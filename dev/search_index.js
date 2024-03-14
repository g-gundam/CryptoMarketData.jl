var documenterSearchIndex = {"docs":
[{"location":"api/","page":"API","title":"API","text":"CurrentModule = CryptoMarketData","category":"page"},{"location":"api/#API","page":"API","title":"API","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Documentation for CryptoMarketData.","category":"page"},{"location":"api/#Types","page":"API","title":"Types","text":"","category":"section"},{"location":"api/#AbstractExchange","page":"API","title":"AbstractExchange","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Every exchange is a subtype of this.","category":"page"},{"location":"api/#AbstractCandle","page":"API","title":"AbstractCandle","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Every exchange also has a matching candle type that's a subtype of AbstractCandle. Its purpose is to capture the data given to us by the exchange.","category":"page"},{"location":"api/#Functions","page":"API","title":"Functions","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"","category":"page"},{"location":"api/","page":"API","title":"API","text":"Modules = [CryptoMarketData]","category":"page"},{"location":"api/#CryptoMarketData.earliest_candle-Tuple{CryptoMarketData.AbstractExchange, Any}","page":"API","title":"CryptoMarketData.earliest_candle","text":"earliest_candle(exchange, market)\n\nReturn the earliest candle for the given market in the 1m timeframe.\n\n\n\n\n\n","category":"method"},{"location":"api/#CryptoMarketData.get_candles_for_day-Tuple{CryptoMarketData.AbstractExchange, Any, Dates.Date}","page":"API","title":"CryptoMarketData.get_candles_for_day","text":"get_candles_for_day(exchange, market, day::Date)\n\nFetch all of the 1m candles for the given exchange, market, and day. The vector and candles returned is just the right size to save to the archives.\n\n\n\n\n\n","category":"method"},{"location":"api/#CryptoMarketData.get_markets-Tuple{Any}","page":"API","title":"CryptoMarketData.get_markets","text":"get_markets(exchange)\n\nFetch the available markets for the given exchange.\n\nExample\n\njulia> bitstamp = Bitstamp()\njulia> markets = get_markets(bitstamp)\n\n\n\n\n\n","category":"method"},{"location":"api/#CryptoMarketData.get_saved_markets-Tuple{}","page":"API","title":"CryptoMarketData.get_saved_markets","text":"get_saved_markets(; datadir)\n\n\nReturn a DataFrame that lists the currently saved markets.\n\nKeyword Arguments\n\ndatadir=\"./data\" - directory where saved data is stored\n\nExample\n\njulia> saved = get_saved_markets()\n10×4 DataFrame\n Row │ exchange       market          start       stop\n     │ Any            Any             Any         Any\n─────┼───────────────────────────────────────────────────────\n   1 │ binance        BTCUSD_240628   2023-12-29  2024-02-17\n   2 │ binance        BTCUSD_PERP     2020-08-11  2020-08-16\n   3 │ bitget         BTCUSD_DMCBL    2019-04-23  2024-02-16\n   4 │ bitget         DOGEUSD_DMCBL   2024-02-01  2024-02-20\n   5 │ bitmex         ETHUSD          2018-08-02  2024-02-19\n   6 │ bitstamp       BTCUSD          2011-08-18  2024-02-25\n   7 │ bybit          ADAUSD          2022-03-24  2022-04-21\n   8 │ bybit-inverse  ADAUSD          2022-03-24  2022-04-20\n   9 │ bybit-linear   10000LADYSUSDT  2023-05-11  2024-03-04\n  10 │ pancakeswap    BTCUSD          2023-03-15  2024-03-04\n\n\n\n\n\n","category":"method"},{"location":"api/#CryptoMarketData.load-Tuple{CryptoMarketData.AbstractExchange, Any}","page":"API","title":"CryptoMarketData.load","text":"load(exchange, market; datadir, span, tf, table)\n\n\nLoad candles for the given exchange and market from the file system.\n\nKeyword Arguments\n\ndatadir=\"./data\" - directory where saved data is stored\nspan - a Date span that defines what Dates to load candles.  If it's missing, load everything.\ntf - a Period that is used to aggregate 1m candles into higher timeframes.\ntable - a Tables.jl-compatible struct to load candles into.  The default is DataFrame.\n\nExample\n\njulia> bitstamp = Bitstamp()\njulia> btcusd4h = load!(bitstamp, \"BTC/USD\"; span=Date(\"2024-01-01\"):Date(\"2024-02-10\"), tf=Hour(4))\n\n\n\n\n\n","category":"method"},{"location":"api/#CryptoMarketData.save!-Tuple{CryptoMarketData.AbstractExchange, Any}","page":"API","title":"CryptoMarketData.save!","text":"save!(exchange, market; datadir, startday, endday, delay)\n\n\nDownload 1m candles from the given exchange and market, and save them locally.\n\nKeyword Arguments\n\ndatadir=\"./data\" - directory where saved data is stored\nstartday - a Date to start fetching candles from\nendday - a Date to stop fetching candles\ndelay - a delay to be passed to sleep() that will pause between internal calls to save_day!()\n\nExample\n\njulia> bitstamp = Bitstamp()\njulia> save!(bitstamp, \"BTC/USD\", endday=Date(\"2020-08-16\"))\n\n\n\n\n\n","category":"method"},{"location":"api/#CryptoMarketData.save_day!-Tuple{CryptoMarketData.AbstractExchange, Any, Any}","page":"API","title":"CryptoMarketData.save_day!","text":"save_day!(exchange, market, candles; datadir=\"./data\")\n\nSave a day worth of 1m candles the caller provides for the given exchange and market.\n\nKeyword Arguments\n\ndatadir=\"./data\" - directory where saved data is stored\n\n\n\n\n\n","category":"method"},{"location":"exchanges/#Exchanges","page":"Exchanges","title":"Exchanges","text":"","category":"section"},{"location":"exchanges/#Binance","page":"Exchanges","title":"Binance","text":"","category":"section"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Status:  Work in Progress","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"I have a preliminary Binance struct, and it supports Binance's COIN-M Futures API.  It works, but to properly support all of Binance's APIs, I'm going to have to add more structs and rename the current Binance struct to something like BinanceCMFutures.  In the end, there may be 4 or 5 exchange types just for Binance.","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Proxies are needed if you're local IP is from a forbidden country.","category":"page"},{"location":"exchanges/#Bitget","page":"Exchanges","title":"Bitget","text":"","category":"section"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Status:  Slightly Broken","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"I had to use an undocumented API that their trading front-end uses to acquire 1m candles, because their official API only gives you the last 30 days of 1m candles.  It was working fine for a while, but in early February 2024, its behavior changed and broke earliest_candle().","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"The constructor for Bitget takes an optional named parameter type to specify which productType to use.  The default value is dmcbl.","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Proxies are needed if you're local IP is from a forbidden country.","category":"page"},{"location":"exchanges/#Bitmex","page":"Exchanges","title":"Bitmex","text":"","category":"section"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Status:  DONE","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"When running save!(bitmex, market), I strongly advise setting delay=3.5. That'll keep you under the rate limit for unauthenticated users.","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"One thing I like about this library is that you don't need to be authenticated to use it.  However, Bitmex gives authenticated users a much better rate limit, so I'd like to support authentication eventually.","category":"page"},{"location":"exchanges/#Bitstamp","page":"Exchanges","title":"Bitstamp","text":"","category":"section"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Status:  DONE","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"This exchange is a valuable source of historical data.  Their \"BTC/USD\" goes back all the way to 2011-08-18 which is the longest of any known exchange.","category":"page"},{"location":"exchanges/#Bybit","page":"Exchanges","title":"Bybit","text":"","category":"section"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Status:  DONE","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"The Bybit constructor takes an optional category parameter that chooses which of the 3 market categories to use.  The default value is inverse, but linear and spot can also be specified.","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"julia> bybit_spot = Bybit(;category=spot)\nBybit(\"https://api.bybit.com\", Dict{Any, Any}(), \"spot\")","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Proxies are needed if you're local IP is from a forbidden country.","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"(The v5 iteration of their API is one of the nicest I've worked with.)","category":"page"},{"location":"exchanges/#PancakeSwap","page":"Exchanges","title":"PancakeSwap","text":"","category":"section"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"Status:  DONE*","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"I say it's done, but I'm not totally sure.  Instead of using documentation (which I couldn't find), I ended up reverse engineering their APIs.  I later discovered that they look a lot like Binance's APIs, and that helped me take this to a working state.","category":"page"},{"location":"exchanges/","page":"Exchanges","title":"Exchanges","text":"This is the only DEX among the currently supported exchanges.","category":"page"},{"location":"examples/#Examples","page":"Examples","title":"Examples","text":"","category":"section"},{"location":"examples/#Construct-an-Exchange","page":"Examples","title":"Construct an Exchange","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"The defaults are usually fine.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> using CryptoMarketData\n\njulia> bitget = Bitget()\nBitget(\"https://api.bitget.com\", \"https://www.bitget.com\", Dict{Any, Any}(), \"dmcbl\")\n\njulia> bitmex = Bitmex()\nBitmex(\"https://www.bitmex.com\", Dict{Any, Any}())\n\njulia> bitstamp = Bitstamp()\nBitstamp(\"https://www.bitstamp.net\")\n\njulia> bybit = Bybit()\nBybit(\"https://api.bybit.com\", Dict{Any, Any}(), \"inverse\")\n\njulia> pancakeswap = PancakeSwap()\nPancakeSwap(\"https://perp.pancakeswap.finance\", Dict{Any, Any}())","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Some exchanges categorize their markets in a way that affects the API calls that must be used to access them. This is expressed during exchange construction.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> bitget_u = Bitget(;type=\"umcbl\")\nBitget(\"https://api.bitget.com\", \"https://www.bitget.com\", Dict{Any, Any}(), \"umcbl\")\n\njulia> bitget_d = Bitget(;type=\"dmcbl\") # default\nBitget(\"https://api.bitget.com\", \"https://www.bitget.com\", Dict{Any, Any}(), \"dmcbl\")\n\njulia> markets_u = get_markets(bitget_u);\n\njulia> markets_d = get_markets(bitget_d);\n\njulia> size(markets_u)\n(195,)\n\njulia> size(markets_d)\n(12,)","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Some of you who live in forbidden countries will need to use a proxy that's outside of your home country to get around IP bans.  Setting up a proxy is beyond the scope of this document, but I recommend Squid.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> bybit = Bybit(Dict(:proxy => \"http://user:pass@proxyhost:3128\"))\nBybit(\"https://api.bybit.com\", Dict(:proxy => \"http://user:pass@proxyhost:3128\"), \"inverse\")","category":"page"},{"location":"examples/#Get-a-List-of-Available-Markets","page":"Examples","title":"Get a List of Available Markets","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> markets = get_markets(bitstamp); markets[1:5]\n5-element Vector{String}:\n \"BTC/USD\"\n \"BTC/EUR\"\n \"BTC/GBP\"\n \"BTC/PAX\"\n \"GBP/USD\"","category":"page"},{"location":"examples/#Save-Candles","page":"Examples","title":"Save Candles","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"This is the most basic thing you can do with this library.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> save!(bitstamp, \"BTC/USD\"; endday=Date(\"2011-08-25\"))\n┌ Info: 2011-08-18\n└   length(cs) = 683\n┌ Info: 2011-08-19\n└   length(cs) = 1440\n┌ Info: 2011-08-20\n└   length(cs) = 1440\n┌ Info: 2011-08-21\n└   length(cs) = 1440\n┌ Info: 2011-08-22\n└   length(cs) = 1440\n┌ Info: 2011-08-23\n└   length(cs) = 1440\n┌ Info: 2011-08-24\n└   length(cs) = 1440\n┌ Info: 2011-08-25\n└   length(cs) = 1440","category":"page"},{"location":"examples/#Find-Out-When-Candle-Data-for-a-Market-Begins","page":"Examples","title":"Find Out When Candle Data for a Market Begins","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> ec = earliest_candle(bitstamp, \"BTC/USD\")\nBitstampCandle(0x000000004e4d076c, 10.9, 10.9, 10.9, 10.9, 0.48990826)\n\njulia> candle_datetime(ec)\n2011-08-18T12:37:00","category":"page"},{"location":"examples/#Load-Candles","page":"Examples","title":"Load Candles","text":"","category":"section"},{"location":"examples/#Everything","page":"Examples","title":"Everything","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> btcusd = load(bitstamp, \"BTC/USD\")","category":"page"},{"location":"examples/#Within-a-Certain-Date-Range","page":"Examples","title":"Within a Certain Date Range","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> btcusd = load(bitstamp, \"BTC/USD\";\n  span=Date(\"2024-01-01\"):Date(\"2024-01-15\"))","category":"page"},{"location":"examples/#In-a-Certain-Time-Frame","page":"Examples","title":"In a Certain Time Frame","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> btcusd4h = load(bitstamp, \"BTC/USD\";\n  tf=Hour(4), span=Date(\"2024-01-01\"):Date(\"2024-01-15\"))","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = CryptoMarketData","category":"page"},{"location":"#CryptoMarketData","page":"Home","title":"CryptoMarketData","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A library for saving and loading OHLCV candle data from cryptocurrency exchanges","category":"page"},{"location":"#Goals","page":"Home","title":"Goals","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Be able to save 1 minute candle data from a variety of cryptocurrency exchanges.\nI only want 1 minute candles, because I can derive higher timeframes myself.\nImplement extremely minimal exchange drivers for this purpose.\nDon't try to do everything.\nFocus on fetching 1 minute and 1 day candles well.\nSave all the candle data the exchange gives us.\nSave even the non-OHLCV data.\nI don't care about it, but maybe someone else does.\nEach day worth of 1 minute candles should be saved in its own date-stamped CSV file.\nAfter saving, be able to load that data into a DataFrame.\n1m candles are the default.\nOther arbitrary timeframes should be supported.","category":"page"},{"location":"#Exchanges","page":"Home","title":"Exchanges","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Name Status\nBinance Work in Progress\nBitget Slightly Broken\nBitmex Done\nBitstamp Done\nBybit Done\nPancakeSwap Done","category":"page"}]
}
