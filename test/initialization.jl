## Description #############################################################################
#
# Tests related with the initialization of space indices.
#
############################################################################################

@testset "Functions init_space_index_sets and init_space_index_set" begin
    # Initialize all space indices (Dst is excluded by default).
    SpaceIndices.init()

    # Test if the structures were initialized.
    @test SpaceIndices._OPDATA_JB2008.data    isa SpaceIndices.JB2008
    @test SpaceIndices._OPDATA_CELESTRAK.data isa SpaceIndices.Celestrak
    @test SpaceIndices._OPDATA_HPO.data       isa SpaceIndices.Hpo
    @test SpaceIndices._OPDATA_DST.data       isa Nothing  # Dst excluded by default

    # Destroy everything to test the individual initialization.
    SpaceIndices.destroy()

    SpaceIndices.init(SpaceIndices.JB2008)
    @test SpaceIndices._OPDATA_JB2008.data    isa SpaceIndices.JB2008
    @test SpaceIndices._OPDATA_CELESTRAK.data isa Nothing
    @test SpaceIndices._OPDATA_HPO.data       isa Nothing
    @test SpaceIndices._OPDATA_DST.data       isa Nothing
    SpaceIndices.destroy()

    SpaceIndices.init(SpaceIndices.Celestrak)
    @test SpaceIndices._OPDATA_JB2008.data    isa Nothing
    @test SpaceIndices._OPDATA_CELESTRAK.data isa SpaceIndices.Celestrak
    @test SpaceIndices._OPDATA_HPO.data       isa Nothing
    @test SpaceIndices._OPDATA_DST.data       isa Nothing
    SpaceIndices.destroy()

    SpaceIndices.init(SpaceIndices.Hpo)
    @test SpaceIndices._OPDATA_JB2008.data    isa Nothing
    @test SpaceIndices._OPDATA_CELESTRAK.data isa Nothing
    @test SpaceIndices._OPDATA_HPO.data       isa SpaceIndices.Hpo
    @test SpaceIndices._OPDATA_DST.data       isa Nothing
    SpaceIndices.destroy()

    # == Dst individual init (requires an ap source) =======================================

    # Dst with Celestrak ap (default).
    SpaceIndices.init(SpaceIndices.Celestrak)
    SpaceIndices.init(SpaceIndices.Dst)
    @test SpaceIndices._OPDATA_DST.data       isa SpaceIndices.Dst
    @test SpaceIndices._OPDATA_CELESTRAK.data isa SpaceIndices.Celestrak
    SpaceIndices.destroy()

    # Dst with Hpo ap.
    SpaceIndices.init(SpaceIndices.Hpo)
    SpaceIndices.init(SpaceIndices.Dst; ap_source = :hpo)
    @test SpaceIndices._OPDATA_DST.data isa SpaceIndices.Dst
    @test SpaceIndices._OPDATA_HPO.data isa SpaceIndices.Hpo
    SpaceIndices.destroy()

    # Invalid ap_source should throw.
    SpaceIndices.init(SpaceIndices.Celestrak)
    @test_throws ArgumentError SpaceIndices.init(SpaceIndices.Dst; ap_source = :invalid)
    SpaceIndices.destroy()

    # == Blocklist =========================================================================

    SpaceIndices.init(; blocklist = [SpaceIndices.Celestrak])
    @test SpaceIndices._OPDATA_JB2008.data    isa SpaceIndices.JB2008
    @test SpaceIndices._OPDATA_CELESTRAK.data isa Nothing
    @test SpaceIndices._OPDATA_HPO.data       isa SpaceIndices.Hpo
    @test SpaceIndices._OPDATA_DST.data       isa Nothing
    SpaceIndices.destroy()

    SpaceIndices.init(; blocklist = [SpaceIndices.Hpo])
    @test SpaceIndices._OPDATA_JB2008.data    isa SpaceIndices.JB2008
    @test SpaceIndices._OPDATA_CELESTRAK.data isa SpaceIndices.Celestrak
    @test SpaceIndices._OPDATA_HPO.data       isa Nothing
    @test SpaceIndices._OPDATA_DST.data       isa Nothing
    SpaceIndices.destroy()

    # Empty blocklist still skips Dst (auto_init is false); all others are initialized.
    SpaceIndices.init(; blocklist = [])
    @test SpaceIndices._OPDATA_JB2008.data    isa SpaceIndices.JB2008
    @test SpaceIndices._OPDATA_CELESTRAK.data isa SpaceIndices.Celestrak
    @test SpaceIndices._OPDATA_HPO.data       isa SpaceIndices.Hpo
    @test SpaceIndices._OPDATA_DST.data       isa Nothing
    SpaceIndices.destroy()

