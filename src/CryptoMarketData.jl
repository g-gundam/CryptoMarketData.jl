module CryptoMarketData

using URIs
using HTTP
using JSON3

using TimeZones
using Dates
using NanoDates
using DataStructures

using CSV
using DataFrames
using DataFramesMeta

abstract type AbstractExchange end
abstract type AbstractCandle end

# unexported utility functions
include("helpers.jl")

# exported exchange-specific structures and methods
include("exchanges/binance.jl")            # DONE
include("exchanges/bitget.jl")             # DONE
include("exchanges/bitmex.jl")             # DONE
include("exchanges/bitstamp.jl")           # DONE
include("exchanges/bybit.jl")              # DONE
include("exchanges/pancakeswap.jl")        # DONE

# general functions that operate on exchanges
export save!
export load
export earliest_candle
export get_candles_for_day
export save_day!

# functions with exchange-specific methods
export csv_headers
export csv_select
export ts2datetime_fn
export candle_datetime
export short_name
export candles_max
export get_markets
export get_candles

"""
    save!(exchange::AbstractExchange, market; datadir="./data", endday=today(tz"UTC"), delay=0.5)

Download 1m candles from the given exchange and market, and save them locally.

# Example

```julia-repl
julia> bitstamp = Bitstamp()
julia> save!(bitstamp, "BTC/USD", endday=Date("2020-08-16"))
```
"""
function save!(exchange::AbstractExchange, market; datadir="./data", startday=missing, endday=today(tz"UTC"), delay=0.5)
    # make directories if they don't already exist
    outdir = joinpath(datadir, short_name(exchange), replace(market, "/" => ""))
    mkpath(outdir)

    # figure out what day we're on
    csv_name = last_csv(outdir)
    current_day = missing
    if !ismissing(startday)
        current_day = Date(startday)
    elseif ismissing(csv_name)
        first_candle = earliest_candle(exchange, market)
        current_day = Date(candle_datetime(first_candle))
    else
        csv_date = Date(replace(csv_name, ".csv" => ""))
        lines = countlines(joinpath(outdir, csv_name))
        if lines > 1440
            current_day = csv_date + Dates.Day(1)
        else
            current_day = csv_date
        end
    end

    while current_day <= endday
        cs = get_candles_for_day(exchange, market, current_day)
        @info current_day length(cs)
        save_day!(exchange, market, cs)
        current_day = current_day + Dates.Day(1)
        sleep(delay)
    end
end

"""
    save_day!(exchange, market, candles; datadir="./data")

Save a day worth of 1m candles the caller provides for the
given exchange and market.
"""
function save_day!(exchange::AbstractExchange, market, candles; datadir="./data")
    current_day = Date(candle_datetime(candles[1]))
    outdir = joinpath(datadir, short_name(exchange), replace(market, "/" => ""))
    outfile = outdir * "/" * Dates.format(current_day, "yyyy-mm-dd") * ".csv"
    CSV.write(outfile, candles |> DataFrame)
end

"""
    earliest_candle(exchange, market)

Return the earliest candle for the given market in the 1m timeframe.
"""
function earliest_candle(exchange::AbstractExchange, market; endday=today(tz"UTC"))
    # starting from the current day
    stop = DateTime(endday)
    max = candles_max(exchange; tf=Day(1))
    start = stop - Dates.Day(max)
    candles = missing
    # grab as many (large timeframe like 1d) candles as is allowed and
    while true
        @debug "ec" start stop
        candles = get_candles(exchange, market; tf=Day(1), start=start, stop=stop, limit=max)
        length(candles) == max || break

        stop = start
        start = stop - Dates.Day(max)
    end
    @debug "after 1d"
    # work backwards until a result with fewer items than the limit is reached.
    # go to the earliest day
    first_day = floor(candle_datetime(candles[1]), Dates.Day)
    half_way = first_day + Dates.Hour(12)
    end_of_day = half_way + Dates.Hour(12)
    # there are 1440 minutes in a day.
    # grab 720 candles
    # XXX :: hopefully candles_max(exchange) > 720
    @debug "1m" first_day (:start => half_way) (:stop => end_of_day)
    candles2 = get_candles(exchange, market; tf=Minute(1), start=half_way, stop=end_of_day-Minute(1), limit=720)
    # start at later half of the day
    # if less than 720 returned, we've found the earliest candle
    if length(candles2) < 720
        @debug "< 720" length(candles2)
        return candles2[1]
    else
        # if not, go to earlier half of the day
        # grab 720 more candles
        @debug ">= 720" first_day half_way
        candles3 = get_candles(exchange, market; tf=Minute(1), start=first_day, stop=half_way-Minute(1), limit=720)
        if length(candles3) == 0
            @debug "length(candles3) == 0"
            return candles2[1]
        else
            @debug "ok" length(candles3) length(candles2)
            return candles3[1]
        end
    end
    # it better be less than 720 returned and earliest candle found
    # if not? there's a bug.
end

"""
    get_candles_for_day(exchange, market, day::Date)

Fetch all of the 1m candles for the given exchange, market, and day.
The vector and candles returned is just the right size to save to the archives.
"""
function get_candles_for_day(exchange::AbstractExchange, market, day::Date)
    limit = candles_max(exchange)    # tf exists to get around a special case for binance
    n_reqs = convert(Int64, ceil(1440 / limit)) # number of requests
    l_preq = convert(Int64, 1440 / n_reqs)      # limit per request
    candles = []
    current_ts = DateTime(day)
    stop_ts = current_ts + Dates.Minute(l_preq - 1)
    for _ in 1:n_reqs
        c = get_candles(exchange, market; start=current_ts, stop=stop_ts, limit=l_preq)
        append!(candles, c)
        current_ts = stop_ts + Dates.Minute(1)
        stop_ts = current_ts + Dates.Minute(l_preq - 1)
    end
    candles
end

"""
    load(exchange, market)

Load candles for the given exchange and market from the file system.
"""
function load(exchange::AbstractExchange, market; datadir="./data", span=missing, tf::Union{Period,Missing}=missing, table=DataFrame)
    indir = joinpath(datadir, short_name(exchange), replace(market, "/" => ""))
    cfs = readdir(indir; join=true)
    if !ismissing(span)
        if typeof(span) <: UnitRange
            cfs = cfs[span]
        elseif typeof(span) <: StepRange
            # convert span to UnitRange
            a = _d2i(first(span), cfs)
            b = _d2i(last(span), cfs)
            cfs = cfs[range(a, b)]
        end
    end
    res = missing
    headers = csv_headers(exchange)
    select = csv_select(exchange)
    #csv_read = (cf) -> CSV.read(cf, table; headers=headers, select=select, skipto=2)
    for cf in cfs
        csv = CSV.read(cf, table; header=headers, select=select, skipto=2)
        csv[!, :ts] = map(ts2datetime_fn(exchange), csv[!, :ts])
        if ismissing(res)
            res = csv
        else
            append!(res, csv)
        end
    end

    # Do optional timeframe summarization
    if ismissing(tf)
        return res
    else
        return @chain res begin
            @transform(:ts2 = floor.(:ts, tf))
            groupby(:ts2) # LSP doesn't know the @chain macro is doing magic.
            @combine begin
                :o = first(:o)
                :h = maximum(:h)
                :l = minimum(:l)
                :c = last(:c)
                :v = sum(:v)
            end
            @select(:ts = :ts2, :o, :h, :l, :c, :v)
        end
    end
end

end
