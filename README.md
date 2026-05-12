# latency-distribution-analyzer
Julia backend for latency distribution fitting, SLA breach probability forecasting, and percentile band analysis. Ingests service log exports, fits LogNormal/Weibull via MLE, computes P50–P99.9 with confidence intervals, and projects 24h SLA breach probability using Markov chains. HTTP.jl REST surface.
