BITGET_API = "https://api.bitget.com"
BITGET_HOME = "https://www.bitget.com"

@kwdef struct Bitget <: AbstractExchange
    base_url::AbstractString = BITGET_API
    home_url::AbstractString = BITGET_HOME
    http_options::AbstractDict = Dict{Symbol,AbstractString}()
    type::AbstractString = "dmcbl"
end

@kwdef struct BitgetCandle <: AbstractCandle
    ts::UInt64
    o::Float64
    h::Float64
    l::Float64
    c::Float64
    v::Float64
    v2::Float64
end

function candle_type(bitget::Bitget)
    BitgetCandle
end

function csv_headers(bitget::Bitget)
    collect(fieldnames(BitgetCandle))
end

function csv_select(bitget::Bitget)
    1:6
end

function ts2datetime_fn(bitget::Bitget)
    DateTime ∘ unixmillis2nanodate
end

function candle_datetime(c::BitgetCandle)
    unixmillis2nanodate(c.ts)
end

function short_name(bitget::Bitget)
    # symbol names don't collide so all market types can be saved to the same directory
    "bitget"
end

function candles_max(bitget::Bitget; tf=Minute(1))
    1000
end

function get_markets(bitget::Bitget)
    # type can be
    # umcbl (usdt settled contracts)
    # dmcbl (coin settled contracts)
    # sumcbl (testnet usdt settled contracts)
    # sdmcbl (testnet coin settled contracts)
    info_url = bitget.base_url * "/api/mix/v1/market/contracts"
    q = OrderedDict(
        "productType" => bitget.type
    )
    uri = URI(info_url; query=q)
    res = HTTP.get(uri; bitget.http_options...)
    json = JSON3.read(res.body)
    return map(m -> m[:symbol], json[:data])
end

function get_candles(bitget::Bitget, market; start, stop, tf=Minute(1), limit::Integer=10, tz_offset=get_tz_offset())
    symbol = market
    interval = if tf == Day(1)
        "1D"
    elseif tf == Minute(1)
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
        "symbolId" => symbol,
        "kLineStep" => interval,
        "kLineType" => 1,
        "languageType" => 0,
        "startTime" => nanodate2unixmillis(NanoDate(start)),
        "endTime" => nanodate2unixmillis(NanoDate(stop) + adjustment),
        "limit" => limit
    )
    #@info "get_candles" start q["startTime"] stop q["endTime"] limit
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

    #@info "cdl" real_start length(candles) candle_datetime(candles[1])
    if isnothing(real_start)
        return []
    elseif real_start > 0
        return candles[real_start:end]
    else
        return candles
    end
end

export Bitget
export BitgetCandle
