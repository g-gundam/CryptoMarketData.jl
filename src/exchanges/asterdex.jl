@kwdef struct Asterdex <: AbstractExchange
    base_url::AbstractString
    ws_url::AbstractString
    http_options::AbstractDict
end
