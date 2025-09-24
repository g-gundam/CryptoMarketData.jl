using CryptoMarketData
using Dates
using Test

@testset "general" begin
    df = get_saved_markets()
    @test df.exchange[1] == "bitstamp"
    @test df.market[1] == "BTCUSD"
    @test df.start[1] == Date("2011-08-18")
    @test df.market[2] == "ETHUSD"
    @test df.start[2] == Date("2024-11-11")
end

@testset "load tf summarization" begin
    bitstamp = Bitstamp()
    ethusd = load(bitstamp, "ETHUSD"; span=Date("2024-11-11"):Date("2024-11-12"), tf=Hour(6))
    @test size(ethusd) == (8, 6)
    @test ethusd.o[1] == 3187.4
    @test ethusd.h[2] == 3213.4
    @test ethusd.l[3] == 3143.7
    @test ethusd.c[4] == 3375.8
    @test isapprox(ethusd.v[5], 3388.77; atol=0.1)
end
