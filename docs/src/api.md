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

### Session

This contains the data needed for a persistent connection to an exchange's WebSocket API.
Through this, one can start and stop a WebSocket connection.  The connection will also
be supervised and automatically restarted if prematurely disconnected.

```julia
@kwdef mutable struct Session
    exchange::AbstractExchange
    market::AbstractString
    candles::Vector{<: AbstractCandle}
    new_candle::Observable
    last_candle::Any # Union{Missing, DataType, AbstractCandle}
    ws::Union{Missing, HTTP.WebSockets.WebSocket}
    supervisor::Union{Missing, Visor.Supervisor}
    supervisor_ws::Union{Missing, Visor.Supervisor}
end
```

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
load_remote
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

### WebSocket Functions

The following 3 functions are the main ways one interacts with WebSockets through this system.

- [`start`](@ref)
- [`stop`](@ref)
- [`stream`](@ref)

```@docs
start
```

```@docs
stop
```

```@docs
stream
```

The following functions support the above, but a user of this library probably never needs to call them.  Nevertheless, they're documented here for completeness.

- [`observe`](@ref)
- [`feed`](@ref)
- [`ws_process`](@ref) 
- [`accumulator_process`](@ref)
- [`command_process`](@ref)

```@docs
observe
```

```@docs
feed
```

```@docs
ws_process
```

```@docs
accumulator_process
```

```@docs
command_process
```

### Exchange Specific Implementations

- [`csv_headers`](@ref)
- csv_select
- ts2datetime_fn
- short_name
- candles_max
- [`get_markets`](@ref)
- get_candles
- [`update!`](@ref)
- [`ws_handle_message`](@ref)
- [`ws_subscribe_commands`](@ref)
- [`ws_uri`](@ref)
- [`Base.merge`](@ref)

```@docs
csv_headers
```

```@docs
get_markets
```

```@docs
update!
```

```@docs
ws_handle_message
```

```@docs
ws_subscribe_commands
```

```@docs
ws_uri
```

```@docs
Base.merge
```

### Other

- [`Base.convert`](@ref)

```@docs
Base.convert
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
