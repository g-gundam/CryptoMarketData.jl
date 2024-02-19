var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = CryptoMarketData","category":"page"},{"location":"#CryptoMarketData","page":"Home","title":"CryptoMarketData","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for CryptoMarketData.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [CryptoMarketData]","category":"page"},{"location":"#CryptoMarketData.earliest_candle-Tuple{CryptoMarketData.AbstractExchange, Any}","page":"Home","title":"CryptoMarketData.earliest_candle","text":"earliest_candle(exchange, market)\n\nReturn the earliest candle for the given market in the 1m timeframe.\n\n\n\n\n\n","category":"method"},{"location":"#CryptoMarketData.get_candles_for_day-Tuple{CryptoMarketData.AbstractExchange, Any, Dates.Date}","page":"Home","title":"CryptoMarketData.get_candles_for_day","text":"get_candles_for_day(exchange, market, day::Date)\n\nFetch all of the 1m candles for the given exchange, market, and day. The vector and candles returned is just the right size to save to the archives.\n\n\n\n\n\n","category":"method"},{"location":"#CryptoMarketData.load-Tuple{CryptoMarketData.AbstractExchange, Any}","page":"Home","title":"CryptoMarketData.load","text":"load(exchange, market)\n\nLoad candles for the given exchange and market from the file system.\n\n\n\n\n\n","category":"method"},{"location":"#CryptoMarketData.save!-Tuple{CryptoMarketData.AbstractExchange, Any}","page":"Home","title":"CryptoMarketData.save!","text":"save!(exchange, market; datadir=\"./data\", endday=today(tz\"UTC\"), delay=0.5)\n\nDownload 1m candles from the given exchange and market, and save them locally.\n\nExample\n\njulia> bitstamp = Bitstamp()\njulia> save!(bitstamp, \"BTC/USD\", endday=Date(\"2020-08-16\"))\n\n\n\n\n\n","category":"method"},{"location":"#CryptoMarketData.save_day!-Tuple{CryptoMarketData.AbstractExchange, Any, Any}","page":"Home","title":"CryptoMarketData.save_day!","text":"save_day!(exchange, market, candles; datadir=\"./data\")\n\nSave a day worth of 1m candles the caller provides for the given exchange and market.\n\n\n\n\n\n","category":"method"}]
}
