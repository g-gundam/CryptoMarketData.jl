PANCAKESWAP_API = "https://perp.pancakeswap.finance"
# This is for legacy mode which is on https://pancakeswap.finance/perp/v2/BTCUSD?theme=dark&chain=bsc
PANCAKESWAP_WS_API = "wss://perp-fstream.pancakeswap.finance/plain/stream?streams=!markPriceTicker@arr"
# This is for the current (2026) perps on https://pancakeswap.finance/perps/BTCUSDT?mode=pro
# XXX: May need to use this instead: wss://fstream.asterdex.com/ws

@kwdef struct PancakeSwap <: AbstractExchange
    base_url::AbstractString = PANCAKESWAP_API
    ws_url::AbstractString = PANCAKESWAP_WS_API
    http_options::AbstractDict = Dict{Symbol,AbstractString}()
end

@kwdef struct PancakeSwapCandle <: AbstractCandle
    ts::UInt64
    o::Float64
    h::Float64
    l::Float64
    c::Float64
    v::Float64
    close_ts::UInt64
    v2::Float64
    trades::UInt64
    tbv::Float64
    tbv2::Float64
    ignore::Float64
end

function candle_type(pancakeswap::PancakeSwap)
    PancakeSwapCandle
end

function csv_headers(pancakeswap::PancakeSwap)
    collect(fieldnames(PancakeSwapCandle))
end

function csv_select(pancakeswap::PancakeSwap)
    1:6
end

function ts2datetime_fn(pancakeswap::PancakeSwap)
    DateTime ∘ unixmillis2nanodate
end

function candle_datetime(c::PancakeSwapCandle)
    unixmillis2nanodate(c.ts)
end

function short_name(pancakeswap::PancakeSwap)
    "pancakeswap"
end

function candles_max(pancakeswap::PancakeSwap; tf=Minute(1))
    1500
end

# Hard-code the [list of market pairs](https://docs.pancakeswap.finance/products/perpetual-trading/perpetual-trading-v2/supported-chains-modes-and-markets#supported-chain-markets) until an API for this info is discovered.
PANCAKESWAP_MARKETS = [
    "BTCUSD",
    "MADBTCUSD",
    "ETHUSD",
    "BNBUSD",
    "SUIUSD",
    "CAKEUSD",
    "ARBUSD",
    "XRPUSD",
    "OPUSD",
    "RDNTUSD",
    "1000PEPEUSD",
    "SOLUSD",
    "DOTUSD",
    "MKRUSD",
    "LDOUSD",
    "UNIUSD",
    "DOGEUSD",
    "GMXUSD",
    "MATICUSD",
    "BCHUSD",
    "LTCUSD",
    "TRXUSD",
    "ADAUSD",
    "LINKUSD",
    "AVAXUSD",
    "EURUSD",
    "JPYUSD",
    "AUDUSD",
    "GBPUSD",
    "CHFUSD",
    "MXNUSD"
]

function get_markets(pancakeswap::PancakeSwap)
    # info_url = pancakeswap.base_url * "/fapi/v1/exchangeInfo"
    # uri = URI(info_url)
    # res = HTTP.get(uri; pancakeswap.http_options...)
    # json = JSON3.read(res.body)
    # return map(m -> m[:symbol], json[:symbols])
    return PANCAKESWAP_MARKETS
end

function get_candles(pancakeswap::PancakeSwap, market; start, stop, tf=Minute(1), limit::Integer=10)
    symbol = replace(market, r"\W" => s"") |> lowercase
    interval = if tf == Day(1)
        "1d"
    elseif tf == Minute(1)
        "1m"
    else
        "1m"
    end
    q = OrderedDict(
        "interval" => interval,
        "contractType" => "PERPETUAL",
        "startTime" => nanodate2unixmillis(NanoDate(start)),
        "endTime" => nanodate2unixmillis(NanoDate(stop)),
        "limit" => limit,
        "symbol" => symbol
    )
    ohlc_url = pancakeswap.base_url * "/fapi/v1/markPriceKlines"
    uri = URI(ohlc_url, query=q)
    res = HTTP.get(uri; pancakeswap.http_options...)
    json = JSON3.read(res.body)
    map(json) do c
        PancakeSwapCandle(
            c[1] % UInt64, # Casting Int64 to UInt64 :: https://discourse.julialang.org/t/casting-int64-to-uint64/33856/4
            pf64(c[2]),
            pf64(c[3]),
            pf64(c[4]),
            pf64(c[5]),
            pf64(c[6]),
            c[7] % UInt64,
            pf64(c[8]),
            c[9] % UInt64,
            pf64(c[10]),
            pf64(c[11]),
            pf64(c[12])
        )
    end
end

function ws_uri(pancakeswap::PancakeSwap)
    URI(pancakeswap.ws_url)
end

function ws_subscribe_commands(pancakeswap::PancakeSwap)
    []
end

function ws_handle_message(pancakeswap::PancakeSwap, s::Session, msg::AbstractString)
end

export PancakeSwap
export PancakeSwapCandle
