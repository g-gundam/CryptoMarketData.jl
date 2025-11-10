BINANCE_API = "https://dapi.binance.com"

@kwdef struct Binance <: AbstractExchange
    base_url::AbstractString = BINANCE_API
    http_options::AbstractDict = Dict{Symbol,AbstractString}()
end

@kwdef struct BinanceCandle <: AbstractCandle
    ts::UInt64
    o::Float64
    h::Float64
    l::Float64
    c::Float64
    v::Float64 # I might not care about anything below this comment, but someone else might so I keep it.
    close_ts::UInt64
    v2::Float64
    trades::UInt64
    tbv::Float64
    tbv2::Float64
    ignore::Float64
end

function candle_type(binance::Binance)
    BinanceCandle
end

function csv_headers(binance::Binance)
    collect(fieldnames(BinanceCandle))
end

function csv_select(binance::Binance)
    1:6
end

function ts2datetime_fn(binance::Binance)
    DateTime ∘ unixmillis2nanodate
end

function candle_datetime(c::BinanceCandle)
    unixmillis2nanodate(c.ts)
end

function short_name(binance::Binance)
    "binance"
end

function candles_max(binance::Binance; tf=Minute(1))
    if tf == Day(1)
        200
    elseif tf == Minute(1)
        1500
    else
        1500
    end
end

function get_markets(binance::Binance)
    info_url = binance.base_url * "/dapi/v1/exchangeInfo"
    uri = URI(info_url)
    res = HTTP.get(uri; binance.http_options...)
    json = JSON3.read(res.body)
    return map(m -> m[:symbol], json[:symbols])
end

function get_candles(binance::Binance, market; start, stop, tf=Minute(1), limit::Integer=10)
    symbol = replace(market, r"\W" => s"") |> lowercase
    interval = if tf == Day(1)
        "1d"
    elseif tf == Minute(1)
        "1m"
    else
        "1m"
    end
    q = OrderedDict(
        "interval" => interval,
        "startTime" => nanodate2unixmillis(NanoDate(start)),
        "endTime" => nanodate2unixmillis(NanoDate(stop)),
        "limit" => limit,
        "symbol" => symbol
    )
    ohlc_url = binance.base_url * "/dapi/v1/klines"
    uri = URI(ohlc_url, query=q)
    res = HTTP.get(uri; binance.http_options...)
    json = JSON3.read(res.body)
    map(json) do c
        BinanceCandle(
            c[1] % UInt64, # Casting Int64 to UInt64 :: https://discourse.julialang.org/t/casting-int64-to-uint64/33856/4
            pf64(c[2]),
            pf64(c[3]),
            pf64(c[4]),
            pf64(c[5]),
            pf64(c[6]), # keeping data after this even if I don't use it.
            c[7] % UInt64,
            pf64(c[8]),
            c[9] % UInt64,
            pf64(c[10]),
            pf64(c[11]),
            pf64(c[12])
        )
    end
end

export Binance
export BinanceCandle
