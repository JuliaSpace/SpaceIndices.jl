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

@testset "Allocations Check" begin
    SpaceIndices.init()
    SpaceIndices.init(SpaceIndices.Dst)  # Dst excluded from default init

    for index in _INDICES
        @test length(check_allocs(space_index, (Val{index}, Float64))) == 0
    end

    SpaceIndices.destroy()
end