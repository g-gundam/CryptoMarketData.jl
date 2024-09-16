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
- [`subscribe`](@ref)

```@docs
get_markets
```

```@docs
subscribe
```

## Select

This was originally [NHDaly/Select.jl](https://github.com/NHDaly/Select.jl), but because it wasn't
easily installable, I absorbed it into this project.  If a better way to multiplex multiple streams
comes along, this may go away, but I'm going to use it until then.

- [`CryptoMarketData.Select.select`](@ref)
- [`CryptoMarketData.Select.@select`](@ref)

```@docs
CryptoMarketData.Select.select
```

```@docs
CryptoMarketData.Select.@select
```
