#!/usr/bin/env julia
"""
Latency Distribution Analyzer — entry point.

Usage:
  julia src/main.jl serve              # start HTTP server
  julia src/main.jl analyze <file.csv> <service> [sla_ms]
"""

include("ingestion.jl");    using .Ingestion
include("distributions.jl"); using .DistributionFitter
include("percentiles.jl");  using .Percentiles
include("sla_breach.jl");   using .SLABreach
include("report.jl");       using .Report
include("server.jl");       using .Server

function cli(args)
    isempty(args) && (args = ["serve"])

    if args[1] == "serve"
        Server.serve()

    elseif args[1] == "analyze"
        length(args) < 3 && error("Usage: analyze <file.csv> <service> [sla_ms]")
        file    = args[2]
        service = args[3]
        sla     = length(args) >= 4 ? parse(Float64, args[4]) : 200.0

        df   = Ingestion.load_csv(file)
        sub  = Ingestion.filter_service(df, service)
        lat  = Float64.(sub.latency_ms)
        length(lat) < 2 && error("No data found for service: $service")

        name, dist, _ = DistributionFitter.fit_best(lat)
        pcts          = Percentiles.compute(lat)
        bp            = SLABreach.breach_probability(lat, sla)
        br            = SLABreach.current_breach_rate(lat, sla)
        summary       = DistributionFitter.dist_summary(name, dist)
        report        = Report.build(service, length(lat), summary, pcts, bp, br, sla)

        println(Report.to_markdown(report))
        println("\n--- JSON ---")
        using JSON3
        println(JSON3.write(report, indent=2))
    else
        error("Unknown command: $(args[1]). Use 'serve' or 'analyze'.")
    end
end

cli(ARGS)
