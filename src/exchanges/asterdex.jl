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
    tbvv::Flaot64               # Taker buy base asset volume
    tbqv::Float64               # Taker buy quote asset volume
    ignore::Float64             # Ignore
end
