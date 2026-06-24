using Visor

"""$(TYPEDSIGNATURES)

This Visor.Process is responsible for connecting to an exchange's webscoket
and initiating a subscription to whatever data the session wants.
"""
function ws_process(td::Visor.Process, s::Session)
    @info :ws note="starting ws_process"
    uri = ws_uri(s.exchange)
    commander = Visor.from_name(s.supervisor, "command_process")
    accumulator = Visor.from_name(s.supervisor, "accumulator_process")
    @info :ws typeof(commander) typeof(accumulator)
    if isnothing(commander)
        @info :ws note="No commander so shutting down."
        shutdown(td)
        return
    end
    try
        WebSockets.open(uri) do ws
            @info :ws note="connected to $uri"
            s.ws = ws
            cast(commander, (:subscribe,))
            while true
                # Keep an eye out for shutdown requests,
                if isshutdown(td)
                    break
                end
                # ...but mostly consume websocket data.
                msg = WebSockets.receive(ws)
                cast(accumulator, msg)
            end
            @info :ws note="Closing time."
            close(ws)
        end
    catch e
        @info :ws note="Closing due to exception" typeof(e)
    end
    @info :ws note="the end"
end

"""$(TYPEDSIGNATURES)

This Visor.Process's job is to accumulate price data into finished candles and
send them to the `command_process`.
"""
function accumulator_process(td::Visor.Process, s::Session)
    # Initial candle starts as the type,
    # because Base.merge methods will dispatch on last_candle to do the right thing.
    last_candle = s.last_candle = candle_type(s.exchange)
    commander = Visor.from_name(s.supervisor, "command_process")
    for msg in td.inbox
        @debug :ax msg
        if isshutdown(msg)
            break
        else
            # INFO: Refactored exchange-specific code into its own method.
            ws_handle_message(s.exchange, s, msg)
        end
    end
    @info :ax note="Shutting down"
    # All I want to do is turn JSON into a candle and send it over to commander.
end

"""$(TYPEDSIGNATURES)

This Visor.Process is the main command loop that users of the session will
interact with. It also receives messages from `candle_process` whenever it
completes a candle.
"""
function command_process(td::Visor.Process, s::Session)
    for msg in td.inbox
        @debug :command msg
        if isshutdown(msg)
            break
        elseif isa(msg, AbstractCandle)
            # update s.candles
            res = CryptoMarketData.update!(s.candles, msg)
            # publish to s.new_candle upon candle completion
            if res == :new
                s.new_candle[] = s.candles[end-1]
            end
        elseif isa(msg, Tuple)
            if msg[1] == :subscribe
                list = ws_subscribe_commands(s.exchange, s.market)
                for cmd in list
                    @info :command note="sending to ws" cmd
                    WebSockets.send(s.ws, cmd)
                end
            else
                @warn :command note="Unrecognized tuple format" msg
            end
        elseif isa(msg, Visor.Request)
            @info :command note="call" msg
            type = candle_type(s.exchange)
            ch = Channel{type}(60)
            put!(msg.inbox, ch)
            for c in s.candles
                put!(ch, c)
            end
        else
            @info :command note="unrecognized" msg
        end
    end
end

## INFO: From here on down is the public API.

"""$(TYPEDSIGNATURES)

This initiates a websocket connection with an `exchange`, and subscribes to the given `market`.
It also creates a supervision tree using Visor.jl that tries very hard to keep websocket connections alive.

# Example
```julia-repl
julia> bitstamp = Bitstamp();

julia> ses = start(bitstamp, "BTCUSD");
```
"""
function start(exchange::AbstractExchange, market::AbstractString; wait::Bool=false)
    ctype = candle_type(exchange)
    candles = Vector{ctype}()
    new_candle = Observable{AbstractCandle}()
    last_candle = candle_type(exchange)
    session = Session(exchange, market, candles, new_candle, last_candle, missing, missing, missing)
    procs = [
        process(accumulator_process, args=(session,)),
        process(command_process, args=(session,))
    ]
    session.supervisor = supervisor("$(string(typeof(exchange))).$market", procs; intensity=1, period=5)
    # Add the ws_process *AFTER* session.supervisor is set.
    procs2 = [process(ws_process; args=(session,), debounce_time=1.5, restart=:permanent), session.supervisor]
    session.supervisor_ws = supervisor("$(string(typeof(exchange))).$market.ws", procs2; intensity=5, period=5)
    if !wait
        supervise(procs2; wait=false)
    end
    session
