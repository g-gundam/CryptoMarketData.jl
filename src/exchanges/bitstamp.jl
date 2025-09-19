BITSTAMP_API = "https://www.bitstamp.net"

@kwdef struct Bitstamp <: AbstractExchange
    base_url::String
end

@kwdef struct BitstampCandle <: AbstractCandle
    timestamp::UInt64
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

export Bitstamp
export BitstampCandle
