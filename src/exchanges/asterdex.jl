ASTERDEX_FUTURES_V3_API = "https://fapi.asterdex.com"
ASTERDEX_FUTURES_V3_WS_API = "wss://fstream.asterdex.com/ws/"

@kwdef struct AsterdexFutures <: AbstractExchange
    base_url::AbstractString = ASTERDEX_FUTURES_V3_API
    ws_url::AbstractString = ASTERDEX_FUTURES_V3_WS_API
    http_options::AbstractDict = Dict{Symbol, AbstractString}()
end

# https://asterdex.github.io/aster-api-website/futures-v3/market-data/#klinecandlestick-data
# https://asterdex.github.io/aster-api-website/futures-v3/websocket-market-streams/#klinecandlestick-streams
@kwdef struct AsterdexFuturesCandle <: AbstractCandle
    ts::UInt64                  # Open time
    o::Float64                  # Open
    h::Float64                  # High
    l::Float64                  # Low
    c::Float64                  # Close
    v::Float64                  # Volume
    cts::UInt64                 # Close time
    qv::Float64                 # Quote asset volume
    trades::Int64               # Number of trades
    tbvv::Float64               # Taker buy base asset volume
    tbqv::Float64               # Taker buy quote asset volume
    ignore::Float64             # Ignore
end

function candle_type(asterdex::AsterdexFutures)
    AsterdexFuturesCandle
end

function csv_headers(asterdex::AsterdexFutures)
    collect(fieldnames(AsterdexFuturesCandle))
end

function csv_select(asterdex::AsterdexFutures)
    1:6
end

function ts2datetime_fn(asterdex::AsterdexFutures)
    DateTime ∘ unixmillis2nanodate
end

function candle_datetime(c::AsterdexFuturesCandle)
    unixmillis2nanodate(c.ts)
end

function short_name(asterdex::AsterdexFutures)
    "asterdex-futures"
end

function candles_max(asterdex::AsterdexFutures; tf=Minute(1))
    1500
end

function get_markets(asterdex::AsterdexFutures)
    url = asterdex.base_url * "/fapi/v3/exchangeInfo"
    uri = URI(url)
    res = HTTP.get(uri; asterdex.http_options...)
    json = JSON3.read(res.body)
    return map(m -> m[:pair], json[:symbols])
end

function get_candles(asterdex::AsterdexFutures, market; start, stop, tf=Minute(1), limit::Integer=10)
    interval = if tf == Day(1)
        "1d"
    elseif tf == Minute(1)
        "1m"
    else
        "1m"
    end
    q = OrderedDict(
        "symbol"    => market,
        "interval"  => interval,
        "startTime" => nanodate2unixmillis(NanoDate(start)),
        "stopTime"  => nanodate2unixmillis(NanoDate(stop)),
        "limit"     => limit
    )
    kline_url = asterdex.base_url * "/fapi/v3/klines"
    uri = URI(kline_url; query=q)
    headers = ["Content-Type" => "application/json"]
    res = HTTP.get(uri, headers; asterdex.http_options...)
    json = JSON3.read(res.body)
    return map(reverse(json)) do c
        AsterdexFuturesCandle(
            convert(UInt64, c[1]),
            pf64(c[2]),
            pf64(c[3]),
            pf64(c[4]),
            pf64(c[5]),
            pf64(c[6]),
            convert(UInt64, c[7]),
            pf64(c[8]),
            c[9],
            pf64(c[10]),
            pf64(c[11]),
            pf64(c[12])
        )
    end
end

# Asterdex requires a different technique.
# This should be faster.
function earliest_candle(asterdex::AsterdexFutures, market; endday=today(tz"UTC"))
    url = asterdex.base_url * "/fapi/v3/exchangeInfo"
    uri = URI(url)
    res = HTTP.get(uri; asterdex.http_options...)
    json = JSON3.read(res.body)
    m_i = findfirst(s -> s[:symbol] == market, json[:symbols])
    if isnothing(m_i)
        return nothing
    end
    market_info = json[:symbols][m_i]
    onboard_date = unixmillis2nanodate(market_info[:onboardDate])
    starting_month = floor(onboard_date, Month)
    stop = starting_month + Day(60)
    cs = get_candles(asterdex, market; start=starting_month, stop, limit=1)
    if length(cs) > 0
        cs[1]
    else
        nothing
    end
