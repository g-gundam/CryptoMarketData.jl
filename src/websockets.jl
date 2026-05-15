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
            handle_ws(s.exchange, s, msg)
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
        @info :command msg
        if isshutdown(msg)
            break
        elseif isa(msg, AbstractCandle)
            res = CryptoMarketData.update!(s.candles, msg)
            if res == :new
                ses.new_candle[] = s.candles[end-1]
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
