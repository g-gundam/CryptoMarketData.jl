using CryptoMarketData
using Documenter

DocMeta.setdocmeta!(CryptoMarketData, :DocTestSetup, :(using CryptoMarketData); recursive=true)

makedocs(;
    modules=[CryptoMarketData],
    authors="contributors",
    sitename="CryptoMarketData.jl",
    format=Documenter.HTML(;
        canonical="https://g-gundam.github.io/CryptoMarketData.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/g-gundam/CryptoMarketData.jl",
    devbranch="main",
)
