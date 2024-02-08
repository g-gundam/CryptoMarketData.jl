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

function _filename_to_date(f)
    ds = replace(basename(f), ".csv" => "")
    m = match(r"(\d{4})-(\d{2})-(\d{2})", ds)
    Date(parse.(Int32, m.captures)...)
end

# date to index in span
function _d2i(d::Date, cfs)
    a = _filename_to_date(first(cfs))
    b = _filename_to_date(last(cfs))
    if a <= d <= b
        diff = d - a
        return diff.value + 1
    else
        missing
    end
end
