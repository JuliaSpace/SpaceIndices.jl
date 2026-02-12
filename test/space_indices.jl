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

@testset "Dst" begin
    SpaceIndices.init(SpaceIndices.Celestrak)
    SpaceIndices.init(SpaceIndices.Dst)

    # == Dst Index (hourly values) =========================================================

    # Quiet period — 2020-06-19 12:00 UT.
    dt = DateTime(2020, 6, 19, 12, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:Dst), dt)
    @test r ≈ 9.0
    r = space_index(Val(:Dst), jd)
    @test r ≈ 9.0

    # Halloween storm 2003 — peak around 2003-10-30 22:00 UT.
    dt = DateTime(2003, 10, 30, 22, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:Dst), dt)
    @test r ≈ -383.0
    r = space_index(Val(:Dst), jd)
    @test r ≈ -383.0

    # Halloween storm — one hour later, verify distinct value.
    dt = DateTime(2003, 10, 30, 23, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:Dst), dt)
    @test r ≈ -371.0
    r = space_index(Val(:Dst), jd)
    @test r ≈ -371.0

    # Linear interpolation test — halfway between 22:00 (-383) and 23:00 (-371).
    dt = DateTime(2003, 10, 30, 22, 30, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:Dst), dt)
    @test r ≈ -377.0
    r = space_index(Val(:Dst), jd)
    @test r ≈ -377.0

    # St. Patrick's Day storm 2015-03-17 22:00 UT.
    dt = DateTime(2015, 3, 17, 22, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:Dst), dt)
    @test r ≈ -234.0
    r = space_index(Val(:Dst), jd)
    @test r ≈ -234.0

    # Early data — 1957-09-13 12:00 UT (major storm during IGY).
    dt = DateTime(1957, 9, 13, 12, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:Dst), dt)
    @test r ≈ -330.0
    r = space_index(Val(:Dst), jd)
    @test r ≈ -330.0

    # == DTC_Dst (dTc derived from Dst) ====================================================

    # Quiet period — dTc should be small and positive (Jacchia 1970 ap baseline with
    # ap capped at 50, analytical formula: dTc = ap + 100*(1 - exp(-0.08*ap))).
    dt = DateTime(2020, 6, 19, 12, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:DTC_Dst), dt)
    @test 0.0 < r < 80.0
    r = space_index(Val(:DTC_Dst), jd)
    @test 0.0 < r < 80.0

    # Halloween storm — dTc should be large and positive near the storm peak.
    # The main phase near Dst minimum (~-383 nT at 22:00 UT) produces large dTc.
    dt = DateTime(2003, 10, 30, 22, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:DTC_Dst), dt)
    @test r > 100.0
    r = space_index(Val(:DTC_Dst), jd)
    @test r > 100.0

    # St. Patrick's Day storm — dTc should be positive during the storm.
    dt = DateTime(2015, 3, 17, 22, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:DTC_Dst), dt)
    @test r > 100.0
    r = space_index(Val(:DTC_Dst), jd)
    @test r > 100.0

    # dTc during storm recovery: may be slightly negative during main phase (no floor),
    # but should be non-negative during recovery/late recovery and quiet periods.
    # At 2003-10-30 00:00 UT we are in a storm region.
    dt = DateTime(2003, 10, 30, 0, 0, 0)
    jd = datetime2julian(dt)

    r = space_index(Val(:DTC_Dst), dt)
    @test r >= -10.0

    SpaceIndices.destroy()
end

@testset "DTC_Dst vs JB2008 DTC Validation" begin
    # Cross-validate the Dst-derived dTc against the pre-computed DTCFILE.TXT values from
    # JB2008 during both storm and calm conditions. Celestrak must be initialized first to
    # provide the Jacchia 1970 ap-based baseline.
    #
    # Both implementations now use the same Jacchia 1970 analytical formula and equation-
    # level behavior (DTCMAKEDR reference). Residuals arise from:
    #   - ap data source differences (Celestrak SW-All.csv vs SET SOLRESAP)
    #   - Storm detection heuristic differences (pre-scan vs per-timestep)

    SpaceIndices.init(SpaceIndices.Celestrak)
    SpaceIndices.init(SpaceIndices.Dst)
    SpaceIndices.init(SpaceIndices.JB2008)

    # == Storm: St. Patrick's Day 2015 (clean, single storm) ===============================
    # Main phase (17:00-22:00 UT): both algorithms use the same Burke et al. equations.
    # Residuals ≤ 10 K from storm onset detection differences.

    for h in [17, 18, 19, 20, 21, 22]
        jd = datetime2julian(DateTime(2015, 3, 17, h, 0, 0))
        dtc_jb  = space_index(Val(:DTC),     jd)
        dtc_dst = space_index(Val(:DTC_Dst), jd)
        @test abs(dtc_dst - dtc_jb) < 10.0
    end

    # == Storm: Halloween 2003 first peak (20:00-23:00 UT Oct 29) ==========================
    # Complex multi-storm; residuals ≤ 35 K driven by storm-onset detection differences
    # and the different storm boundary algorithms (pre-scan vs per-timestep).

    for h in [20, 21, 22, 23]
        jd = datetime2julian(DateTime(2003, 10, 29, h, 0, 0))
        dtc_jb  = space_index(Val(:DTC),     jd)
        dtc_dst = space_index(Val(:DTC_Dst), jd)
        @test abs(dtc_dst - dtc_jb) < 35.0
    end

    # == Calm periods ======================================================================
    # Both use the same Jacchia 1970 analytical formula (ap + 100*(1-exp(-0.08*ap)),
    # ap capped at 50). Residuals ≤ 20 K are due to ap data source differences
    # (Celestrak SW-All.csv vs SET SOLRESAP).

    for dt in [
        DateTime(2020, 6, 19, 12, 0, 0),
        DateTime(2010, 1, 15, 12, 0, 0),
        DateTime(2019, 8, 20, 12, 0, 0),
        DateTime(2018, 3,  1, 12, 0, 0),
    ]
        jd = datetime2julian(dt)
        dtc_jb  = space_index(Val(:DTC),     jd)
        dtc_dst = space_index(Val(:DTC_Dst), jd)
        @test abs(dtc_dst - dtc_jb) < 20.0
    end

    SpaceIndices.destroy()
