module Server

using HTTP, JSON3
include("ingestion.jl");    using .Ingestion
include("distributions.jl"); using .DistributionFitter
include("percentiles.jl");  using .Percentiles
include("sla_breach.jl");   using .SLABreach
include("report.jl");       using .Report

const DATA_PATH = get(ENV, "LATENCY_DATA", joinpath(@__DIR__, "../data/sample_latency.csv"))
const SLA_MS    = parse(Float64, get(ENV, "SLA_MS", "200"))
const PORT      = parse(Int,     get(ENV, "PORT",   "8080"))

function handle_analyze(req::HTTP.Request)
    body     = JSON3.read(String(req.body))
    service  = get(body, :service, "checkout")
    window   = get(body, :window_minutes, 0)
    sla      = get(body, :sla_ms, SLA_MS)

    df       = load_csv(DATA_PATH)
    sub      = filter_service(df, service; window_minutes=window)
    lat      = Float64.(sub.latency_ms)
    length(lat) < 2 && return HTTP.Response(400, "insufficient data for service: $service")

    name, dist, _ = fit_best(lat)
    pcts          = compute(lat)
    bp            = breach_probability(lat, sla)
    br            = current_breach_rate(lat, sla)
    summary       = dist_summary(name, dist)
    report        = build(service, length(lat), summary, pcts, bp, br, sla)

    return HTTP.Response(200,
        ["Content-Type" => "application/json"],
        JSON3.write(report)
    )
end

function handle_health(req::HTTP.Request)
    return HTTP.Response(200, JSON3.write(Dict("status" => "ok", "version" => "1.0.0")))
end

function serve()
    router = HTTP.Router()
    HTTP.register!(router, "POST", "/analyze", handle_analyze)
    HTTP.register!(router, "GET",  "/health",  handle_health)
    @info "Latency Distribution Analyzer listening on port $PORT"
    HTTP.serve(router, "0.0.0.0", PORT)
end

end
