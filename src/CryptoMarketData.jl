module CryptoMarketData

using URIs
using HTTP
using JSON3

using TimeZones
using Dates
using NanoDates
using DataStructures
using DocStringExtensions

using CSV
using DataFrames
using Chain
using Visor
using Observables

# Every exchange implements its own subtype of these.
abstract type AbstractExchange end
abstract type AbstractCandle end

# I want to introduce the concept of storage
# instead of hardcoding file-based CSV data for storage.
# It will be a slow introduction though.
# I don't feel ready to do a major refactor yet.
abstract type AbstractStorage end

# This is used to contain WebSocket sessions and interact with them.
@kwdef mutable struct Session
    exchange::AbstractExchange
    market::AbstractString
    candles::Vector{<: AbstractCandle}
    new_candle::Observable
    last_candle::Any # Union{Missing, DataType, AbstractCandle}
    ws::Union{Missing, HTTP.WebSockets.WebSocket}
    supervisor::Union{Missing, Visor.Supervisor}
    supervisor_ws::Union{Missing, Visor.Supervisor}
end

# Include NHDaly/Select locally.
# It may be old and unmaintained, but I like the way it works.
# When a better way to wait on multiple channels appears, I'll switch.
include("Select.jl")

# unexported utility functions
include("helpers.jl")

# exported exchange-specific structures and methods
include("exchanges/binance.jl")            # DONE
include("exchanges/bitget.jl")             # DONE
include("exchanges/bitmex.jl")             # DONE
include("exchanges/bitstamp.jl")           # DONE
include("exchanges/bybit.jl")              # DONE
include("exchanges/pancakeswap.jl")        # DONE

# storage strutures and methods
include("storage/csv.jl")

# websocket support
include("websockets.jl")

## Exports

# general functions
export get_saved_markets

# general functions that operate on exchanges
# 1 implementation
export save!
export load
export load_remote
export earliest_candle
export get_candles_for_day
export save_day!

# general function that operates on exchange-specific candle types
# 1 implementation
export update!

# functions with exchange-specific methods
# many exchange-specific implementations
export candle_type
export csv_headers
export csv_select
export ts2datetime_fn
export candle_datetime
export short_name
export candles_max
export get_markets
export get_candles
export ws_uri
export subscribe # XXX: This is getting replaced with something based on Visor.
                 # I may change the name, too.

# `Base.merge(a::C, b::C) where {C <: AbstractCandle}` should be implemented too.
#    (It's already exported by Julia, so there's no need to export here.)

"""$(TYPEDSIGNATURES)

Take any AbstractCandle `c` and return a NamedTuple that can be pushed into a DataFrame.
"""
function Base.convert(::Type{NamedTuple}, c::AbstractCandle)
    (;
     :ts => candle_datetime(c),
     :o  => c.o,
     :h  => c.h,
     :l  => c.l,
     :c  => c.c,
     :v  => c.v)
end

"""
$(TYPEDSIGNATURES)

Return a DataFrame that lists the currently saved markets.

# Keyword Arguments

* datadir="./data" - directory where saved data is stored

# Example

```julia-repl
julia> saved = get_saved_markets()
10×4 DataFrame
 Row │ exchange       market          start       stop
     │ Any            Any             Any         Any
─────┼───────────────────────────────────────────────────────
   1 │ binance        BTCUSD_240628   2023-12-29  2024-02-17
   2 │ binance        BTCUSD_PERP     2020-08-11  2020-08-16
   3 │ bitget         BTCUSD_DMCBL    2019-04-23  2024-02-16
   4 │ bitget         DOGEUSD_DMCBL   2024-02-01  2024-02-20
   5 │ bitmex         ETHUSD          2018-08-02  2024-02-19
   6 │ bitstamp       BTCUSD          2011-08-18  2024-02-25
   7 │ bybit          ADAUSD          2022-03-24  2022-04-21
   8 │ bybit-inverse  ADAUSD          2022-03-24  2022-04-20
   9 │ bybit-linear   10000LADYSUSDT  2023-05-11  2024-03-04
  10 │ pancakeswap    BTCUSD          2023-03-15  2024-03-04
```
"""
function get_saved_markets(; datadir="./data")
    @debug "datadir" datadir
    df = DataFrame(exchange=[], market=[], start=[], stop=[])
    exchanges = readdir(datadir)
    for ex in exchanges
        markets = readdir("$(datadir)/$(ex)")
        for mk in markets
            csv_a = first_csv("$(datadir)/$(ex)/$(mk)")
            csv_b = last_csv("$(datadir)/$(ex)/$(mk)")
            start = if ismissing(csv_a)
                missing
            else
                _filename_to_date(csv_a)
            end
            stop = if ismissing(csv_b)
                missing
            else
                _filename_to_date(csv_b)
            end
            df = vcat(df, DataFrame(exchange=[ex], market=[mk], start=[start], stop=[stop]))
        end
    end
    return df
