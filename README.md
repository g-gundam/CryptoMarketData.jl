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

## Exchanges

| Name        | Status                                                                          |
|-------------|---------------------------------------------------------------------------------|
| Binance     | Work in Progress                                                                |
| Bitget      | It was working, but an undocumented API call changed and slightly broke things. |
| Bitmex      | Done                                                                            |
| Bitstamp    | Done                                                                            |
| Bybit       | Done                                                                            |
| PancakeSwap | Done                                                                            |

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

julia> btcusd = load(bitstamp, "BTC/USD")
```
