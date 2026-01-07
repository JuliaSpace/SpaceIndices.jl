## Description #############################################################################
#
#   Tests related with the functions to obtain the space indices.
#
############################################################################################

@testset "Celestrak" begin
    # == F10.7 Indices =====================================================================

    SpaceIndices.init(SpaceIndices.Celestrak)
    dt = DateTime(2020, 6, 19, 8)
    jd = datetime2julian(dt)

    r = space_index(Val(:F10adj), dt)
    @test r ≈ 71.1
    r = space_index(Val(:F10adj), jd)
    @test r ≈ 71.1

    r = space_index(Val(:F10adj_avg_center81), dt)
    @test r ≈ 71.4
    r = space_index(Val(:F10adj_avg_center81), jd)
    @test r ≈ 71.4

    r = space_index(Val(:F10adj_avg_last81), dt)
    @test r ≈ 70.8
    r = space_index(Val(:F10adj_avg_last81), jd)
    @test r ≈ 70.8

    r = space_index(Val(:F10obs), dt)
    @test r ≈ 68.8
    r = space_index(Val(:F10obs), jd)
    @test r ≈ 68.8

    r = space_index(Val(:F10obs_avg_center81), dt)
    @test r ≈ 69.3
    r = space_index(Val(:F10obs_avg_center81), jd)
    @test r ≈ 69.3

    r = space_index(Val(:F10obs_avg_last81), dt)
    @test r ≈ 69.6
    r = space_index(Val(:F10obs_avg_last81), jd)
    @test r ≈ 69.6

    dt = DateTime(2020, 6, 19, 7, 59, 59)
    jd = datetime2julian(dt)

    r = space_index(Val(:F10adj), dt)
    @test r ≈ 70.2
    r = space_index(Val(:F10adj), jd)
    @test r ≈ 70.2

    r = space_index(Val(:F10adj_avg_center81), dt)
    @test r ≈ 71.3
    r = space_index(Val(:F10adj_avg_center81), jd)
    @test r ≈ 71.3

    r = space_index(Val(:F10adj_avg_last81), dt)
    @test r ≈ 70.8
    r = space_index(Val(:F10adj_avg_last81), jd)
    @test r ≈ 70.8

    r = space_index(Val(:F10obs), dt)
    @test r ≈ 67.9
    r = space_index(Val(:F10obs), jd)
    @test r ≈ 67.9

    r = space_index(Val(:F10obs_avg_center81), dt)
    @test r ≈ 69.3
    r = space_index(Val(:F10obs_avg_center81), jd)
    @test r ≈ 69.3

    r = space_index(Val(:F10obs_avg_last81), dt)
    @test r ≈ 69.6
    r = space_index(Val(:F10obs_avg_last81), jd)
    @test r ≈ 69.6

    dt = DateTime(2000, 6, 8, 8)
    jd = datetime2julian(dt)

    r = space_index(Val(:F10adj), dt)
    @test r ≈ 179.9
    r = space_index(Val(:F10adj), jd)
    @test r ≈ 179.9

    r = space_index(Val(:F10adj_avg_center81), dt)
    @test r ≈ 193.1
    r = space_index(Val(:F10adj_avg_center81), jd)
    @test r ≈ 193.1

    r = space_index(Val(:F10adj_avg_last81), dt)
    @test r ≈ 190.2
    r = space_index(Val(:F10adj_avg_last81), jd)
    @test r ≈ 190.2

    r = space_index(Val(:F10obs), dt)
    @test r ≈ 174.6
    r = space_index(Val(:F10obs), jd)
    @test r ≈ 174.6

    r = space_index(Val(:F10obs_avg_center81), dt)
    @test r ≈ 187.8
    r = space_index(Val(:F10obs_avg_center81), jd)
    @test r ≈ 187.8

    r = space_index(Val(:F10obs_avg_last81), dt)
    @test r ≈ 187.8
    r = space_index(Val(:F10obs_avg_last81), jd)
    @test r ≈ 187.8

    dt = DateTime(2000, 6, 8, 7, 59, 59)
    jd = datetime2julian(dt)

    r = space_index(Val(:F10adj), dt)
    @test r ≈ 185.8
    r = space_index(Val(:F10adj), jd)
    @test r ≈ 185.8

    r = space_index(Val(:F10adj_avg_center81), dt)
    @test r ≈ 192.1
    r = space_index(Val(:F10adj_avg_center81), jd)
    @test r ≈ 192.1

    r = space_index(Val(:F10adj_avg_last81), dt)
    @test r ≈ 190.5
    r = space_index(Val(:F10adj_avg_last81), jd)
    @test r ≈ 190.5

    r = space_index(Val(:F10obs), dt)
    @test r ≈ 180.3
    r = space_index(Val(:F10obs), jd)
    @test r ≈ 180.3

    r = space_index(Val(:F10obs_avg_center81), dt)
    @test r ≈ 186.8
    r = space_index(Val(:F10obs_avg_center81), jd)
    @test r ≈ 186.8

    r = space_index(Val(:F10obs_avg_last81), dt)
    @test r ≈ 188.2
    r = space_index(Val(:F10obs_avg_last81), jd)
    @test r ≈ 188.2

    # == Kp & Ap ===========================================================================

    dt = DateTime(2020, 6, 19)
    jd = datetime2julian(dt)

    r = space_index(Val(:Kp), dt)
    @test r == (0.667, 1.000, 0.333, 1.000, 0.667, 0.667, 1.333, 1.667)
    r = space_index(Val(:Kp), jd)
    @test r == (0.667, 1.000, 0.333, 1.000, 0.667, 0.667, 1.333, 1.667)

    r = space_index(Val(:Kp_daily), dt)
    @test r ≈ 0.91675
    r = space_index(Val(:Kp_daily), jd)
    @test r ≈ 0.91675

    r = space_index(Val(:Ap), dt)
    @test r == (3, 4, 2, 4, 3, 3, 5, 6)
    r = space_index(Val(:Ap), jd)
    @test r == (3, 4, 2, 4, 3, 3, 5, 6)

    r = space_index(Val(:Ap_daily), dt)
    @test r == 4
    r = space_index(Val(:Ap_daily), jd)
    @test r == 4

    dt = DateTime(2000, 6, 8)
    jd = datetime2julian(dt)

    r = space_index(Val(:Kp), dt)
    @test r == (2.667, 3.667, 4.333, 6.333, 7.0, 6.333, 6.0, 5.0)
    r = space_index(Val(:Kp), jd)
    @test r == (2.667, 3.667, 4.333, 6.333, 7.0, 6.333, 6.0, 5.0)

    r = space_index(Val(:Kp_daily), dt)
    @test r ≈ 5.166625
    r = space_index(Val(:Kp_daily), jd)
    @test r ≈ 5.166625

    r = space_index(Val(:Ap), dt)
    @test r == (12, 22, 32, 94, 132, 94, 80, 48)
    r = space_index(Val(:Ap), jd)
    @test r == (12, 22, 32, 94, 132, 94, 80, 48)

    r = space_index(Val(:Ap_daily), dt)
    @test r == 64
    r = space_index(Val(:Ap_daily), jd)
    @test r == 64

    # == Other Indices =====================================================================

    dt = DateTime(2020, 6, 19)
    jd = datetime2julian(dt)

    r = space_index(Val(:BSRN), dt)
    @test r == 2549
    r = space_index(Val(:BSRN), jd)
    @test r == 2549

    r = space_index(Val(:ND), dt)
    @test r == 3
    r = space_index(Val(:ND), jd)
    @test r == 3

    r = space_index(Val(:C9), dt)
    @test r == 0.0
    r = space_index(Val(:C9), jd)
    @test r == 0.0

    r = space_index(Val(:Cp), dt)
    @test r == 0.1
    r = space_index(Val(:Cp), jd)
    @test r == 0.1

    r = space_index(Val(:ISN), dt)
    @test r == 0
    r = space_index(Val(:ISN), jd)
    @test r == 0

    r = space_index(Val(:ND), dt)
    @test r == 3
    r = space_index(Val(:ND), jd)
    @test r == 3

    dt = DateTime(2000, 6, 8)
    jd = datetime2julian(dt)

    r = space_index(Val(:BSRN), dt)
    @test r == 2278
    r = space_index(Val(:BSRN), jd)
    @test r == 2278

    r = space_index(Val(:ND), dt)
    @test r == 4
    r = space_index(Val(:ND), jd)
    @test r == 4

    r = space_index(Val(:C9), dt)
    @test r == 7.0
    r = space_index(Val(:C9), jd)
    @test r == 7.0

    r = space_index(Val(:Cp), dt)
    @test r == 1.7
    r = space_index(Val(:Cp), jd)
    @test r == 1.7

    r = space_index(Val(:ISN), dt)
    @test r == 181
    r = space_index(Val(:ISN), jd)
    @test r == 181

    r = space_index(Val(:ND), dt)
    @test r == 4
    r = space_index(Val(:ND), jd)
    @test r == 4

    SpaceIndices.destroy()
