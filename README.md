# latency-distribution-analyzer

> **Julia · HTTP.jl · Distributions.jl · StatsBase**  
> Platform Reliability | SRE | Observability

Statistical latency analysis engine for production services. Ingests raw latency logs, fits optimal probability distributions via MLE, computes P50–P99.9 with bootstrap confidence intervals, and forecasts 24-hour SLA breach probability using a Markov chain model.

---

## Why Julia?

Julia provides C-level numerical performance with Python-level ergonomics. For large-scale latency log processing, MLE distribution fitting, and Monte Carlo percentile bootstrapping, it outperforms Python/Pandas by 10–100× on hot numerical paths — without JVM overhead.

---

## Features

- **Distribution fitting** — Evaluates Normal, LogNormal, Gamma, Weibull, Exponential; selects best by AIC
- **Percentile bands** — P50, P75, P90, P95, P99, P99.9 with 95% bootstrap confidence intervals
- **SLA breach forecasting** — Two-state Markov chain projects 24h breach probability
- **REST API** — `POST /analyze`, `GET /health` via HTTP.jl
- **CLI mode** — `julia src/main.jl analyze <file.csv> <service> [sla_ms]`
- **Dockerized** — single `docker run` to serve

---

## Quickstart

### Docker
```bash
docker build -t latency-analyzer .
docker run -p 8080:8080 latency-analyzer
```

### Local
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia src/main.jl serve
```

### CLI one-shot analysis
```bash
julia src/main.jl analyze data/sample_latency.csv checkout 200
```

---

## API

### `POST /analyze`
```json
{
  "service": "checkout",
  "window_minutes": 60,
  "sla_ms": 200
}
```

**Response:**
```json
{
  "service": "checkout",
  "sample_count": 1200,
  "sla_threshold_ms": 200,
  "best_fit_distribution": {
    "name": "LogNormal",
    "mean": 84.3,
    "std": 42.1,
    "params": "(4.28, 0.47)"
  },
  "percentiles": {
    "p500":  { "value": 72.4,  "ci_lo": 70.1,  "ci_hi": 74.8  },
    "p990":  { "value": 198.3, "ci_lo": 185.0, "ci_hi": 212.7 },
    "p999":  { "value": 341.2, "ci_lo": 310.4, "ci_hi": 378.9 }
  },
  "breach_probability_24h": 0.0312,
  "current_breach_rate": 0.028,
  "health": "green"
}
```

### `GET /health`
```json
{ "status": "ok", "version": "1.0.0" }
```

---

## Architecture

```
CSV / Log Input
      │
      ▼
  Ingestion.jl  ──→  filter by service + time window
      │
      ▼
  DistributionFitter.jl  ──→  MLE fit (5 candidate distributions, AIC selection)
      │
      ├──→  Percentiles.jl  ──→  P50–P99.9 + bootstrap CI
      │
      └──→  SLABreach.jl    ──→  Markov chain 24h breach probability
                │
                ▼
           Report.jl  ──→  JSON + Markdown
                │
                ▼
           Server.jl  ──→  HTTP REST surface
```

---

## Input Format

`data/sample_latency.csv`:
```csv
timestamp,service,latency_ms
2026-05-01T00:00:01,checkout,45.2
2026-05-01T00:00:02,checkout,52.7
```

| Column | Type | Description |
|---|---|---|
| `timestamp` | ISO 8601 | Request timestamp |
| `service` | String | Service identifier |
| `latency_ms` | Float | End-to-end latency in milliseconds |

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | HTTP listen port |
| `SLA_MS` | `200` | SLA threshold in milliseconds |
| `LATENCY_DATA` | `data/sample_latency.csv` | Path to latency log CSV |

---

## Testing
```bash
julia --project=. test/test_distributions.jl
```

---

## Stack

| Package | Purpose |
|---|---|
| `Distributions.jl` | MLE distribution fitting |
| `StatsBase.jl` | Weighted percentiles, resampling |
| `HTTP.jl` | Lightweight REST server |
| `CSV.jl` + `DataFrames.jl` | Log ingestion |
| `JSON3.jl` | Request/response serialization |
| `Optim.jl` | Numerical optimization for MLE |

---

## Related Projects

| Repo | Relationship |
|---|---|
| [`latency-budget-enforcer`](https://github.com/mizcausevic-dev/latency-budget-enforcer) | Upstream: latency budget policy enforcement (Go) |
| [`agent-canary`](https://github.com/mizcausevic-dev/agent-canary) | Sibling: progressive rollout driven by latency signals |
| [`kinetic-flightdeck`](https://github.com/mizcausevic-dev/kinetic-flightdeck) | Consumer: operator surface for platform health |

---

## License

AGPL-3.0 © [Miz Causevic](https://kineticgain.com)