end

"""$(TYPEDSIGNATURES)

Feed a channel with candles.
Once the candles are up to date with the present, start observing `session.new_candles`,
and feed those into the given channel as they come.
"""
function feed(session::Session, ch::Channel, from::Date, live::Observable)
    tday = today(tz"UTC")
    span = from:tday
    CandleType = candle_type(session.exchange)
    # load initial candles into channel
    initial_candles = load(session.exchange, session.market; span, remote=true)
    @info :feed note="initial_candles" size(initial_candles)
    # put all but last candle into ch
    for row in eachrow(initial_candles)[begin:end-1]
        c = convert(CandleType, row)
        put!(ch, c)
    end
    # after that's done, fill in any gap between the last inserted candle and the most recent available
    # - What time is it now?
    t_now = floor(now(tz"UTC").utc_datetime, Minute)
    # - What time is the last candle we have?
    t_last = initial_candles[end, :ts]
    # - is there a gap?
    # - if so fetch again
    # - and fill the gap
    if (t_now - t_last > Second(60))
        secondary_candles = load(session.exchange, session.market; span=tday:tday, remote=true)
        # DONE: skip forward
        a = findfirst(==(t_last), secondary_candles.ts)
        @info :feed note="secondary_candles" size(secondary_candles) a
        for row in eachrow(secondary_candles)[a:end-1]
            # DONE: push candles to fill the gap
            c = convert(CandleType, row)
            put!(ch, c)
        end
    end

    # DONE: once caught up, setup an observer on session.new_candle
    @info :feed note="observe"
    live[] = on(session.new_candle) do c
        put!(ch, c)
    end
end

"""$(TYPEDSIGNATURES)

Observe the current session for new candles and publish them to `ch`.

# Example
```julia-repl
julia> (ch, observer) = observe(session, preload(session, Date("2026-05-05")))
```
"""
function observe(session::Session, ch::Channel)
    observer = on(session.new_candle) do candle
        t = @task put!(ch, candle)
        schedule(t)
    end
    return (ch, observer)
end

"""$(TYPEDSIGNATURES)

Return a tuple that contains a channel as its first element that 1 minute
candles will be published to in realtime as they are finalized.  Candles
from the past as specified by the `from` parameter are also published to the
channel before switching to websockets.

## Notes on other returned values
- The returned channel is what will be interacted with the most.
- The task is the async process that loads the initial candles into the channel and switches to publishing from websockets afterward.
- The observer is what waits for a candle to finish before publishing.
- The task and observer are returned for the sake of completeness, but they're rarely interacted with directly.

# Example
```julia-repl
julia> bitstamp = Bitstamp();

julia> ses = start(bitstamp, "BTCUSD");

julia> (ch, task, observer) = stream(ses, today() - Day(2));
```
"""
function stream(session, from::Date=(today(tz"UTC") - Day(1)))
    CandleType = candle_type(session.exchange)
    ch = Channel{CandleType}(60)
    live = Observable{Observable}()
    t = @task feed(session, ch, from, live)
    schedule(t)
    return (ch, t, live)
end

"""$(TYPEDSIGNATURES)

Close the session's websocket and shut down all of its supervised processes.

# Example
```julia-repl
julia> stop(ses)
```
"""
function stop(session::Session)
    wsp = Visor.from_name(session.supervisor_ws, "ws_process")
    shutdown(session.supervisor)
    close(session.ws)
    shutdown(wsp)
    # If my timing is lucky, I get a clean shutdown.
    # Unlucky timing is still very possible in which case I still
    # get big ugly strack traces.  I want to get it perfect,
    # but it's not the most important thing right now.

    #shutdown(session.supervisor_ws)
end

#=
# REPL Snippets
using CryptoMarketData, Dates

function consume(ch::Channel)
    while true
        candle = take!(ch)
        print(now(), " ", candle, "\n")
    end
end

bitstamp = Bitstamp()
ses = start(bitstamp)
(ch, task, observer0) = stream(ses, today() - Day(2))

t = @task consume(ch)
schedule(t)

schedule(t, InterruptException(); error=true)
=#
