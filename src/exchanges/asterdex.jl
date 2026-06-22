ASTERDEX_FUTURES_V3_API = "https://fapi.asterdex.com"
ASTERDEX_FUTURES_V3_WS_API = "wss://fstream.asterdex.com"

@kwdef struct AsterdexFutures <: AbstractExchange
    base_url::AbstractString
    ws_url::AbstractString
    http_options::AbstractDict
end
