# Examples

## Construct an Exchange

The defaults are usually fine.

```julia-repl
julia> using CryptoMarketData

julia> bitget = Bitget()
Bitget("https://api.bitget.com", "https://www.bitget.com", Dict{Any, Any}(), "dmcbl")

julia> bitmex = Bitmex()
Bitmex("https://www.bitmex.com", Dict{Any, Any}())

julia> bitstamp = Bitstamp()
Bitstamp("https://www.bitstamp.net")

julia> bybit = Bybit()
Bybit("https://api.bybit.com", Dict{Any, Any}(), "inverse")

julia> pancakeswap = PancakeSwap()
PancakeSwap("https://perp.pancakeswap.finance", Dict{Any, Any}())
```

Some of you who live in forbidden countries will need to use a proxy. Setting
up a proxy is beyond the scope of this document, but I recommend
[Squid](https://www.digitalocean.com/community/tutorials/how-to-set-up-squid-proxy-on-ubuntu-22-04).

```julia-repl
julia> bybit = Bybit(Dict(:proxy => "http://user:pass@proxyhost:3128"))
Bybit("https://api.bybit.com", Dict(:proxy => "http://user:pass@proxyhost:3128"), "inverse")
```

## Get a List of Available Markets

```julia-repl
julia> markets = get_markets(bitstamp); markets[1:5]
5-element Vector{String}:
 "BTC/USD"
 "BTC/EUR"
 "BTC/GBP"
 "BTC/PAX"
 "GBP/USD"
```

## Save Candles

This is the most basic thing you can do with this library.

```julia-repl
julia> save!(bitstamp, "BTC/USD"; endday=Date("2011-08-25"))
┌ Info: 2011-08-18
└   length(cs) = 683
┌ Info: 2011-08-19
└   length(cs) = 1440
┌ Info: 2011-08-20
└   length(cs) = 1440
┌ Info: 2011-08-21
└   length(cs) = 1440
┌ Info: 2011-08-22
└   length(cs) = 1440
┌ Info: 2011-08-23
└   length(cs) = 1440
┌ Info: 2011-08-24
└   length(cs) = 1440
┌ Info: 2011-08-25
└   length(cs) = 1440
```

### Find Out When Candle Data for a Market Begins

```julia-repl
julia> ec = earliest_candle(bitstamp, "BTC/USD")
BitstampCandle(0x000000004e4d076c, 10.9, 10.9, 10.9, 10.9, 0.48990826)

julia> candle_datetime(ec)
2011-08-18T12:37:00
```

## Load Candles

### Everything

```julia-repl
julia> btcusd = load(bitstamp, "BTC/USD")
```

### Within a Certain Date Range

```julia-repl
julia> btcusd = load(bitstamp, "BTC/USD";
  span=Date("2024-01-01"):Date("2024-01-15"))
```

### In a Certain Time Frame

```julia-repl
julia> btcusd4h = load(bitstamp, "BTC/USD";
  tf=Hour(4), span=Date("2024-01-01"):Date("2024-01-15"))
```

