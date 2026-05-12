FROM julia:1.10-bullseye

WORKDIR /app

COPY Project.toml Manifest.toml* ./
RUN julia -e 'using Pkg; Pkg.instantiate()'

COPY src/ ./src/
COPY data/ ./data/

ENV PORT=8080
ENV SLA_MS=200
ENV LATENCY_DATA=/app/data/sample_latency.csv

EXPOSE 8080

CMD ["julia", "src/main.jl", "serve"]
