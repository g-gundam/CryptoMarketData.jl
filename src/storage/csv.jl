@kwdef struct CSVStorage <: AbstractStorage
    datadir::AbstractString
end

function prepare!(storage::CSVStorage, exchange::AbstractExchange, market::AbstractString)
    outdir = joinpath(storage.datadir, short_name(exchange), replace(market, "/" => ""))
    mkpath(outdir)
end

export CSVStorage
export prepare!
