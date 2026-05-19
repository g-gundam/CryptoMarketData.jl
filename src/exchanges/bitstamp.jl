BITSTAMP_API = "https://www.bitstamp.net"
BITSTAMP_WS_API = "wss://ws.bitstamp.net"

@kwdef struct Bitstamp <: AbstractExchange
    base_url::AbstractString = BITSTAMP_API
    ws_url::AbstractString = BITSTAMP_WS_API
end

@kwdef struct BitstampCandle <: AbstractCandle
    timestamp::UInt64 # unix seconds
    open::Union{Float64,Missing}
    high::Union{Float64,Missing}
    low::Union{Float64,Missing}
    close::Union{Float64,Missing}
    volume::Union{Float64,Missing}
end

function Base.getproperty(c::BitstampCandle, s::Symbol)
    if s == :ts
        return getfield(c, :timestamp)
    elseif s == :o
        return getfield(c, :open)
    elseif s == :h
        return getfield(c, :high)
    elseif s == :l
        return getfield(c, :low)
    elseif s == :c
        return getfield(c, :close)
    elseif s == :v
        return getfield(c, :volume)
    else
        return getfield(c, s)
    end
end

function Base.convert(::Type{BitstampCandle}, row::DataFrameRow)
    BitstampCandle(nanodate2unixseconds(NanoDate(row.ts)), row.o, row.h, row.l, row.c, row.v)
end

function candle_type(bitstamp::Bitstamp)
    BitstampCandle
end

function csv_headers(bitstamp::Bitstamp)
    [:ts, :o, :h, :l, :c, :v]
end

function csv_select(bitstamp::Bitstamp)
    1:6
end

function ts2datetime_fn(bitstamp::Bitstamp)
    DateTime ∘ unixseconds2nanodate
end

function candle_datetime(c::BitstampCandle)
    unixseconds2nanodate(c.ts)
end

function short_name(bitstamp::Bitstamp)
    "bitstamp"
end

function candles_max(bitstamp::Bitstamp; tf=Minute(1))
    1000
end

function get_markets(bitstamp::Bitstamp)
    market_url = bitstamp.base_url * "/api/v2/ticker/"
    res = HTTP.get(market_url)
    json = JSON3.read(res.body)
    return map(r -> r.pair, json)
end

function get_candles(bitstamp::Bitstamp, market; start, stop, tf=Minute(1), limit::Integer=10)
    mark2 = replace(market, r"\W" => s"") |> lowercase
    # I only support two timeframes.  1d and 1m
    step = if tf == Day(1)
        60 * 60 * 24
    elseif tf == Minute(1)
        60
    else
        60
    end
    q2 = OrderedDict(
        "step"  => step,
        "start" => nanodate2unixseconds(NanoDate(start)),
        "end"   => nanodate2unixseconds(NanoDate(stop)),
        "limit" => limit
    )
    ohlc_url = bitstamp.base_url * "/api/v2/ohlc/" * mark2 * "/"
    uri = URI(ohlc_url, query=q2)
    res = HTTP.get(uri)
    json = JSON3.read(res.body)
    # TODO - return a standardized candle, not JSON
    map(json[:data][:ohlc]) do c
        BitstampCandle(
            pui64(c[:timestamp]),
            pf64(c[:open]),
            pf64(c[:high]),
            pf64(c[:low]),
            pf64(c[:close]),
            pf64(c[:volume])
        )
    end
end

# TODO: I may want to document this once to cover all specializations.
"""$(TYPEDSIGNATURES)

Return the websocket URI for the given exchange.
"""
function ws_uri(bitstamp::Bitstamp)
    URI(bitstamp.ws_url)
end

"""$(TYPEDSIGNATURES)

Return a vector of JSON commands to send to an exchange's WebSocket API
to subscribe to market data.
"""
function ws_subscribe_commands(bitstamp::Bitstamp, market::AbstractString)
    clean_market = @chain market begin
        lowercase
        replace(_, "/" => "")
    end
    map(
        JSON3.write,
        [Dict(:event => "bts:subscribe", :data => Dict(:channel => "live_trades_$(clean_market)"))]
    )
end

"""$(TYPEDSIGNATURES)

While inside `accumulator_process`, handle a websocket message from the exchange.
The main job of this function is to send candles to commander_process.
Secondary jobs may include acknowleding successful subscriptions
or handling reconnect requests.
"""
function ws_handle_message(bitstamp::Bitstamp, s::Session, msg::AbstractString)
    data = JSON3.read(msg)
    commander = Visor.from_name(s.supervisor, "command_process")
    if haskey(data, "event")
        if data["event"] == "trade"
            new_candle = merge(s.last_candle, data)
            cast(commander, new_candle)
            s.last_candle = new_candle # I forgot to do this in main.jl (aka take2).
        elseif data["event"] == "bts:subscription_succeeded"
            @info :ax note="subscription succeeded"
        elseif data["event"] == "bts:request_reconnect"
            @info :ax note="bts:request_reconnect"
            close(s.ws)
            # Visor.jl should restart things.
        else
            @warn :ax note="unknown message type" data["event"]
        end
    else
        @warn :ax note="data has no 'event' key." data
    end
end

## This is used by CryptoMarketData.update! and every exchange should implement this for their candle type.

function Base.merge(a::BitstampCandle, b::BitstampCandle)
    @assert a.timestamp == b.timestamp # hopefully, whoever is calling update can guarantee this, so I can get rid of this.
    high = max(a.high, b.high)
    low  = min(a.low, b.low)
    return BitstampCandle(a.timestamp, a.open, high, low, b.close, b.volume)
end

## The following Base.merge methods are used by code that consumes data from websokets.

# a is the last candle
# b is the new data
# return an updated candle if a and be are in the same tf
# or return a new candle if a and b are in different tfs
function Base.merge(a::BitstampCandle, b::AbstractDict; tf=Minute(1))
    price  = b["data"]["price"]
    amount = b["data"]["amount"]
    b_ts   = parse(UInt64, b["data"]["timestamp"])
    b_dt   = DateTime(unixseconds2nanodate(b_ts))
    b_ts2  = floor(b_dt, tf)
    a_ts2  = DateTime(candle_datetime(a))
    if a_ts2 == b_ts2
        # update candle
        return BitstampCandle(
            timestamp=a.timestamp,
            open=a.open,
            high=max(a.high, price),
            low=min(a.low, price),
            close=price,
            volume=a.volume + amount
        )
    else
        # new candle
        b_nd2 = NanoDate(b_ts2)
        ts    = nanodate2unixseconds(b_nd2)
        return BitstampCandle(
            timestamp=ts,
            open=price,
            high=price,
            low=price,
            close=price,
            volume=amount
        )
    end
end

# When there is no initial candle, pass the desired type so we can dispatch to this function
# to create the initial candle.
function Base.merge(a::Type{BitstampCandle}, b::AbstractDict; tf=Minute(1))
    price  = b["data"]["price"]
    amount = b["data"]["amount"]
    b_ts   = parse(UInt64, b["data"]["timestamp"])
    b_dt   = DateTime(unixseconds2nanodate(b_ts))
    b_ts2  = floor(b_dt, tf)
    b_nd2  = NanoDate(b_ts2)
    ts     = nanodate2unixseconds(b_nd2)
    return BitstampCandle(
        timestamp=ts,
        open=price,
        high=price,
        low=price,
        close=price,
        volume=amount
    )
end

export Bitstamp
export BitstampCandle