end

@testset "Celestrak [ERRORS]" begin
    SpaceIndices.init(SpaceIndices.Celestrak)

    # The data starts on 1932-01-01.
    dt = DateTime(1931, 12, 31)
    jd = datetime2julian(dt)

    @test_throws ArgumentError space_index(Val(:F10obs), dt)
    @test_throws ArgumentError space_index(Val(:F10obs), jd)
    @test_throws ArgumentError space_index(Val(:F10adj), dt)
    @test_throws ArgumentError space_index(Val(:F10adj), jd)

    @test_throws ArgumentError space_index(Val(:Kp), dt)
    @test_throws ArgumentError space_index(Val(:Kp), jd)

    @test_throws ArgumentError space_index(Val(:Kp_daily), dt)
    @test_throws ArgumentError space_index(Val(:Kp_daily), jd)

    @test_throws ArgumentError space_index(Val(:Ap), dt)
    @test_throws ArgumentError space_index(Val(:Ap), jd)

    @test_throws ArgumentError space_index(Val(:Ap_daily), dt)
    @test_throws ArgumentError space_index(Val(:Ap_daily), jd)
end

@testset "JB2008" begin
    SpaceIndices.init(SpaceIndices.JB2008)
    dt = DateTime(2020, 6, 19, 9, 30, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:DTC), dt)
    @test r ≈ 37
    r = space_index(Val(:DTC), jd)
    @test r ≈ 37

    r = space_index(Val(:S10), dt)
    @test r ≈ 53.6
    r = space_index(Val(:S10), jd)
    @test r ≈ 53.6

    r = space_index(Val(:S81a), dt)
    @test r ≈ 54.1
    r = space_index(Val(:S81a), jd)
    @test r ≈ 54.1

    r = space_index(Val(:M10), dt)
    @test r ≈ 72.8
    r = space_index(Val(:M10), jd)
    @test r ≈ 72.8

    r = space_index(Val(:M81a), dt)
    @test r ≈ 74.0
    r = space_index(Val(:M81a), jd)
    @test r ≈ 74.0

    r = space_index(Val(:Y10), dt)
    @test r ≈ 58.2
    r = space_index(Val(:Y10), jd)
    @test r ≈ 58.2

    r = space_index(Val(:Y81a), dt)
    @test r ≈ 62.7
    r = space_index(Val(:Y81a), jd)
    @test r ≈ 62.7
