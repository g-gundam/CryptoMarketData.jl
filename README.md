# CryptoMarketData

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://g-gundam.github.io/CryptoMarketData.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://g-gundam.github.io/CryptoMarketData.jl/dev/)
[![Build Status](https://github.com/g-gundam/CryptoMarketData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/g-gundam/CryptoMarketData.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/g-gundam/CryptoMarketData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/g-gundam/CryptoMarketData.jl)

## Goals

1.  Be able to save 1m candle data from a variety of cryptocurrency exchanges.
    + Implement extremely minimal exchange drivers for this purpose.
      - Don't try to do everything.
      - Focus on fetching 1m (and 1d) candles well.
    + Save all the candle data the exchange gives us accurately in CSV format.
      - Each day worth of 1m candles is saved in its own date-stamped file.
2.  After saving, be able to load that data into a DataFrame.
    + 1m candles are the default.
    + Other arbitrary timeframes should be supported.

## Exchanges

| Name     | Status                                                                          |
|----------|---------------------------------------------------------------------------------|
| Binance  | Work in Progress                                                                |
| Bitget   | It was working, but an undocumented API call changed and slightly broke things. |
| Bitmex   | Done                                                                            |
| Bitstamp | Done                                                                            |
| Bybit    | Done                                                                            |

## Example

### Save and Load Candles

This is the most basic thing you can do with this library.

```julia-repl
julia> using CryptoMarketData
julia> bitstamp = Bitstamp()
julia> markets = get_markets(bitstamp)
julia> save!(bitstamp, "BTCUSD")
julia> btcusd = load(bitstamp, "BTCUSD")
```
