using Test

using Dates
using DelimitedFiles
using Logging
using Scratch
using SpaceIndices

const _INDICES = [
    :F10obs
    :F10obs_avg_center81
    :F10obs_avg_last81
    :F10adj
    :F10adj_avg_center81
    :F10adj_avg_last81
    :Ap
    :Ap_daily
    :Kp
    :Kp_daily
    :Cp
    :C9
    :ISN
    :BSRN
    :ND
    :DTC
    :S10
    :M10
    :Y10
    :S81a
    :M81a
    :Y81a
    :Hp30
    :Hp60
    :Ap30
    :Ap60
]

if isempty(VERSION.prerelease)
    # Add Mooncake and Enzyme to the project if not the nightly version. Adding them via the
    # Project.toml isn't working because it tries to compile them before reaching the
    # gating.

    using Pkg

    Pkg.add("DifferentiationInterface")
    
    Pkg.add("FiniteDiff")
    Pkg.add("ForwardDiff")
    Pkg.add("Mooncake")
    Pkg.add("PolyesterForwardDiff")
    Pkg.add("Zygote")

    Pkg.add("Aqua")
    Pkg.add("JET")
    Pkg.add("AllocCheck")

    
    if (VERSION.major == 1 && VERSION.minor < 12)
        Pkg.add("Enzyme")
        using DifferentiationInterface
        using Enzyme, FiniteDiff, ForwardDiff, Mooncake, PolyesterForwardDiff, Zygote

        const _BACKENDS = (
            ("ForwardDiff", AutoForwardDiff()),
            ("Enzyme", AutoEnzyme()),
            ("Mooncake", AutoMooncake(;config=nothing)),
            ("PolyesterForwardDiff", AutoPolyesterForwardDiff()),
        )
    else
        @warn "Enzyme is not fully supported on Julia 1.12, skipping tests"
        using DifferentiationInterface
        using FiniteDiff, ForwardDiff, Mooncake, PolyesterForwardDiff, Zygote
        const _BACKENDS = (
            ("ForwardDiff", AutoForwardDiff()),
            ("Mooncake", AutoMooncake(;config=nothing)),
            ("PolyesterForwardDiff", AutoPolyesterForwardDiff()),
        )
    end

    @testset "Automatic Differentiation" verbose = true begin
        include("./differentiability.jl")
    end

    using Aqua
    using JET
    using AllocCheck

    @testset "Performance" verbose = true begin
        include("./performance.jl")
    end
else
    @warn "Differentiation backends not guaranteed to work on julia-nightly, skipping tests"
    @warn "Performance tests not guaranteed to work on julia-nightly, skipping tests"
end

@testset "Initilization" verbose = true begin
    include("./initialization.jl")
end

@testset "Obtaining Space Indices" verbose = true begin
    include("./space_indices.jl")
end

@testset "API" verbose = true begin
    include("./api.jl")
end

@testset "Interpolations" verbose = true begin
    include("./interpolations.jl")
end