end

function ws_uri(asterdex::AsterdexFutures)
    URI(asterdex.ws_url)
end

function ws_subscribe_commands(asterdex::AsterdexFutures, market::AbstractString)
    lc_market = lowercase(market)
    [
        JSON3.write(Dict(:method => "SUBSCRIBE", :params => ["$(lc_market)@kline_1m"]))
    ]
end

function ws_handle_message(asterdex::AsterdexFutures, s::Session, msg::AbstractString)
    data = JSON3.read(msg)
    commander = Visor.from_name(s.supervisor, "command_process")
    @info msg
    if haskey(data, :e)
        if data[:e] == "kline"
            new_candle = merge(s.last_candle, data)
            cast(commander, new_candle)
            s.last_candle = new_candle
        elseif data[:e] == "ping"
            # TODO: send pong.
            @info :ax note="ping received; need to send pong"
        else
            @warn :ax note="unknown message type" data["event"]
        end
    else
        @warn :ax note="data has no 'event' key." data
    end
end

# used by CryptoMarketData.update!

function Base.merge(a::AsterdexFuturesCandle, b::AsterdexFuturesCandle)
    @assert a.ts == b.ts # hopefully, whoever is calling update can guarantee this, so I can get rid of this.
    high = max(a.h, b.h)
    low  = min(a.l, b.l)
    return AsterdexFuturesCandle(a.ts, a.o, high, low, b.c, b.v, b.cts, b.qv, b.trades, b.tbvv, b.tbqv, b.ignore)
end

# initial candle
function Base.merge(a::Type{AsterdexFuturesCandle}, b::AbstractDict; tf=Minute(1))
    k = b[:k]
    return AsterdexFuturesCandle(
        ts=convert(UInt64, k[:t]),
        o=parse(Float64, k[:o]),
        h=parse(Float64, k[:h]),
        l=parse(Float64, k[:l]),
        c=parse(Float64, k[:c]),
        v=parse(Float64, k[:v]),
        cts=convert(UInt64, k[:T]),
        qv=parse(Float64, k[:q]),
        trades=k[:n],
        tbvv=parse(Float64, k[:V]),
        tbqv=parse(Float64, k[:Q]),
        ignore=parse(Float64, k[:B])
    )
end

# subsequent candles
function Base.merge(a::AsterdexFuturesCandle, b::AbstractDict; tf=Minute(1))
    k = b[:k]
    b_ts = convert(UInt64, k[:t])
    if a.ts == b_ts
        # update candle
        return AsterdexFuturesCandle(
            ts=a.ts,
            o=a.o,
            h=max(a.h, parse(Float64, k[:h])),
            l=min(a.l, parse(Float64, k[:l])),
            c=parse(Float64, k[:c]),
            v=parse(Float64, k[:v]),
            cts=convert(UInt64, k[:T]),
            qv=parse(Float64, k[:q]),
            trades=k[:n],
            tbvv=parse(Float64, k[:V]),
            tbqv=parse(Float64, k[:Q]),
            ignore=parse(Float64, k[:B])
        )
    else
        # new candle
        return AsterdexFuturesCandle(
            ts=b_ts,
            o=parse(Float64, k[:o]),
            h=parse(Float64, k[:h]),
            l=parse(Float64, k[:l]),
            c=parse(Float64, k[:c]),
            v=parse(Float64, k[:v]),
            cts=convert(UInt64, k[:T]),
            qv=parse(Float64, k[:q]),
            trades=k[:n],
            tbvv=parse(Float64, k[:V]),
            tbqv=parse(Float64, k[:Q]),
            ignore=parse(Float64, k[:B])
        )
    end
end

export AsterdexFutures
export AsterdexFuturesCandle
