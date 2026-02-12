## Description #############################################################################
#
# Tests for differentiation across the coordinate sets.
#
# Currently Supported & Tested:
#
#   Enzyme, ForwardDiff, FiniteDiff, Mooncake, PolyesterForwardDiff, Zygote
#
############################################################################################

@testset "Space Index Differentiability" begin
    SpaceIndices.init()
    SpaceIndices.init(SpaceIndices.Dst)  # Dst excluded from default init
    dt = DateTime(2020, 6, 19, 9, 30, 0)
    jd = datetime2julian(dt)

    # For hourly-cadence indices (Dst, DTC_Dst), FiniteDiff's default relative step
    # size (√ε × |jd| ≈ 0.04 days ≈ 1 hour) is comparable to the knot spacing,
    # causing the FD derivative to straddle multiple intervals. Use a manual central
    # difference with a step small enough to stay within one interpolation interval.
    _HOURLY_INDICES = (:Dst, :DTC_Dst, :DTC)

    for backend in _BACKENDS
        testset_name = "Space Indices " * string(backend[1])
        @testset "$testset_name"  begin
            for index in _INDICES
                fn = (x) -> reduce(vcat, space_index(Val(index), x))

                if index ∈ _HOURLY_INDICES
                    h_fd = 1e-6  # ~0.086 s — well within 1-hour knots
                    f_fd  = fn(jd)
                    df_fd = (fn(jd + h_fd) - fn(jd - h_fd)) / (2h_fd)
                else
                    f_fd, df_fd = value_and_derivative(fn, AutoFiniteDiff(), jd)
                end

                f_ad, df_ad = value_and_derivative(fn, backend[2], jd)

                @test f_fd == f_ad
                @test df_fd ≈ df_ad rtol=1e-2
            end
        end
    end

    # Zygote is separated as the tangent of a constant function is defined by "nothing"
    # instead of 0.0. This behavior is expected it should not affect downstream derivative
    # computations as in SatelliteToolboxAtmospheric.jl.
    #
    # See https://github.com/JuliaDiff/DifferentiationInterface.jl/pull/604

    @testset "Space Indcies Zygote"  begin
        for index in _INDICES
            fn = (x) -> reduce(vcat, space_index(Val(index), x))

            if index ∈ _HOURLY_INDICES
                h_fd = 1e-6
                f_fd  = fn(jd)
                df_fd = (fn(jd + h_fd) - fn(jd - h_fd)) / (2h_fd)
            else
                f_fd, df_fd = value_and_derivative(fn, AutoFiniteDiff(), jd)
            end

            try
                f_ad, df_ad = value_and_derivative(fn, AutoZygote(), jd)

                @test f_fd == f_ad
                @test df_fd ≈ df_ad rtol=1e-2
            catch err
                @test err isa MethodError
                @test startswith(
                    sprint(showerror, err),
                    "MethodError: no method matching iterate(::Nothing)",
                ) || startswith(
                    sprint(showerror, err),
                    "MethodError: reducing over an empty collection is not allowed; consider supplying `init` to the reducer",
                )
            end
        end
    end

    SpaceIndices.destroy()

end
