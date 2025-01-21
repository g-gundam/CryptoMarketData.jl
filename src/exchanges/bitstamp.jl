module Exchanges
module Bitstamp

# Pull these in from CryptoMarketData
import ...AbstractExchange
import ...AbstractCandle

# XXX: When the functions were inside CryptoMarketData.Exchanges.Bitstamp, I needed this.
#      When I moved them back out, I didn't need these using statements anymore.
# using DataStructures
# using HTTP
# using JSON3
# using URIs

struct Exchange <: AbstractExchange # CryptoMarketData.Exchange.Bitstamp.Exchange (was Bitstamp)
    base_url::String

    function Exchange()
        new("https://www.bitstamp.net")
    end
end

struct Candle <: AbstractCandle # CryptoMarketData.Exchange.Bitstamp.Candle (was BitstampCandle)
    timestamp::UInt64
    open::Union{Float64,Missing}
    high::Union{Float64,Missing}
    low::Union{Float64,Missing}
    close::Union{Float64,Missing}
    volume::Union{Float64,Missing}
end

function Base.getproperty(c::Candle, s::Symbol)
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

#export Exchange
#export Candle

end
end

# XXX: Doing this for now to make things work like they used to.
import .Exchanges.Bitstamp.Exchange as Bitstamp
import .Exchanges.Bitstamp.Candle   as BitstampCandle
export Bitstamp
export BitstampCandle

# XXX: These functions were initially inside CryptoMarketData.Exchanges.Bitstamp
#      but they needed to be in CryptoMarketData for the other generic code that
#      uses them to work.

function csv_headers(bitstamp::Bitstamp) # XXX: Needs to be CryptoMarketData.csv_headers
    [:ts, :o, :h, :l, :c, :v]
end

function csv_select(bitstamp::Bitstamp) # XXX: same
    1:6
end

function ts2datetime_fn(bitstamp::Bitstamp) # XXX: same
    DateTime ∘ unixseconds2nanodate
end

function candle_datetime(c::BitstampCandle) # XXX: same
    unixseconds2nanodate(c.ts)
end

function short_name(bitstamp::Bitstamp) # XXX: same
    "bitstamp"
end

function candles_max(bitstamp::Bitstamp; tf=Minute(1)) # XXX: same
    1000
end

function get_markets(bitstamp::Bitstamp) # XXX: same
    market_url = bitstamp.base_url * "/api/v2/ticker/"
    res = HTTP.get(market_url)
    json = JSON3.read(res.body)
    return map(r -> r.pair, json)
end

function get_candles(bitstamp::Bitstamp, market; start, stop, tf=Minute(1), limit::Integer=10) # XXX: same
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