end

@testset "DTC_Dst with Hpo ap source" begin
    # Test the dTc computation using the hourly ap60 data from GFZ Hpo instead of the
    # default 3-hour Celestrak ap. Hpo data starts in 1985.

    SpaceIndices.init(SpaceIndices.Hpo)
    SpaceIndices.init(SpaceIndices.Dst; ap_source = :hpo)
    SpaceIndices.init(SpaceIndices.JB2008)

    # == Cross-validation against JB2008 DTC ===============================================
    # The Hpo hourly ap differs slightly from the SET SOLRESAP 3-hour ap used in
    # DTCFILE.TXT, so tolerances are wider than for the Celestrak-based tests.

    # Storm: St. Patrick's Day 2015 — residuals ≤ 10 K.
    for h in [17, 18, 19, 20, 21, 22]
        jd = datetime2julian(DateTime(2015, 3, 17, h, 0, 0))
        dtc_jb  = space_index(Val(:DTC),     jd)
        dtc_dst = space_index(Val(:DTC_Dst), jd)
        @test abs(dtc_dst - dtc_jb) < 10.0
    end

    # Storm: Halloween 2003 first peak — residuals ≤ 35 K.
    for h in [20, 21, 22, 23]
        jd = datetime2julian(DateTime(2003, 10, 29, h, 0, 0))
        dtc_jb  = space_index(Val(:DTC),     jd)
        dtc_dst = space_index(Val(:DTC_Dst), jd)
        @test abs(dtc_dst - dtc_jb) < 35.0
    end

    # Calm periods — wider tolerance than Celestrak because Hpo hourly ap values
    # can differ more from the SET SOLRESAP 3-hour ap used by JB2008. Residuals ≤ 34 K.
    for dt in [
        DateTime(2020, 6, 19, 12, 0, 0),
        DateTime(2010, 1, 15, 12, 0, 0),
        DateTime(2019, 8, 20, 12, 0, 0),
        DateTime(2018, 3,  1, 12, 0, 0),
    ]
        jd = datetime2julian(dt)
        dtc_jb  = space_index(Val(:DTC),     jd)
        dtc_dst = space_index(Val(:DTC_Dst), jd)
        @test abs(dtc_dst - dtc_jb) < 34.0
    end

    SpaceIndices.destroy()
end

@testset "DTC_Dst: Celestrak vs Hpo consistency" begin
    # The two ap sources should produce broadly consistent dTc values for the same dates.

    dates = [
        DateTime(2020, 6, 19, 12, 0, 0),
        DateTime(2010, 1, 15, 12, 0, 0),
        DateTime(2015, 3, 17, 20, 0, 0),
    ]

    # -- Compute with Celestrak ap (default) --
    SpaceIndices.init(SpaceIndices.Celestrak)
    SpaceIndices.init(SpaceIndices.Dst; ap_source = :celestrak)
    dtc_celestrak = [space_index(Val(:DTC_Dst), datetime2julian(dt)) for dt in dates]
    SpaceIndices.destroy()

    # -- Compute with Hpo ap --
    SpaceIndices.init(SpaceIndices.Hpo)
    SpaceIndices.init(SpaceIndices.Dst; ap_source = :hpo)
    dtc_hpo = [space_index(Val(:DTC_Dst), datetime2julian(dt)) for dt in dates]
    SpaceIndices.destroy()

    # The two sources should agree within 12 K. Differences arise from the different temporal
    # resolution (3h vs 1h) and minor data source discrepancies.
    for i in eachindex(dates)
        @test abs(dtc_celestrak[i] - dtc_hpo[i]) < 12.0
    end
