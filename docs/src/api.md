```@meta
CurrentModule = CryptoMarketData
```

# API

Documentation for [CryptoMarketData](https://github.com/g-gundam/CryptoMarketData.jl).

## Types

### AbstractExchange

Every exchange is a subtype of AbstractExchange.

### AbstractCandle

Every exchange also has a matching candle type that's a subtype of AbstractCandle.
Its purpose is to capture the data given to us by the exchange.

## Functions

### General Functions

- [`get_saved_markets`](@ref)

```@docs
get_saved_markets
```

### Generalized on Exchange

- [`save!`](@ref)
- [`load`](@ref)
- [`earliest_candle`](@ref)
- [`get_candles_for_day`](@ref)
- [`save_day!`](@ref)

```@docs
save!
```

```@docs
load
```

```@docs
earliest_candle
```

```@docs
get_candles_for_day
```

```@docs
save_day!
```

### Exchange Specific Implementations

- csv_headers
- csv_select
- ts2datetime_fn
- short_name
- candles_max
- [`get_markets`](@ref)
- get_candles

```@docs
get_markets
```
