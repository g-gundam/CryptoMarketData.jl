const BYBIT_API         = "https://api.bybit.com"
const BYBIT_TESTNET_API = "https://api-testnet.bybit.com"

struct Bybit <: AbstractExchange
    base_url::String
    using NanoDates: NanoDate0
    http_options::Dict

    function Bybit()
        new(BYBIT_API, Dict())
    end

    function Bybit(http_options::Dict)
        new(BYBIT_API, http_options)
    end
end

struct BybitCandle <: AbstractCandle
    ts::UInt64
    o::Union{Float64,Missing}
    h::Union{Float64,Missing}
    l::Union{Float64,Missing}
    c::Union{Float64,Missing}
    v::Union{Float64,Missing}
    v2::Union{Float64,Missing}
end

function ts2datetime_fn(bybit::Bybit)
    unixmillis2nanodate
end

function candle_datetime(c::BybitCandle)
    unixmillis2nanodate(c.ts)
end

function short_name(bybit::Bybit)
    if bybit.base_url == BYBIT_API
        "bybit"
    elseif bybit.base_url == BYBIT_TESTNET_API
        "bybit-testnet"
    else
        "bybit-unknown"
    end
end

function candles_max(bybit::Bybit; tf=Minute(1))
    1000
end

# valid categories: linear, inverse, option, spot
function get_markets(bybit::Bybit; category="inverse")
    url = bybit.base_url * "/v5/market/instruments-info"
    q = OrderedDict("category" => category)
    uri = URI(url; query=q)
    res = HTTP.get(uri; bybit.http_options...)
    json = JSON3.read(res.body)
    return map(m -> m[:symbol], json[:result][:list])
end

function get_candles(bybit::Bybit, market; start, stop, tf=Minute(1), limit::Integer=10, category="inverse")
    interval = if tf == Day(1)
        "D"
    elseif tf == Minute(1)
        "1"
    else
        "1"
    end
    q = OrderedDict(
        "category" => category,
        "symbol"   => market,
        "interval" => interval,
        "start"    => nanodate2unixmillis(NanoDate(start)),
        "end"      => nanodate2unixmillis(NanoDate(stop)),
        "limit"    => limit
    )
    ohlc_url = bybit.base_url * "/v5/market/kline"
    uri = URI(ohlc_url; query=q)
    headers = ["Content-Type" => "application/json"]
    res = HTTP.get(uri, headers; bybit.http_options...)
    json = JSON3.read(res.body)
    return map(reverse(json[:result][:list])) do c
        BybitCandle(
            pui64(c[1]),
            pf64(c[2]),
            pf64(c[3]),
            pf64(c[4]),
            pf64(c[5]),
            pf64(c[6]),
            pf64(c[7])
        )
    end
end

export Bybit
export BybitCandle
