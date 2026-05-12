module SLABreach

using Distributions

"""
Estimate 24-hour SLA breach probability using a two-state Markov chain.
- State 0: healthy (latency < sla_ms)
- State 1: breaching (latency >= sla_ms)
Transition matrix estimated from the latency time series.
"""
function breach_probability(
    latencies::Vector{Float64},
    sla_ms::Float64;
    horizon_steps::Int=1440  # minutes in 24h
)::Float64
    n = length(latencies)
    states = Int[l >= sla_ms ? 1 : 0 for l in latencies]

    # Count transitions
    t00 = t01 = t10 = t11 = 0
    for i in 1:(n-1)
        if states[i] == 0 && states[i+1] == 0; t00 += 1
        elseif states[i] == 0 && states[i+1] == 1; t01 += 1
        elseif states[i] == 1 && states[i+1] == 0; t10 += 1
        else; t11 += 1
        end
    end

    # Transition probabilities with Laplace smoothing
    p01 = (t01 + 1) / (t00 + t01 + 2)
    p10 = (t10 + 1) / (t10 + t11 + 2)

    # Steady-state probability of breach
    steady_breach = p01 / (p01 + p10)

    # Probability of being in breach state after horizon_steps
    # using matrix power approximation via eigenvalue method
    # π(t) = π_steady + (π(0) - π_steady) * (1 - p01 - p10)^t
    pi0 = sum(states) / n  # initial breach fraction
    eigen_val = (1 - p01 - p10)^horizon_steps
    breach_prob = steady_breach + (pi0 - steady_breach) * eigen_val

    return clamp(breach_prob, 0.0, 1.0)
end

"""Current breach rate — fraction of samples above SLA threshold."""
function current_breach_rate(latencies::Vector{Float64}, sla_ms::Float64)::Float64
    return sum(l >= sla_ms for l in latencies) / length(latencies)
end

end
