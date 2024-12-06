using CryptoMarketData
using Dates
using Test

@testset "general" begin
    df = get_saved_markets()
    @test df.exchange[1] == "bitstamp"
    @test df.market[1] == "BTCUSD"
    @test df.start[1] == Date("2011-08-18")
    @test df.market[2] == "ETHUSD"
    @test ismissing(df.start[2])
end
