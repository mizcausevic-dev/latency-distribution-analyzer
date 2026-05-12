module Ingestion

using CSV, DataFrames

"""Load latency CSV with columns: timestamp, service, latency_ms"""
function load_csv(path::String)::DataFrame
    df = CSV.read(path, DataFrame)
    rename!(df, lowercase.(names(df)))
    dropmissing!(df, :latency_ms)
    filter!(r -> r.latency_ms > 0, df)
    return df
end

"""Filter dataframe by service name and optional time window (minutes)"""
function filter_service(df::DataFrame, service::String; window_minutes::Int=0)::DataFrame
    sub = filter(r -> r.service == service, df)
    if window_minutes > 0 && "timestamp" in names(sub)
        cutoff = maximum(sub.timestamp) - Dates.Minute(window_minutes)
        sub = filter(r -> r.timestamp >= cutoff, sub)
    end
    return sub
end

end