end

@testset "JB2008 [ERRORS]" begin
    # The data starts on 1997-01-01.
    dt = DateTime(1996, 12, 31)
    jd = datetime2julian(dt)

    @test_throws ArgumentError space_index(Val(:DTC),  dt)
    @test_throws ArgumentError space_index(Val(:DTC),  jd)

    @test_throws ArgumentError space_index(Val(:S10),  dt)
    @test_throws ArgumentError space_index(Val(:S10),  jd)

    @test_throws ArgumentError space_index(Val(:S81a), dt)
    @test_throws ArgumentError space_index(Val(:S81a), jd)

    @test_throws ArgumentError space_index(Val(:M10),  dt)
    @test_throws ArgumentError space_index(Val(:M10),  jd)

    @test_throws ArgumentError space_index(Val(:M81a), dt)
    @test_throws ArgumentError space_index(Val(:M81a), jd)

    @test_throws ArgumentError space_index(Val(:Y10),  dt)
    @test_throws ArgumentError space_index(Val(:Y10),  jd)

    @test_throws ArgumentError space_index(Val(:Y81a), dt)
    @test_throws ArgumentError space_index(Val(:Y81a), jd)
end

@testset "Hpo" begin
    SpaceIndices.init(SpaceIndices.Hpo)

    # Test Hp30 and ap30 indices
    # Using a date that should be in the historical data
    dt = DateTime(2020, 6, 10, 0, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:Hp30), dt)
    @test r isa NTuple{48, Float64}
    expected_hpo30 = (1.667, 2.0, 2.0, 1.667, 2.0, 2.0, 2.0, 2.333, 2.667, 2.0)
    @test r[1:10] == expected_hpo30
    r_jd = space_index(Val(:Hp30), jd)
    @test r_jd == r

    r = space_index(Val(:Ap30), dt)
    @test r isa NTuple{48, Float64}
    expected_ap30 = (6, 7, 7, 6, 7, 7, 7, 9, 12, 7)
    @test r[1:10] == expected_ap30
    r_jd = space_index(Val(:Ap30), jd)
    @test r_jd == r

    # Test Hp60 and ap60 indices
    r = space_index(Val(:Hp60), dt)
    expected_hpo60 = (1.667, 1.667, 2.0, 2.333, 2.333, 2.667, 2.667, 2.333, 2.333, 3.333, 1.667, 1.667, 1.333, 1.0, 1.0, 1.333, .667, 1.0, 1.667, .667, .667, 1.333, .667, 2.0)
    @test r isa NTuple{24, Float64}
    @test r == expected_hpo60
    r_jd = space_index(Val(:Hp60), jd)
    @test r_jd == r

    r = space_index(Val(:Ap60), dt)
    @test r isa NTuple{24, Float64}
    expected_ap60 = (6, 6, 7, 9, 9, 12, 12, 9, 9, 18, 6, 6, 5, 4, 4, 5, 3, 4, 6, 3, 3, 5, 3, 7)
    @test all(x -> x >= 0.0 || isnan(x), r)
    r_jd = space_index(Val(:Ap60), jd)
    @test r_jd == r

    SpaceIndices.destroy()
