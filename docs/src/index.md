```@meta
CurrentModule = CryptoMarketData
```

# CryptoMarketData

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

| Name            | Candle Archival  | WebSockets  |
|-----------------|------------------|-------------|
| AsterdexFutures | DONE             | In Progress |
| Binance         | Work in Progress | Not Started |
| Bitget          | Slightly Broken  | Not Started |
| Bitmex          | Done             | Not Started |
| Bitstamp        | Done             | Done        |
| Bybit           | Done             | Not Started |
| Kraken          | Not Started      | Not Started |
| PancakeSwap     | Done             | Not Started |
