## Generalized Documentation
#    for methods with exchange-specific implementations:

"""    csv_headers(exchange::AbstractExchange) -> Vector{Symbol}

Return headings for each column of candle data.

# Example

```julia-repl
julia> bitstamp = Bitstamp();
julia> columns = csv_headers(bitstamp)
6-element Vector{Symbol}:
 :ts
 :o
 :h
 :l
 :c
 :v
```
"""
csv_headers(exchange)

"""    get_markets(exchange) -> Vector{String}

Fetch the available markets for the given exchange.

# Example

```julia-repl
julia> bitstamp = Bitstamp();
julia> markets = get_markets(bitstamp)
```
"""
CryptoMarketData.get_markets(exchange)

"""    Base.merge(a::C, b::C) where {C <: CryptoMarketData.AbstractCandle} -> C

Every concrete candle type should implement a Base.merge method that will
take the current candle `a` and a newer candle `b` with the same timestamp, and
perform a merge such that high, low, and volume are updated as necessary.
It should return a new candle with the merged data.

(This will be used by code that consumes unfinished candle data from WebSockets.)
"""
Base.merge(a::AbstractCandle, b::AbstractCandle)
