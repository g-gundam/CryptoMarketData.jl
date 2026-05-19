# CryptoMarketData

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://g-gundam.github.io/CryptoMarketData.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://g-gundam.github.io/CryptoMarketData.jl/dev/)
[![Build Status](https://github.com/g-gundam/CryptoMarketData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/g-gundam/CryptoMarketData.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/g-gundam/CryptoMarketData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/g-gundam/CryptoMarketData.jl)

A library for saving and loading OHLCV candle data from cryptocurrency exchanges

## Goals

1.  **Be able to save 1 minute candle data from a variety of cryptocurrency exchanges.**
    + I only want 1 minute candles, because I can derive higher timeframes myself.
    + Implement extremely minimal exchange drivers for this purpose.
      - Don't try to do everything.
      - Focus on fetching 1 minute and 1 day candles well.
    + Save all the candle data the exchange gives us.
      - Save even the non-OHLCV data.
      - I don't care about it, but maybe someone else does.
      - Each day worth of 1 minute candles should be saved in its own date-stamped CSV file.
2.  **After saving, be able to load that data into a DataFrame.**
    + 1m candles are the default.
    + Other arbitrary timeframes should be supported.
3.  **Be able to subscribe to WebSocket APIs and publish finished 1 minute candles to a `Channel`.**
    + WebSocket connections should be supervised and automatically reconnected.
    + Data subscriptions should also be automatically renewed on reconnection.

## Exchanges

| Name        | Candle Archival  | WebSockets  |
|-------------|------------------|-------------|
| Binance     | Work in Progress | Not Started |
| Bitget      | Slightly Broken  | Not Started |
| Bitmex      | Done             | Not Started |
| Bitstamp    | Done             | Done        |
| Bybit       | Done             | Not Started |
| Kraken      | Not Started      | Not Started |
| PancakeSwap | Done             | Not Started |

## Examples

### Save and Load Candles

This is the most basic thing you can do with this library.

```julia-repl
julia> using CryptoMarketData

julia> bitstamp = Bitstamp()
Bitstamp("https://www.bitstamp.net")

julia> markets = get_markets(bitstamp); markets[1:5]
5-element Vector{String}:
 "BTC/USD"
 "BTC/EUR"
 "BTC/GBP"
 "BTC/PAX"
 "GBP/USD"

julia> ENV["JULIA_DEBUG"] = "CryptoMarketData"
"CryptoMarketData"

julia> save!(bitstamp, "BTC/USD"; endday=Date("2011-08-25"))
┌ Debug: 2011-08-18
└   length(cs) = 683
┌ Debug: 2011-08-19
└   length(cs) = 1440
┌ Debug: 2011-08-20
└   length(cs) = 1440
┌ Debug: 2011-08-21
└   length(cs) = 1440
┌ Debug: 2011-08-22
└   length(cs) = 1440
┌ Debug: 2011-08-23
└   length(cs) = 1440
┌ Debug: 2011-08-24
└   length(cs) = 1440
┌ Debug: 2011-08-25
└   length(cs) = 1440

julia> btcusd = load(bitstamp, "BTC/USD");
```

### Stream Finished Candles

Stream finished 1m candles from a websocket.

``` julia
"""
Print finished candles from `ch` as they come.
"""
function consumer(ch)
    while true
        candle = take!(ch)
        print(now(), " ", candle, "\n")
    end
end
```

``` julia-repl
# Start a supervised websocket connection.
julia> ses = start(bitstamp, "BTC/USD");

# Request a channel of candles.
julia> (ch, t, o) = stream(ses);

# Start a task that consumes from `ch`.
julia> tc = @task consumer(ch)
Task (runnable) @0x0000749ede937490

# After the initial dump of candles,
# near the beginning of every new minute,
# the finished candle from the previous minute should be printed.
julia> schedule(tc)

# Stop the consumer task.
julia> schedule(tc, InterruptException(); error=true);

# Stop the supervised websocket connection.
julia> stop(ses);
```
