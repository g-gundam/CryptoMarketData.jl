function pui64(n)
    parse(UInt64, n)
end

function pf64(n)
    parse(Float64, n)
end

function last_csv(outdir)
    cfs = readdir(outdir)
    if length(cfs) == 0
        missing
    else
        cfs[end]
    end
end

