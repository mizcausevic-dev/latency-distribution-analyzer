module Report

using JSON3, Dates

"""Assemble the full analysis report as a Dict for JSON serialization."""
function build(
    service::String,
    n::Int,
    dist_summary::Dict,
    percentiles::Dict,
    breach_prob::Float64,
    breach_rate_current::Float64,
    sla_ms::Float64,
)
    return Dict(
        "service"              => service,
        "sample_count"         => n,
        "generated_at"         => string(now()),
        "sla_threshold_ms"     => sla_ms,
        "best_fit_distribution" => dist_summary,
        "percentiles"          => percentiles,
        "breach_probability_24h" => round(breach_prob, digits=4),
        "current_breach_rate"  => round(breach_rate_current, digits=4),
        "health"               => breach_prob < 0.05 ? "green" :
                                   breach_prob < 0.15 ? "yellow" : "red",
    )
end

function to_markdown(r::Dict)::String
    lines = String[]
    push!(lines, "# Latency Distribution Report — $(r["service"])")
    push!(lines, "")
    push!(lines, "**Generated:** $(r["generated_at"])  ")
    push!(lines, "**Samples:** $(r["sample_count"])  ")
    push!(lines, "**SLA Threshold:** $(r["sla_threshold_ms"]) ms  ")
    push!(lines, "**Health:** $(uppercase(r["health"]))")
    push!(lines, "")
    push!(lines, "## Best-Fit Distribution")
    d = r["best_fit_distribution"]
    push!(lines, "- Model: **$(d[\"name\"])**")
    push!(lines, "- Mean: $(round(d[\"mean\"], digits=2)) ms")
    push!(lines, "- Std Dev: $(round(d[\"std\"], digits=2)) ms")
    push!(lines, "")
    push!(lines, "## Percentiles (with 95% CI)")
    push!(lines, "| Percentile | Value (ms) | CI Low | CI High |")
    push!(lines, "|---|---|---|---|")
    for (label, v) in r["percentiles"]
        push!(lines, "| $(label) | $(v[\"value\"]) | $(v[\"ci_lo\"]) | $(v[\"ci_hi\"]) |")
    end
    push!(lines, "")
    push!(lines, "## SLA Breach Forecast")
    push!(lines, "- 24h breach probability: **$(r[\"breach_probability_24h\"] * 100)%**")
    push!(lines, "- Current breach rate: **$(r[\"current_breach_rate\"] * 100)%**")
    return join(lines, "\n")
end

end