end

@testset "DTC_Dst: Fortran DTCMAKEDR regression (contrived storm)" begin
    # Reference values from DTCMAKEDR_AUTO.f compiled with a contrived Dst storm profile
    # and stub DTCAP (fixed ap=4 baseline = 31.385 K).
    #
    # The Fortran test harness (test/test_dtc_fortran.f) populates the DSTDATA common block
    # with the same 50-point hourly Dst profile and calls DSTDTC at each grid point.
    #
    # This tests the full algorithm: storm detection, phase classification, DELAY mechanism,
    # and the main/recovery/late-recovery integration equations.

    # -- Contrived hourly Dst profile --
    vdst = Float64[
        #  1-10: Quiet pre-storm
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        # 11-15: Storm onset & main phase
        0, -30, -80, -150, -200,
        # 16-20: Fast recovery (slope > 100 nT/day)
        -170, -140, -115, -100, -90,
        # 21-25: Moderate recovery (slope drops < 100 nT/day → slope change)
        -85, -82, -80, -78, -77,
        # 26-30: Slow tail (still < -75 → storm end delayed)
        -76, -76, -75, -74, -73,
        # 31-35: Gradual return (6 pts > -75 needed for storm end)
        -72, -71, -70, -68, -65,
        # 36-40
        -60, -55, -50, -45, -40,
        # 41-45: Return to quiet
        -35, -30, -25, -20, -15,
        # 46-50
        -10, -5, 0, 0, 0,
    ]

    # Constant ap-based baseline (ap = 4 → Jacchia 1970)
    baseline_val = SpaceIndices._ap_to_dtc(4.0)
    vbaseline = fill(baseline_val, length(vdst))

    # Compute Julia DTC
    vdtc = SpaceIndices._compute_dtc_from_dst(vdst, vbaseline)

    # Fortran reference (from test/test_dtc_fortran.f output)
    # DTC[k] at each hourly grid point, computed by DTCMAKEDR_AUTO.f DSTDTC subroutine
    # with stub DTCAP returning ap=4 baseline.
    fortran_dtc = [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,   # 1-10
        0.0, 0.0,                                                # 11-12
        31.3852057431,                                           # 13
        76.9879819286,                                           # 14
        155.7486222145,                                          # 15
        266.9317742466,                                          # 16
        342.6674774967,                                          # 17
        320.5674868569,                                          # 18
        302.3674946573,                                          # 19
        287.4174993374,                                          # 20
        274.4175024574,                                          # 21
        262.7175040173,                                          # 22
        251.6675049531,                                          # 23
        241.0075185391,                                          # 24
        236.0075185390,                                          # 25
        231.0075245400,                                          # 26
        228.5075245399,                                          # 27
        226.0075305412,                                          # 28
        226.0075245398,                                          # 29
        223.5075245397,                                          # 30
        221.0075245397,                                          # 31
        218.5075245396,                                          # 32
        216.0075245395,                                          # 33
        213.5075245394,                                          # 34
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,   # 35-44
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,                         # 45-50
    ]

    # Storm detection: verify detected storm parameters match Fortran
    storms = SpaceIndices._detect_dst_storms(vdst)
    @test length(storms) == 1
    s = storms[1]
    @test s.start_idx == 11
    @test s.min_idx == 15
    @test s.slope_change_idx == 22
    @test s.end_idx == 34
    @test s.dst_min == -200.0
    @test s.dst_max == 0.0

    # Compare Julia vs Fortran at each hourly grid point.
    # For non-storm indices (Fortran DTC = 0), Julia returns the ap baseline.
    # For storm indices, the values should match within floating-point tolerance.
    #
    # The Fortran uses 0 for non-storm; Julia uses the ap baseline. We compare storm
    # indices only for the integration match.
    #
    # Tolerance: the Fortran uses integer Dst and different floating-point accumulation,
    # so sub-0.1 K agreement is expected.
    for k in 13:34
        diff = abs(vdtc[k] - fortran_dtc[k])
        @test diff < 0.1
    end

    # Verify non-storm indices return the ap baseline
    for k in [1:12; 35:50]
        @test vdtc[k] ≈ baseline_val
    end
end

@testset "Dst [ERRORS]" begin
    SpaceIndices.init(SpaceIndices.Celestrak)
    SpaceIndices.init(SpaceIndices.Dst)

    # The data starts on 1957-01-01.
    dt = DateTime(1956, 12, 31)
    jd = datetime2julian(dt)

    @test_throws ArgumentError space_index(Val(:Dst), dt)
    @test_throws ArgumentError space_index(Val(:Dst), jd)

    @test_throws ArgumentError space_index(Val(:DTC_Dst), dt)
    @test_throws ArgumentError space_index(Val(:DTC_Dst), jd)

    SpaceIndices.destroy()
end
