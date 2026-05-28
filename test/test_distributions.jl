using Test

include("../src/distributions.jl")
include("../src/percentiles.jl")
include("../src/sla_breach.jl")

# The src modules don't `export` their public API, so `using .M` does not
# put any names in scope — we reference everything through the module
# namespace explicitly.
using .DistributionFitter: fit_best, dist_summary
using .Percentiles: compute
using .SLABreach: breach_probability, current_breach_rate
using Distributions

@testset "DistributionFitter" begin
    # Generate synthetic LogNormal data
    rng_data = rand(LogNormal(4.0, 0.5), 500)

    @testset "fit_best returns a known distribution" begin
        name, dist, aic_val = fit_best(rng_data)
        @test name isa String
        @test isa(dist, UnivariateDistribution)
        # AIC = 2k - 2*ll; ll is unbounded above, so AIC can be any real
        # number. Just confirm it's finite.
        @test isfinite(aic_val)
    end

    @testset "dist_summary keys" begin
        name, dist, _ = fit_best(rng_data)
        s = dist_summary(name, dist)
        @test haskey(s, "name")
        @test haskey(s, "mean")
        @test haskey(s, "std")
    end
end

@testset "Percentiles" begin
    data = Float64.(50:150)  # uniform 50–150
    pcts = compute(data; n_boot=100)
    @test haskey(pcts, "p500")  # p50
    @test pcts["p500"]["value"] ≈ 100.0 atol=5.0
    @test pcts["p990"]["value"] ≈ 148.0 atol=5.0
end

@testset "SLABreach" begin
    # All below threshold → near 0 breach prob
    safe = fill(50.0, 200)
    @test breach_probability(safe, 200.0) < 0.15

    # All above threshold → high breach prob
    unsafe = fill(300.0, 200)
    @test breach_probability(unsafe, 200.0) > 0.5

    @test current_breach_rate(safe, 200.0) == 0.0
    @test current_breach_rate(unsafe, 200.0) == 1.0
end
