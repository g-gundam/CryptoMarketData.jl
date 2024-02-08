struct Bitget <: AbstractExchange
    base_url::String
    home_url::String
    http_options::Dict

    function Bitget()
        new("https://api.bitget.com", "https://www.bitget.com", Dict())
    end

    function Bitget(http_options::Dict)
        new("https://api.bitget.com", "https://www.bitget.com", http_options)
    end
end

struct BitgetCandle <: AbstractCandle
    ts::UInt64
    o::Float64
    h::Float64
    l::Float64
    c::Float64
    v::Float64
    v2::Float64
end

function ts2datetime_fn(bitget::Bitget)
    DateTime ∘ unixmillis2nanodate
end

function candle_datetime(c::BitgetCandle)
    unixmillis2nanodate(c.ts)
end

function short_name(bitget::Bitget)
    "bitget"
end

function candles_max(bitget::Bitget)
    1000
end

function get_markets(bitget::Bitget; type="dmcbl")
    # type can be
    # umcbl (usdt settled contracts)
    # dmcbl (coin settled contracts)
    # sumcbl (testnet usdt settled contracts)
    # sdmcbl (testnet coin settled contracts)
    info_url = bitget.base_url * "/api/mix/v1/market/contracts"
    q = OrderedDict(
        "productType" => type
    )
    uri = URI(info_url; query=q)
    res = HTTP.get(uri)
    json = JSON3.read(res.body)
    return map(m -> m[:symbol], json[:data])
end

function get_candles(bitget::Bitget, market; start, stop, tf="1m", limit::Integer=10, tz_offset=(8 * 60 * 60 * 1000))
    symbol = market
    interval = if tf == "1d"
        "1D"
    elseif tf == "1m"
        "1m"
    else
        "1m"
    end

    # Add 1 minute to end time, because their API doesn't include the last minute otherwise.
    # Not sure if the 1D interval also needs an adjustment.
    adjustment = if interval == "1m"
        Minute(1)
    else
        Minute(0)
    end

    q = OrderedDict(
        "symbolId"     => symbol,
        "kLineStep"    => interval,
        "kLineType"    => 1,
        "languageType" => 0,
        "startTime"    => nanodate2unixmillis(NanoDate(start)),
        "endTime"      => nanodate2unixmillis(NanoDate(stop) + adjustment),
        "limit"        => limit
    )
    # @info "get_candles" start q["startTime"] stop q["endTime"] limit
    ohlc_url = bitget.home_url * "/v1/kline/getMoreKlineData"
    uri = URI(ohlc_url)
    headers = ["Content-Type" => "application/json"]
    body = JSON3.write(q)
    res = HTTP.post(uri, headers, body; bitget.http_options...)
    json = JSON3.read(res.body)

    # I don't know how, but bitget seems to be able to infer my local timezone
    # even though I'm behind a proxy.  What is going on?
    effective_offset = if interval == "1D"
        tz_offset
    else
        0
    end

    candles = map(json.data) do c
        BitgetCandle(
            pui64(c[1]) + effective_offset,
            pf64(c[2]),
            pf64(c[3]),
            pf64(c[4]),
            pf64(c[5]),
            pf64(c[6]),
            pf64(c[7])
        )
    end

    real_start = findfirst(candles) do c
        c.ts == q["startTime"]
    end

    if real_start > 0
        return candles[real_start:end]
    else
        return candles
    end
end

export Bitget
export BitgetCandle
