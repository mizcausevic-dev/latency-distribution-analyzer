module Percentiles

using StatsBase, Distributions

const PCTILES = [0.50, 0.75, 0.90, 0.95, 0.99, 0.999]

"""Empirical percentiles with 95% bootstrap CI (n=1000 resamples)."""
function compute(latencies::Vector{Float64}; n_boot::Int=1000)
    n = length(latencies)
    results = Dict{String, Any}()

    for p in PCTILES
        label = "p$(round(Int, p * 1000))"
        emp = quantile(latencies, p)

        boots = [quantile(sample(latencies, n; replace=true), p) for _ in 1:n_boot]
        ci_lo = quantile(boots, 0.025)
        ci_hi = quantile(boots, 0.975)

        results[label] = Dict(
            "value" => round(emp, digits=2),
            "ci_lo" => round(ci_lo, digits=2),
            "ci_hi" => round(ci_hi, digits=2),
        )
    end
    return results
end

end
