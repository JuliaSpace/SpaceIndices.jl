## Description #############################################################################
#
# Tests related to performance and memory allocations.
#
############################################################################################
@testset "Aqua.jl" begin
    Aqua.test_all(SpaceIndices; ambiguities=(recursive = false), deps_compat=(check_extras = false))
end

@testset "JET Testing" begin
    rep = JET.test_package(SpaceIndices; toplevel_logger=nothing, target_modules=(SpaceIndices,))
end

# Skip allocation tests on macOS with Julia 1.12+ due to AllocCheck detecting
# platform-specific runtime calls (jl_get_pgcstack_static) as allocations
if Sys.isapple() && (VERSION.major == 1 && VERSION.minor >= 12)
    @warn "Allocation tests skipped on macOS with Julia 1.12+ due to AllocCheck platform limitations"
else
    @testset "Allocations Check" begin
        SpaceIndices.init()

        for index in _INDICES
            @test length(check_allocs(space_index, (Val{index}, Float64))) == 0
        end

        SpaceIndices.destroy()
    end
end