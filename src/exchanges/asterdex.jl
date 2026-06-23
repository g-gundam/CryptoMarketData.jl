ASTERDEX_FUTURES_V3_API = "https://fapi.asterdex.com"
ASTERDEX_FUTURES_V3_WS_API = "wss://fstream.asterdex.com"

@kwdef struct AsterdexFutures <: AbstractExchange
    base_url::AbstractString = ASTERDEX_FUTURES_V3_API
    ws_url::AbstractString = ASTERDEX_FUTURES_V3_WS_API
    http_options::AbstractDict = Dict{Symbol, AbstractString}()
end

# https://asterdex.github.io/aster-api-website/futures-v3/market-data/#klinecandlestick-data
@kwdef struct AsterdexFuturesCandle <: AbstractCandle
    ts::UInt64                  # Open time
    o::Float64                  # Open
    h::Float64                  # High
    l::Float64                  # Low
    c::Float64                  # Close
    v::Float64                  # Volume
    cts::UInt64                 # Close time
    qv::Float64                 # Quote asset volume
    trades::Int64               # Number of trades
    tbvv::Float64               # Taker buy base asset volume
    tbqv::Float64               # Taker buy quote asset volume
    ignore::Float64             # Ignore
end

function candle_type(asterdex::AsterdexFutures)
    AsterdexFuturesCandle
end

function csv_headers(asterdex::AsterdexFutures)
    collect(fieldnames(AsterdexFuturesCandle))
end

function csv_select(asterdex::AsterdexFutures)
    1:6
end

function ts2datetime_fn(asterdex::AsterdexFutures)
    DateTime ∘ unixmillis2nanodate
end

function candle_datetime(c::AsterdexFuturesCandle)
    unixmillis2nanodate(c.ts)
end

function short_name(asterdex::AsterdexFutures)
    "asterdex-futures"
end

function candles_max(asterdex::AsterdexFutures; tf=Minute(1))
    1500
end

function get_markets(asterdex::AsterdexFutures)
    url = asterdex.base_url * "/fapi/v3/exchangeInfo"
    uri = URI(url)
    res = HTTP.get(uri; asterdex.http_options...)
    json = JSON3.read(res.body)
    return map(m -> m[:pair], json[:symbols])
end

function get_candles(asterdex::AsterdexFutures, market; start, stop, tf=Minute(1), limit::Integer=10)
    interval = if tf == Day(1)
        "1d"
    elseif tf == Minute(1)
        "1m"
    else
        "1m"
    end
    q = OrderedDict(
        "symbol"    => market,
        "interval"  => interval,
        "startTime" => nanodate2unixmillis(NanoDate(start)),
        "stopTime"  => nanodate2unixmillis(NanoDate(stop)),
        "limit"     => limit
    )
    kline_url = asterdex.base_url * "/fapi/v3/klines"
    uri = URI(kline_url; query=q)
    headers = ["Content-Type" => "application/json"]
    res = HTTP.get(uri, headers; asterdex.http_options...)
    json = JSON3.read(res.body)
    return map(reverse(json)) do c
        AsterdexFuturesCandle(
            convert(UInt64, c[1]),
            pf64(c[2]),
            pf64(c[3]),
            pf64(c[4]),
            pf64(c[5]),
            pf64(c[6]),
            convert(UInt64, c[7]),
            pf64(c[8]),
            c[9],
            pf64(c[10]),
            pf64(c[11]),
            pf64(c[12])
        )
    end
end

# Asterdex requires a different technique.
# This should be faster.
function earliest_candle(asterdex::AsterdexFutures, market; endday=today(tz"UTC"))
    url = asterdex.base_url * "/fapi/v3/exchangeInfo"
    uri = URI(url)
    res = HTTP.get(uri; asterdex.http_options...)
    json = JSON3.read(res.body)
    m_i = findfirst(s -> s[:symbol] == market, json[:symbols])
    if isnothing(m_i)
        return nothing
    end
    market_info = json[:symbols][m_i]
    onboard_date = unixmillis2nanodate(market_info[:onboardDate])
    starting_month = floor(onboard_date, Month)
    stop = starting_month + Day(60)
    cs = get_candles(asterdex, market; start=starting_month, stop, limit=1)
    if length(cs) > 0
        cs[1]
    else
        nothing
    end
end

export AsterdexFutures
export AsterdexFuturesCandle
