struct Bitmex <: AbstractExchange
    base_url::String
    using NanoDates: NanoDate0
    http_options::Dict

    function Bitmex()
        new("https://www.bitmex.com/api/v1", Dict())
    end

    function Bitmex(http_options::Dict)
        new("https://www.bitmex.com/api/v1", http_options)
    end
    # TODO - support testnet
end

struct BitmexCandle <: AbstractCandle
    ts::String
    symbol::String
    open::Union{Float64,Missing}
    high::Union{Float64,Missing}
    low::Union{Float64,Missing}
    close::Union{Float64,Missing}
    trades::Integer
    v::Union{Float64,Missing}
    vwap::Union{Float64,Missing}
    lastSize::Union{Integer,Missing}
    turnover::Integer
    homeNotional::Float64
    foreignNotional::Float64
end

function Base.getproperty(c::BitmexCandle, s::Symbol)
    if s == :o
        return getfield(c, :open)
    elseif s == :h
        return getfield(c, :high)
    elseif s == :l
        return getfield(c, :low)
    elseif s == :c
        return getfield(c, :close)
    else
        return getfield(c, s)
    end
end

# https://www.bitmex.com/api/explorer/#!/Trade/Trade_getBucketed
# Timestamps returned by our bucketed endpoints are the end of the period,
# indicating when the bucket was written to disk. Some other common systems use
# the timestamp as the beginning of the period. Please be aware of this when
# using this endpoint.
#
# This leads to subtraction and addition of 1 minute at key points.

function ts2datetime_fn(bitmex::Bitmex)
    return function (dt)
        NanoDate(dt) - Minute(1)
    end
end

function candle_datetime(c::BitmexCandle)
    NanoDate(c.ts) - Minute(1)
end

# TODO - support testnet
function short_name(bitmex::Bitmex)
    "bitmex"
end

function candles_max(bitmex::Bitmex; tf=Minute(1))
    1000
end

function get_markets(bitmex::Bitmex)
    url = bitmex.base_url * "/instrument/active"
    uri = URI(url)
    res = HTTP.get(uri; bitmex.http_options...)
    json = JSON3.read(res.body)
    return map(m -> m[:symbol], json)
end

function get_candles(bitmex::Bitmex, market; start, stop, tf=Minute(1), limit::Integer=10)
    symbol = market
    interval = if tf == Day(1)
        "1d"
    elseif tf == Minute(1)
        "1m"
    else
        "1m"
    end
    adjustment = if tf == Minute(1)
        Minute(1)
    else
        Minute(0)
    end
    q = OrderedDict(
        "symbol"    => symbol,
        "binSize"   => interval,
        "startTime" => format(NanoDate(start) + adjustment),
        "endTime"   => format(NanoDate(stop) + adjustment),
        "count"     => limit
    )
    ohlc_url = bitmex.base_url * "/trade/bucketed"
    uri = URI(ohlc_url; query=q)
    headers = ["Content-Type" => "application/json"]
    res = HTTP.get(uri, headers; bitmex.http_options...)
    json = JSON3.read(res.body)

    candles = map(json) do c
        open = if hasproperty(c, :open)
            c[:open]
        else
            missing
        end
        high = if hasproperty(c, :high)
            c[:high]
        else
            missing
        end
        low = if hasproperty(c, :low)
            c[:low]
        else
            missing
        end
        close = if hasproperty(c, :close)
            c[:close]
        else
            missing
        end
        vwap = if hasproperty(c, :vwap)
            c[:vwap]
        else
            missing
        end
        lastSize = if hasproperty(c, :lastSize)
            c[:lastSize]
        else
            missing
        end
        BitmexCandle(
            c[:timestamp],
            c[:symbol],
            open,
            high,
            low,
            close,
            c[:trades],
            c[:volume],
            vwap,
            lastSize,
            c[:turnover],
            c[:homeNotional],
            c[:foreignNotional]
        )
    end

    return candles
end

export Bitmex
export BitmexCandle
