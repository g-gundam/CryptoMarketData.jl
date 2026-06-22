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
end

export AsterdexFutures
export AsterdexFuturesCandle