end

"""
$(SIGNATURES)

Download 1m candles from the given exchange and market, and save them locally.

# Keyword Arguments

* datadir="./data" - directory where saved data is stored
* startday - a `Date` to start fetching candles from
* endday - a `Date` to stop fetching candles
* delay - a delay to be passed to `sleep()` that will pause between internal calls to `save_day!()`

# Example

```julia-repl
julia> bitstamp = Bitstamp()
julia> save!(bitstamp, "BTC/USD", endday=Date("2020-08-16"))
```

To monitor its progress on long downloads, set the `JULIA_DEBUG` environment variable.
This will cause debug log messages to be emitted before each day of candles is downloaded.

```julia-repl
julia> ENV["JULIA_DEBUG"] = "CryptoMarketData"
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
        @debug current_day length(cs)
        save_day!(exchange, market, cs; datadir)
        current_day = current_day + Dates.Day(1)
        sleep(delay)
    end
end

"""
    save_day!(exchange, market, candles; datadir="./data")

Save a day worth of 1m candles the caller provides for the
given exchange and market.

# Keyword Arguments

* datadir="./data" - directory where saved data is stored
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
    candles2 = get_candles(exchange, market; tf=Minute(1), start=half_way, stop=end_of_day - Minute(1), limit=720)
    # start at later half of the day
    # if less than 720 returned, we've found the earliest candle
    if length(candles2) < 720
        @debug "< 720" length(candles2)
        return candles2[1]
    else
        # if not, go to earlier half of the day
        # grab 720 more candles
        @debug ">= 720" first_day half_way
        candles3 = get_candles(exchange, market; tf=Minute(1), start=first_day, stop=half_way - Minute(1), limit=720)
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

"""$(TYPEDSIGNATURES)

Fetch all of the 1m candles for the given exchange, market, and day.
The vector and candles returned is just the right size to save to the archives.
"""
function get_candles_for_day(exchange::AbstractExchange, market, day::Date)
    limit = candles_max(exchange)    # tf exists to get around a special case for binance
    n_reqs = convert(Int64, ceil(1440 / limit)) # number of requests
    l_preq = convert(Int64, 1440 / n_reqs)      # limit per request
    Type = candle_type(exchange)
    candles = Vector{Type}()
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
$(TYPEDSIGNATURES)

Load candles for the given exchange and market from the file system.

# Keyword Arguments

* datadir="./data" - directory where saved data is stored
* span - a `Date` span that defines what Dates to load candles.  If it's `missing`, load everything
* tf - a `Period` that is used to aggregate 1m candles into higher timeframes
* table - a Tables.jl-compatible struct to load candles into.  The default is `DataFrame`
* remote - if true, fill in gaps in local storage by fetching from remote sources

# Example

```julia-repl
julia> bitstamp = Bitstamp()
julia> btcusd4h = load(bitstamp, "BTC/USD"; span=Date("2024-01-01"):Date("2024-02-10"), tf=Hour(4))
```
"""
function load(exchange::AbstractExchange, market; datadir="./data", span=missing, tf::Union{Period,Missing}=missing, table=DataFrame, remote::Bool=false)
    indir = joinpath(datadir, short_name(exchange), replace(market, "/" => ""))
    cfs = readdir(indir; join=true)
    out_of_range = false        # XXX: This is a flag used by the `if remote` block
    if !ismissing(span)
        if typeof(span) <: UnitRange
            cfs = cfs[span]
        elseif typeof(span) <: StepRange
            # convert span to UnitRange
            a = _d2i(first(span), cfs)
            b = _d2i(last(span), cfs)
            # @info "might be out of range" a b span (b > span.stop)
            if ismissing(b)
                b = lastindex(cfs)
                out_of_range = true
                # @info "replacement for missing b" b size(cfs)
            end
            if !ismissing(a)
                cfs = cfs[range(a, b)]
            else
                cfs = missing
            end
        end
    end
    res = missing
    headers = csv_headers(exchange)
    select = csv_select(exchange)
    #csv_read = (cf) -> CSV.read(cf, table; headers=headers, select=select, skipto=2)
    if !ismissing(cfs)
        for cf in cfs
            csv = CSV.read(cf, table; header=headers, select=select, skipto=2)
            csv[!, :ts] = map(ts2datetime_fn(exchange), csv[!, :ts])
            if ismissing(res)
                res = csv
            else
                append!(res, csv)
            end
        end
    end

    # fill in gaps in local storage with remotely fetched data
    if remote && out_of_range
        if ismissing(res)
            # full remote
            res = DataFrame()
            rcs = load_remote(exchange, market; span)
            for j in 1:length(rcs)
                push!(res, convert(NamedTuple, rcs[j]))
            end
        else
            # partial load_remote
            # - get the last day from local storage
            # - fetch until span.stop
            last_ts = res[end, :ts]
            last_day = Date(floor(last_ts, Day))
            remote_span = last_day:span.stop
            rcs = load_remote(exchange, market; span=remote_span)
            # - skip candles already in the dataframe
            i = 1
            while candle_datetime(rcs[i]) <= last_ts && i < length(rcs)
                i += 1
            end
            # - push the remaining candles on to the dataframe
            for j in i:length(rcs)
                push!(res, convert(NamedTuple, rcs[j]))
            end
        end
    end

    # Do optional timeframe summarization
    if ismissing(tf)
        return res
    else
        return @chain res begin
            transform(:ts => (ts -> floor.(ts, tf)) => :ts2)
            groupby(:ts2) # LSP doesn't know the @chain macro is doing magic.
            combine(
                :o => (o -> first(o))   => :o,
                :h => (h -> maximum(h)) => :h,
                :l => (l -> minimum(l)) => :l,
                :c => (c -> last(c))    => :c,
                :v => (v -> sum(v))     => :v
            )
            # XXX: I was forced to be explicit, but I don't know
            # what select method I was conflicting with.
            DataFrames.select(:ts2=>:ts, :o, :h, :l, :c, :v) 
        end
    end
end

"""$(TYPEDSIGNATURES)

