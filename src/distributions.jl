module DistributionFitter

using Distributions, StatsBase, Optim

const CANDIDATES = [
    ("LogNormal", LogNormal),
    ("Normal",    Normal),
    ("Gamma",     Gamma),
    ("Weibull",   Weibull),
    ("Exponential", Exponential),
]

"""Fit all candidate distributions to latency_ms vector, return best by AIC."""
function fit_best(latencies::Vector{Float64})
    best_name = "LogNormal"
    best_dist = fit(LogNormal, latencies)
    best_aic  = aic(best_dist, latencies)

    for (name, D) in CANDIDATES
        try
            d = fit(D, latencies)
            a = aic(d, latencies)
            if a < best_aic
                best_aic  = a
                best_dist = d
                best_name = name
            end
        catch
            continue
        end
    end
    return best_name, best_dist, best_aic
end

function aic(d::UnivariateDistribution, data::Vector{Float64})
    k = length(params(d))
    ll = sum(logpdf.(d, data))
    return 2k - 2ll
end

"""Return mean, std, and param dict for a fitted distribution."""
function dist_summary(name::String, d::UnivariateDistribution)
    return Dict(
        "name"   => name,
        "mean"   => mean(d),
        "std"    => std(d),
        "params" => string(params(d)),
    )
end

end
