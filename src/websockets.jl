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