end

@testset "Initialize Indices Using Local Files" begin
    SpaceIndices.init(SpaceIndices.Celestrak; filepaths = ["./SW-All.csv"])
    @test SpaceIndices._OPDATA_CELESTRAK.data isa SpaceIndices.Celestrak

    # Make sure we loaded the local file by testing a data outside the available interval.
    @test_throws Exception space_index(Val(:Kp), DateTime("2024-05-31T00:00:00"))

    # Test some data from the local file.
    kp = space_index(Val(:Kp), DateTime("2024-06-19T10:00:00"))
    @test kp[1] == 2.333
    @test kp[2] == 2.333
    @test kp[3] == 2.333
    @test kp[4] == 2.333
    @test kp[5] == 2.333
    @test kp[6] == 2.333
    @test kp[7] == 2.333
    @test kp[2] == 2.333

    f10obs = space_index(Val(:F10obs), DateTime("2024-06-19T10:00:00"))
    @test f10obs == 155.0
end

@testset "Errors Related To Unitialized Space Indices" begin
    SpaceIndices.destroy()
    dt = DateTime(1900, 1, 1)

    @test_throws Exception space_index(Val(:BSRN),                dt)
    @test_throws Exception space_index(Val(:ND),                  dt)
    @test_throws Exception space_index(Val(:C9),                  dt)
    @test_throws Exception space_index(Val(:Cp),                  dt)
    @test_throws Exception space_index(Val(:ISN),                 dt)
    @test_throws Exception space_index(Val(:ND),                  dt)
    @test_throws Exception space_index(Val(:Kp),                  dt)
    @test_throws Exception space_index(Val(:Kp_daily),            dt)
    @test_throws Exception space_index(Val(:Ap),                  dt)
    @test_throws Exception space_index(Val(:Ap_daily),            dt)
    @test_throws Exception space_index(Val(:F10obj),              dt)
    @test_throws Exception space_index(Val(:F10obj_avg_center81), dt)
    @test_throws Exception space_index(Val(:F10obj_avg_last81),   dt)
    @test_throws Exception space_index(Val(:F10adj),              dt)
    @test_throws Exception space_index(Val(:F10adj_avg_center81), dt)
    @test_throws Exception space_index(Val(:F10adj_avg_last81),   dt)

    @test_throws Exception space_index(Val(:S10),  dt)
    @test_throws Exception space_index(Val(:S81a), dt)
    @test_throws Exception space_index(Val(:M10),  dt)
    @test_throws Exception space_index(Val(:M81a), dt)
    @test_throws Exception space_index(Val(:Y10),  dt)
    @test_throws Exception space_index(Val(:Y81a), dt)

    @test_throws Exception space_index(Val(:Hp30), dt)
    @test_throws Exception space_index(Val(:Ap30), dt)
    @test_throws Exception space_index(Val(:Hp60), dt)
    @test_throws Exception space_index(Val(:Ap60), dt)

    @test_throws Exception space_index(Val(:Dst),     dt)
    @test_throws Exception space_index(Val(:DTC_Dst), dt)
end

@testset "Errors Related To Space Index Set Initialization" begin
    @test_throws Exception SpaceIndices.init(
        SpaceIndices.Celestrak;
        filepaths = ["./SW-All.csv", "./SW-All.csv"]
    )
end