end

@testset "Hpo [ERRORS]" begin
    SpaceIndices.init(SpaceIndices.Hpo)

    # Test with a date before the data starts (before 1985)
    dt = DateTime(1984, 12, 31)
    jd = datetime2julian(dt)

    @test_throws ArgumentError space_index(Val(:Hp30), dt)
    @test_throws ArgumentError space_index(Val(:Hp30), jd)

    @test_throws ArgumentError space_index(Val(:Ap30), dt)
    @test_throws ArgumentError space_index(Val(:Ap30), jd)

    @test_throws ArgumentError space_index(Val(:Hp60), dt)
    @test_throws ArgumentError space_index(Val(:Hp60), jd)

    @test_throws ArgumentError space_index(Val(:Ap60), dt)
    @test_throws ArgumentError space_index(Val(:Ap60), jd)

    SpaceIndices.destroy()
end


@testset "SpaceIndexSeries" begin
    SpaceIndices.init(SpaceIndices.Celestrak)

    t0 = DateTime(2020, 6, 19)
    t1 = DateTime(2020, 6, 22)

    # Test scalar index (F10obs)
    series = space_index(:F10obs, t0, t1)
    @test series isa AbstractArray
    @test length(series) == 4
    @test series.dates == t0:Day(1):t1
    @test series[1] == space_index(:F10obs, t0)
    @test series[end] == space_index(:F10obs, t1)

    # Test tuple index (Kp) - should be flattened
    series = space_index(:Kp, t0, t1)
    @test series isa SpaceIndexSeries{Float64}
    @test length(series) == 32  # 4 days × 8 values per day
    @test step(series.dates) == Hour(3)
    @test series[1:8] == collect(space_index(:Kp, t0))
end