Load candles using the exchange's API.
"""
function load_remote(exchange::AbstractExchange, market; span::StepRange{Date,Day}=today():today(), tf::Union{Period,Missing}=missing, delay=0.5, table=DataFrame)
    @chain span begin
        map(day -> get_candles_for_day(exchange, market, day), _)
        vcat(_...)
    end
end

"""$(TYPEDSIGNATURES)

Destructively update a vector of `candles` with new `candle` data.
One of 3 things can happen as a result of calling this function.

1. Return `:first` if `candles` was previously empty.
2. Return `:updated` if the timestamps are the same and update the last candle.
3. Return `:new` if the timestamps are different and push the new candle.
"""
function update!(candles::AbstractVector{<: AbstractCandle}, candle::AbstractCandle)
    last = if length(candles) > 0
        candles[end]
    else
        nothing
    end
    if isnothing(last)
        push!(candles, candle)
        return :first
    else
        last_dt   = candle_datetime(last)
        candle_dt = candle_datetime(candle)
        if last_dt == candle_dt
            updated_candle = merge(last, candle)
            candles[end] = updated_candle
            return :updated
        else
            push!(candles, candle)
            return :new
        end
    end
end

## Generalized Documentation
#    for methods with exchange-specific implementations:

"""
    csv_headers(exchange::AbstractExchange) -> Vector{Symbol}

Return headings for each column of candle data.

# Example

```julia-repl
julia> bitstamp = Bitstamp()
julia> columns = csv_headers(bitstamp)
6-element Vector{Symbol}:
 :ts
 :o
 :h
 :l
 :c
 :v
```
"""
csv_headers(exchange)

"""
    get_markets(exchange) -> Vector{String}

Fetch the available markets for the given exchange.

# Example

```julia-repl
julia> bitstamp = Bitstamp()
julia> markets = get_markets(bitstamp)
```
"""
CryptoMarketData.get_markets(exchange)

"""    Base.merge(a::C, b::C) where {C <: CryptoMarketData.AbstractCandle} -> C

Every concrete candle type should implement a Base.merge method that will
take the current candle `a` and a newer candle `b` with the same timestamp, and
perform a merge such that high, low, and volume are updated as necessary.
It should return a new candle with the merged data.

(This will be used by code that consumes unfinished candle data from WebSockets.)
"""
Base.merge(a::AbstractCandle, b::AbstractCandle)

end

#=
## REPL Snippets

using CryptoMarketData
using DataFrames
using DataFramesMeta
using Dates
using NanoDates

1 + 1
b = 9
c = 9
markets = get_saved_markets()
pancakeswap = PancakeSwap()
bitstamp = Bitstamp()
btcusd = load(bitstamp, "BTCUSD"; tf=Minute(1), span=Date("2024-01-01"):Date("2024-01-02"))

s = subscribe(pancakeswap) # s for websocket session

tf = Hour(6)
fix = @chain res begin
    transform(:ts => (ts -> floor.(ts, tf)) => :ts2)
    groupby(:ts2) # LSP doesn't know the @chain macro is doing magic.
    combine(
        :o => (o -> first(o))   => :o,
        :h => (h -> maximum(h)) => :h,
        :l => (l -> minimum(l)) => :l,
        :c => (c -> last(c))    => :c,
        :v => (v -> sum(v))     => :v
    )
    #@select(:ts = :ts2, :o, :h, :l, :c, :v)
    select(:ts2=>:ts, :o, :h, :l, :c, :v)
end

=#
