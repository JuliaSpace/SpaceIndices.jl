## Description #############################################################################
#
# Space index set: Dst (Disturbance Storm Time)
# Source: WDC for Geomagnetism, Kyoto University
# URL: https://wdc.kugi.kyoto-u.ac.jp/dstdir/
#
# The Dst (Disturbance Storm Time) index is an hourly measure of the equatorial
# geomagnetic disturbance level. It represents the axially symmetric disturbance magnetic
# field at the dipole equator on the Earth's surface, measured in nanoTesla (nT). Negative
# Dst values indicate geomagnetic storms.
#
# Data categories:
#   - Final:       1957/01 - 2020/12 (definitive, quality-checked)
#   - Provisional: 2021/01 - present (visually screened for artificial noise)
#   - Real-time:   Where provisional ends - present (unverified quicklook, for monitoring)
#
# The data is downloaded as monthly HTML pages from the Kyoto WDC. Each page contains
# 24 hourly Dst values for every day in the month.
#
# References:
#   Sugiura, M. (1964), Hourly values of equatorial Dst for the IGY,
#   Ann. Int. Geophys. Year, 35, 9-45.
#
#   Bowman, B.R., Tobiska, W.K., Marcos, F.A., Huang, C.Y., Lin, C.S., and Burke, W.J.
#   (2008), "A New Empirical Thermospheric Density Model JB2008 Using New Solar and
#   Geomagnetic Indices," AIAA/AAS Astrodynamics Specialist Conference, AIAA 2008-6438.
#
#   Bowman, B.R. (2008), DTCMAKEDR_AUTO.f — Fortran reference implementation of the
#   dTc storm-time exospheric temperature correction algorithm for JB2008. Revised by
#   D. Bouwer (2011–2023) and S. Mutschler (2023).
#
############################################################################################

############################################################################################
#                                       Constants                                          #
############################################################################################

# Year boundaries for DST data categories.
# These reflect the data currently available at the Kyoto WDC.
# Update _DST_FINAL_END_YEAR when new final data releases are published.
const _DST_FINAL_START_YEAR = 1957
const _DST_FINAL_END_YEAR   = 2020
const _DST_PROV_START_YEAR  = 2021

# Month name lookup for parsing the header in DST HTML pages.
const _DST_MONTH_NAMES = Dict{String, Int}(
    "JANUARY"   => 1,  "FEBRUARY"  => 2,  "MARCH"     => 3,
    "APRIL"     => 4,  "MAY"       => 5,  "JUNE"      => 6,
    "JULY"      => 7,  "AUGUST"    => 8,  "SEPTEMBER" => 9,
    "OCTOBER"   => 10, "NOVEMBER"  => 11, "DECEMBER"  => 12
)

############################################################################################
#                                        Structure                                         #
############################################################################################

struct Dst <: SpaceIndexSet
    vjd::Vector{Float64}
    vdst::Vector{Float64}
    vdtc::Vector{Float64}
end

############################################################################################
#                                           API                                            #
############################################################################################

function urls(::Type{Dst})
    _urls = String[]

    # Final DST: 1957/01 - 2020/12.
    for year in _DST_FINAL_START_YEAR:_DST_FINAL_END_YEAR
        for month in 1:12
            ym = _dst_ym_str(year, month)
            push!(_urls, "https://wdc.kugi.kyoto-u.ac.jp/dst_final/$(ym)/index.html")
        end
    end

    # Provisional DST: 2021/01 - current month.
    current_dt = now()
    cy = Dates.year(current_dt)
    cm = Dates.month(current_dt)

    for year in _DST_PROV_START_YEAR:cy
        end_m = (year == cy) ? cm : 12
        for month in 1:end_m
            ym = _dst_ym_str(year, month)
            push!(_urls, "https://wdc.kugi.kyoto-u.ac.jp/dst_provisional/$(ym)/index.html")
        end
    end

    # Real-time (quicklook) DST: duplicates the provisional range.
    # During _fetch_dst_files(), real-time is only tried for months where provisional is
    # unavailable. Listed here for API completeness.
    for year in _DST_PROV_START_YEAR:cy
        end_m = (year == cy) ? cm : 12
        for month in 1:end_m
            ym = _dst_ym_str(year, month)
            push!(_urls, "https://wdc.kugi.kyoto-u.ac.jp/dst_realtime/$(ym)/index.html")
        end
    end

    return _urls
end

function filenames(::Type{Dst})
    _fns = String[]

    for year in _DST_FINAL_START_YEAR:_DST_FINAL_END_YEAR
        for month in 1:12
            push!(_fns, "dst_final_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    current_dt = now()
    cy = Dates.year(current_dt)
    cm = Dates.month(current_dt)

    for year in _DST_PROV_START_YEAR:cy
        end_m = (year == cy) ? cm : 12
        for month in 1:end_m
            push!(_fns, "dst_prov_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    for year in _DST_PROV_START_YEAR:cy
        end_m = (year == cy) ? cm : 12
        for month in 1:end_m
            push!(_fns, "dst_realtime_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    return _fns
end

function expiry_periods(::Type{Dst})
    _exp = DatePeriod[]

    # Final: effectively never expires.
    n_final = (_DST_FINAL_END_YEAR - _DST_FINAL_START_YEAR + 1) * 12
    for _ in 1:n_final
        push!(_exp, Year(100))
    end

    # Provisional: refresh daily to stay current.
    current_dt = now()
    cy = Dates.year(current_dt)
    cm = Dates.month(current_dt)

    for year in _DST_PROV_START_YEAR:cy
        end_m = (year == cy) ? cm : 12
        for _ in 1:end_m
            push!(_exp, Day(1))
        end
    end

    # Real-time: refresh daily.
    for year in _DST_PROV_START_YEAR:cy
        end_m = (year == cy) ? cm : 12
        for _ in 1:end_m
            push!(_exp, Day(1))
        end
    end

    return _exp
end

function parse_files(::Type{Dst}, filepaths::Vector{String}; ap_source::Symbol = :celestrak)
    # Pre-allocate with a rough estimate: ~68 years × 365 days × 24 hours ≈ 600k entries.
    vjd  = Float64[]
    vdst = Float64[]
    sizehint!(vjd,  600_000)
    sizehint!(vdst, 600_000)

    for filepath in filepaths
        try
            _parse_dst_html!(vjd, vdst, filepath)
        catch e
            @debug "Failed to parse DST file: $(basename(filepath))" exception=e
        end
    end

    # Sort by Julian date (files may not be in strict order).
    if !issorted(vjd)
        perm = sortperm(vjd)
        vjd  = vjd[perm]
        vdst = vdst[perm]
    end

    # Remove duplicate timestamps, keeping the latest value for each.
    _deduplicate_dst!(vjd, vdst)

    # Compute the exospheric temperature change (dTc) from the Dst time series using the
    # JB2008 storm algorithm (Bowman et al., 2008).
    #
    # The non-storm baseline is derived from the ap index (with 6.7-hour lag) converted to
    # dTc via the Jacchia 1970 lookup table. The ap source is selected by the `ap_source`
    # keyword:
    #   :celestrak — 3-hour ap from Celestrak SW-All.csv (default, matches JB2008 DTCFILE)
    #   :hpo       — hourly ap60 from GFZ Hpo index (higher cadence, better for real-time)
    vbaseline = _build_ap_baseline(vjd, ap_source)
    vdtc = _compute_dtc_from_dst(vdst, vbaseline)

    return Dst(vjd, vdst, vdtc)
end

@register Dst

# Dst requires explicit initialization — it downloads many monthly files and depends on an
# ap data source (Celestrak or Hpo) being initialized first.
_auto_init(::Type{Dst}) = false

# -- Specialized init for Dst --------------------------------------------------------------- #

"""
    init(::Type{Dst}; ap_source::Symbol = :celestrak, kwargs...) -> Nothing

Initialize the Dst space index set.

Dst is not included in the default `init()` call because it downloads many monthly files
and depends on an ap data source being initialized first.

# Keywords

- `ap_source::Symbol`: The source of ap data for the non-storm dTc baseline.
    - `:celestrak` — Use 3-hour ap from Celestrak (default). Matches JB2008 DTCFILE.TXT
      convention.
    - `:hpo` — Use hourly ap60 from the GFZ Hpo index. Provides higher temporal resolution.
    The corresponding index set (Celestrak or Hpo) must already be initialized.
    (**Default** = `:celestrak`)
- `filepaths::Union{Nothing, Vector{String}}`: If `nothing`, download from Kyoto WDC.
    (**Default** = `nothing`)
- `force_download::Bool`: If `true`, re-download regardless of timestamps.
    (**Default** = `false`)
"""
function init(
    ::Type{Dst};
    ap_source::Symbol = :celestrak,
    filepaths::Union{Nothing, Vector{String}} = nothing,
    force_download::Bool = false,
)
    ap_source in (:celestrak, :hpo) || throw(ArgumentError(
        "ap_source must be :celestrak or :hpo, got :$ap_source"
    ))

    id = findfirst(x -> first(x) === Dst, _SPACE_INDEX_SETS)
    isnothing(id) && throw(ArgumentError("The space index set Dst is not registered!"))

    handler = _SPACE_INDEX_SETS[id] |> last

    fp = isnothing(filepaths) ?
        _fetch_dst_files(; force_download = force_download) :
        filepaths

    obj = parse_files(Dst, fp; ap_source = ap_source)
    push!(handler, obj)

    return nothing
end

# Download DST monthly HTML files from the Kyoto WDC.
#
# Final files (1957/01–2020/12) are known to exist and always downloaded. Provisional files
# (2021/01 onward) are fetched sequentially, stopping at the first month that returns a 404.
# Real-time (quicklook) files are then fetched for any remaining months up to the current
# month. This ensures coverage up to (approximately) the present day, even when provisional
# data lags behind by several months.
function _fetch_dst_files(; force_download::Bool = false)
    key = string(Dst)
    filepaths = String[]

    # -- Final DST (1957/01–2020/12): all files exist. ------------------------------------
    for year in _DST_FINAL_START_YEAR:_DST_FINAL_END_YEAR, month in 1:12
        ym = _dst_ym_str(year, month)
        fp = _download_file(
            "https://wdc.kugi.kyoto-u.ac.jp/dst_final/$(ym)/index.html",
            key,
            "dst_final_$(year)_$(lpad(month, 2, '0')).html";
            force_download = force_download,
            expiry_period  = Year(100),
        )
        push!(filepaths, fp)
    end

    # -- Provisional DST (2021/01–present): stop at first missing month. ------------------
    current_dt = now()
    cy = Dates.year(current_dt)
    cm = Dates.month(current_dt)

    # Track where provisional data stops so real-time can pick up.
    prov_stop_year  = _DST_PROV_START_YEAR
    prov_stop_month = 0
    done = false

    for year in _DST_PROV_START_YEAR:cy
        done && break
        end_m = (year == cy) ? cm : 12

        for month in 1:end_m
            ym = _dst_ym_str(year, month)
            try
                fp = _download_file(
                    "https://wdc.kugi.kyoto-u.ac.jp/dst_provisional/$(ym)/index.html",
                    key,
                    "dst_prov_$(year)_$(lpad(month, 2, '0')).html";
                    force_download = force_download,
                    expiry_period  = Day(1),
                )
                push!(filepaths, fp)
                prov_stop_year  = year
                prov_stop_month = month
            catch
                done = true
                break
            end
        end
    end

    # -- Real-time (quicklook) DST: fill the gap from provisional to current month. -------
    # Start from the month after the last successful provisional download.
    rt_start_year  = prov_stop_year
    rt_start_month = prov_stop_month + 1
    if rt_start_month > 12
        rt_start_year += 1
        rt_start_month = 1
    end

    if rt_start_year < cy || (rt_start_year == cy && rt_start_month <= cm)
        for year in rt_start_year:cy
            start_m = (year == rt_start_year) ? rt_start_month : 1
            end_m   = (year == cy) ? cm : 12

            for month in start_m:end_m
                ym = _dst_ym_str(year, month)
                try
                    fp = _download_file(
                        "https://wdc.kugi.kyoto-u.ac.jp/dst_realtime/$(ym)/index.html",
                        key,
                        "dst_realtime_$(year)_$(lpad(month, 2, '0')).html";
                        force_download = force_download,
                        expiry_period  = Day(1),
                    )
                    push!(filepaths, fp)
                catch
                    # Real-time data may not exist for the current month yet; not fatal.
                    @debug "Real-time Dst not available for $(ym)"
                end
            end
        end
    end

    isempty(filepaths) && error(
        "Failed to download any DST files. Check your network connection."
    )

    return filepaths
end

"""
    space_index(::Val{:Dst}, jd::Number) -> Float64

Get the Dst (Disturbance Storm Time) index [nT] at the Julian Day `jd`.

The Dst index measures the intensity of the globally symmetric part of the equatorial
ring current. Negative values indicate geomagnetic storms. Values are linearly
interpolated between hourly observations.

# Source

WDC for Geomagnetism, Kyoto University.
https://wdc.kugi.kyoto-u.ac.jp/dstdir/
"""
function space_index(::Val{:Dst}, jd::Number)
    obj    = @object(Dst)
    knots  = obj.vjd
    values = obj.vdst
    return linear_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:DTC_Dst}, jd::Number) -> Float64

Get the exospheric temperature variation [K] caused by geomagnetic activity at Julian Day
`jd`, computed from the Dst index using the JB2008 storm algorithm.

This provides a real-time alternative to the pre-computed DTC values from DTCFILE.TXT
(available via `Val(:DTC)` from the JB2008 index set), which have a ~45 day publication lag.

During geomagnetic storms (Dst < -75 nT, ΔDst ≥ 50 nT), the temperature change is
integrated using the differential equations from Burke et al. as extended by Bowman et al.
(2008), matching the DTCMAKEDR Fortran reference implementation:
  - **Main phase**: Eq. (8)/(10) with storm-magnitude-dependent slope S;
    Dst clamped to ≤ 0, no dTc floor.
  - **Recovery**: Eq. (12) with S=0.13; storm terminates if dTc < 0.
  - **Late recovery**: Eq. (13) with S=-2.5 (uses main-phase S when Dst dips).

During non-storm periods, dTc is the Jacchia 1970 ap-based temperature (ap capped at 50)
if Celestrak is initialized, or 0 otherwise.

# Reference

Bowman, B.R., et al., "A New Empirical Thermospheric Density Model JB2008 Using New
Solar and Geomagnetic Indices," AIAA 2008-6438, 2008.
"""
function space_index(::Val{:DTC_Dst}, jd::Number)
    obj    = @object(Dst)
    knots  = obj.vjd
    values = obj.vdtc
    return linear_interpolation(knots, values, jd)
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# Build a "YYYYMM" string from year and month.
function _dst_ym_str(year::Int, month::Int)
    return string(year) * lpad(month, 2, '0')
end

# Parse a single DST HTML file and append the hourly data to `vjd` and `vdst`.
#
# The Kyoto WDC HTML pages embed DST data in a <pre> block with the following structure:
#
#     WDC for Geomagnetism, Kyoto
#     Hourly Equatorial Dst Values (FINAL)
#     JANUARY 1957
#     unit=nT  UT
#      1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
#     DAY
#      1  11  13  12  12   9   7   7   6   2  -1  -7  -7  -8  -1   9   8   4   0   1   3   2   4   9   9
#      2 ...
#     ...
#
# Each data line contains a day number followed by 24 hourly values. Adjacent negative
# values can be packed without spaces (e.g., "-235-217-225"), so we use a regex to extract
# all integers from each line. Lines with exactly 25 integers (1 day + 24 values) are
# treated as data lines.
function _parse_dst_html!(vjd::Vector{Float64}, vdst::Vector{Float64}, filepath::String)
    content = read(filepath, String)

    year  = 0
    month = 0

    for line in split(content, '\n')
        # Strip HTML tags.
        clean = replace(line, r"<[^>]*>" => "")

        # Attempt to extract month and year from header lines.
        # The header contains a line like "JANUARY 1957".
        if year == 0 || month == 0
            upper = uppercase(strip(clean))
            for (mname, mnum) in _DST_MONTH_NAMES
                if occursin(mname, upper)
                    m = match(r"(\d{4})", clean)
                    if !isnothing(m) && !isnothing(m.captures[1])
                        year  = parse(Int, m.captures[1]::SubString{String})
                        month = mnum
                    end
                    break
                end
            end
        end

        # Skip lines until we have a valid year and month.
        (year == 0 || month == 0) && continue

        # Match all integers (positive and negative) in the line.
        # A valid DST data line has exactly 25 integers: 1 day + 24 hourly values.
        int_matches = collect(eachmatch(r"-?\d+", clean))
        length(int_matches) == 25 || continue

        try
            day = parse(Int, int_matches[1].match)
            (1 <= day <= 31) || continue

            # Validate the date against the calendar.
            day > Dates.daysinmonth(year, month) && continue

            for h in 0:23
                dst_val = parse(Float64, int_matches[h + 2].match)
                jd = datetime2julian(DateTime(year, month, day, h, 0, 0))
                push!(vjd,  jd)
                push!(vdst, dst_val)
            end
        catch
            continue
        end
    end
end

# Remove duplicate Julian dates in-place, keeping the last occurrence.
# Assumes `vjd` is sorted in ascending order.
function _deduplicate_dst!(vjd::Vector{Float64}, vdst::Vector{Float64})
    isempty(vjd) && return

    write_idx = 1
    for read_idx in 2:length(vjd)
        if vjd[read_idx] == vjd[write_idx]
            # Duplicate timestamp: overwrite with the newer value.
            vdst[write_idx] = vdst[read_idx]
        else
            write_idx += 1
            vjd[write_idx]  = vjd[read_idx]
            vdst[write_idx] = vdst[read_idx]
        end
    end

    resize!(vjd,  write_idx)
    resize!(vdst, write_idx)
end

############################################################################################
#                        Non-storm dTc Baseline from ap Data                               #
############################################################################################

"""
    _build_ap_baseline(vjd, ap_source) -> Union{Vector{Float64}, Nothing}

Build an hourly Jacchia 1970 dTc baseline from ap index data. Returns `nothing` if the
required index set is not initialized (falls back to zero baseline).

For each hour, the ap value from 6.7 hours earlier is looked up and converted to a
temperature increment via `_ap_to_dtc` (Jacchia 1970 formula with ap capped at 50).

# Arguments

- `vjd`: Vector of Julian dates for the Dst time series.
- `ap_source`: `:celestrak` for 3-hour ap from Celestrak, or `:hpo` for hourly ap60 from
  the GFZ Hpo index.
"""
function _build_ap_baseline(vjd::Vector{Float64}, ap_source::Symbol)
    if ap_source === :celestrak
        return _build_baseline_celestrak(vjd)
    elseif ap_source === :hpo
        return _build_baseline_hpo(vjd)
    else
        error("Unknown ap_source: $ap_source")
    end
end

# -- Celestrak (3-hour ap) ----------------------------------------------------------------- #

function _build_baseline_celestrak(vjd::Vector{Float64})
    local celestrak
    try
        celestrak = @object(Celestrak)
    catch
        return nothing
    end

    n = length(vjd)
    vbaseline = Vector{Float64}(undef, n)

    # Celestrak stores daily records with 8 three-hourly ap values per day
    # (0-3h, 3-6h, ..., 21-24h).
    ap_jd     = celestrak.vjd
    ap_tuples = celestrak.vap

    for i in 1:n
        jd_lagged = vjd[i] - _DTC_AP_LAG_HOURS / 24.0
        ap_val = _lookup_3h_ap(ap_jd, ap_tuples, jd_lagged)
        vbaseline[i] = _ap_to_dtc(ap_val)
    end

    return vbaseline
end

"""
    _lookup_3h_ap(ap_jd, ap_tuples, jd) -> Float64

Look up the 3-hour ap value for a given Julian date from the Celestrak daily ap data.
`ap_jd` contains Julian dates at the start of each day, and `ap_tuples` contains 8
three-hourly ap values per day.
"""
function _lookup_3h_ap(
    ap_jd::Vector{Float64},
    ap_tuples::Vector{NTuple{8, Float64}},
    jd::Float64,
)
    idx = searchsortedlast(ap_jd, jd)

    if idx < 1 || idx > length(ap_jd)
        return 4.0  # Quiet-time default if out of range.
    end

    fraction_of_day = jd - ap_jd[idx]
    hour_of_day = fraction_of_day * 24.0
    block = clamp(floor(Int, hour_of_day / 3.0) + 1, 1, 8)

    return ap_tuples[idx][block]
end

# -- Hpo (hourly ap60) -------------------------------------------------------------------- #

function _build_baseline_hpo(vjd::Vector{Float64})
    local hpo
    try
        hpo = @object(Hpo)
    catch
        return nothing
    end

    n = length(vjd)
    vbaseline = Vector{Float64}(undef, n)

    # Hpo stores daily records with 24 hourly ap60 values per day (0-1h, 1-2h, ..., 23-24h).
    ap_jd     = hpo.vjd
    ap_tuples = hpo.vap60

    for i in 1:n
        jd_lagged = vjd[i] - _DTC_AP_LAG_HOURS / 24.0
        ap_val = _lookup_hourly_ap(ap_jd, ap_tuples, jd_lagged)
        vbaseline[i] = isnan(ap_val) ? 0.0 : _ap_to_dtc(ap_val)
    end

    return vbaseline
end

"""
    _lookup_hourly_ap(ap_jd, ap_tuples, jd) -> Float64

Look up the hourly ap60 value for a given Julian date from the Hpo daily ap data.
`ap_jd` contains Julian dates at the start of each day, and `ap_tuples` contains 24
hourly ap values per day.
"""
function _lookup_hourly_ap(
    ap_jd::Vector{Float64},
    ap_tuples::Vector{NTuple{24, Float64}},
    jd::Float64,
)
    idx = searchsortedlast(ap_jd, jd)

    if idx < 1 || idx > length(ap_jd)
        return 4.0  # Quiet-time default if out of range.
    end

    fraction_of_day = jd - ap_jd[idx]
    hour_of_day = fraction_of_day * 24.0
    block = clamp(floor(Int, hour_of_day) + 1, 1, 24)

    return ap_tuples[idx][block]
end

############################################################################################
#                    dTc Computation from Dst (JB2008 Storm Algorithm)                     #
############################################################################################
#
# Implements the geomagnetic storm temperature model from the DTCMAKEDR Fortran reference
# code by Bruce R. Bowman (June 2008, rev. G May 2017), distributed with:
#   Bowman, B.R., et al., "A New Empirical Thermospheric Density Model JB2008 Using New
#   Solar and Geomagnetic Indices," AIAA 2008-6438, 2008.
#
# The algorithm detects storms (Dst < -75 nT, ΔDst ≥ 50 nT) and integrates an exospheric
# temperature change (dTc) through four phases:
#   1. Main phase: temperature rises as ring current intensifies (Eq. 8/10/11)
#   2. Sub-storm correction: handles temporary Dst recoveries during main phase (Eq. 11)
#   3. Recovery phase: fast temperature decay after Dst minimum (Eq. 12)
#   4. Late recovery phase: slow temperature decay until storm end (Eq. 13)
#
# Key behaviors matched to the Fortran reference (DTCMAKEDR_AUTO.f):
#   - Dst values clamped to ≤ 0 during main phase (SSC protection, lines 382–383)
#   - No dTc floor during main phase; floor only in recovery/late recovery (Apr 2012 rev)
#   - Storm terminated when dTc < 0 in recovery/late recovery → ap baseline (lines 407–414)
#   - Late recovery uses main-phase slope S when Dst dips (line 430)
#   - ap capped at 50 before Jacchia 1970 equation (line 251)
#   - Slope change detected via centered Dst derivative < 100 nT/day (DSTREC)
#   - Storm end duration = 0.0075 × ΔDst days with flat-bottom extension (DSTEND)
#
# Outside of storms, dTc is set to the Jacchia 1970 ap-based temperature (if Celestrak is
# initialized) or 0 (if not). The ap-based baseline also provides the initial condition at
# storm commencement, matching the JB2008 reference implementation.
############################################################################################

# -- Non-storm dTc baseline (JB2008 DTCMAKEDR convention) -------------------------------- #

# Jacchia 1970 lag: the 3-hour ap value is taken from 6.7 hours earlier.
const _DTC_AP_LAG_HOURS = 6.7

"""
    _ap_to_dtc(ap::Float64) -> Float64

Compute the non-storm dTc [K] from a 3-hour ap index value using the Jacchia 1970
geomagnetic activity equation as implemented in DTCMAKEDR (lines 251–255):

    if ap > 50: ap = 50    (cap per JB2008 convention)
    dTc = ap + 100 × (1 − exp(−0.08 × ap))
"""
function _ap_to_dtc(ap::Float64)
    ap <= 0.0 && return 0.0
    # Cap ap at 50 per JB2008 convention (DTCMAKEDR line 251).
    ap_capped = min(ap, 50.0)
    # Jacchia 1970 geomagnetic activity equation (DTCMAKEDR lines 254–255).
    return ap_capped + 100.0 * (1.0 - exp(-0.08 * ap_capped))
end

# -- Constants for the dTc computation -------------------------------------------------- #

# Temperature relaxation time constant τ₁ [hours].
const _DTC_TAU1 = 6.5

# Dst relaxation time constant τ₂ [hours].
const _DTC_TAU2 = 7.7

# Storm detection threshold [nT].
const _DTC_STORM_THRESHOLD = -75.0

# Minimum storm magnitude (max − min) [nT] (DTCMAKEDR DSTBEG IMAG).
const _DTC_STORM_MIN_MAGNITUDE = 50

# Substorm correction factor (SFAC) for Equation (11).
const _DTC_SFAC = 0.3

# Late recovery phase slope [K/nT].
const _DTC_LATE_RECOVERY_SLOPE = -2.5

# Recovery phase slope [K/nT] — Equation (12) with τ₁→∞, τ₂=1.
const _DTC_RECOVERY_SLOPE = 0.13

# Pre-computed coefficients for Equation (8).
const _DTC_ALPHA = 1.0 - 1.0 / _DTC_TAU1   # ≈ 0.846
const _DTC_BETA  = 1.0 - 1.0 / _DTC_TAU2   # ≈ 0.870

# Maximum scan distance for storm detection [hours].
const _DTC_MAX_STORM_SCAN = 240  # 10 days

# Slope limit for recovery inflection point detection [nT/day] (DSTREC SLPLIM).
const _DTC_SLOPE_LIMIT = 100.0

# -- Storm structure -------------------------------------------------------------------- #

struct _DstStormEvent
    start_idx::Int           # Index of storm commencement (Dst maximum before drop)
    min_idx::Int             # Index of Dst minimum (end of main phase)
    slope_change_idx::Int    # Index where recovery transitions to late recovery
    end_idx::Int             # Index of storm end
    dst_min::Float64         # Minimum Dst value during the storm [nT]
    dst_max::Float64         # Dst value at storm commencement [nT]
end

# -- Main entry point ------------------------------------------------------------------- #

"""
    _compute_dtc_from_dst(vdst, vbaseline) -> Vector{Float64}
    _compute_dtc_from_dst(vdst)            -> Vector{Float64}

Compute the exospheric temperature change dTc [K] from an hourly Dst time series using the
JB2008 storm algorithm (DTCMAKEDR). Returns a vector of dTc values the same length as
`vdst`.

If `vbaseline` is provided (same length as `vdst`), it supplies the Jacchia 1970 ap-based
temperature for each hour. This is used as:
  - The dTc value during non-storm periods.
  - The initial condition at storm commencement.

If omitted, the baseline is 0 everywhere (storm-only mode).

The algorithm is a two-pass procedure:
  1. Detect all storm events in the Dst time series.
  2. Integrate dTc through each storm using the appropriate phase equations.

When dTc goes negative during recovery or late recovery, the storm is terminated early
and the ap-based baseline is restored (matching DTCMAKEDR April 2012 revision).
"""
function _compute_dtc_from_dst(
    vdst::Vector{Float64},
    vbaseline::Union{Vector{Float64}, Nothing} = nothing,
)
    n = length(vdst)
    has_baseline = !isnothing(vbaseline)

    # Start from the baseline (or zeros if none provided).
    vdtc = has_baseline ? copy(vbaseline) : zeros(Float64, n)

    n < 2 && return vdtc

    # ---- Pass 1: Detect all storm events ---- #
    storms = _detect_dst_storms(vdst)

    # ---- Pass 2: Integrate dTc for each storm ---- #
    for (si, storm) in enumerate(storms)
        # Initial condition: the baseline value at storm start, or carry-over from the
        # previous storm if they overlap.
        initial_dtc = has_baseline ? vbaseline[storm.start_idx] : 0.0

        if si > 1
            prev_end = storms[si - 1].end_idx
            if storm.start_idx <= prev_end + 1
                initial_dtc = vdtc[prev_end]
            end
        end

        _integrate_storm_dtc!(vdtc, vdst, vbaseline, storm, initial_dtc)
    end

    return vdtc
end

# -- Storm detection -------------------------------------------------------------------- #

"""
    _detect_dst_storms(vdst) -> Vector{_DstStormEvent}

Scan the hourly Dst time series and return a vector of detected storm events.

A storm requires:
  - Dst minimum < $(_DTC_STORM_THRESHOLD) nT
  - Magnitude ΔDst (max − min) ≥ $(_DTC_STORM_MIN_MAGNITUDE) nT

Based on DSTSTM / DSTBEG / DSTMAX / DSTMIN / DSTREC / DSTEND from DTCMAKEDR.
"""
function _detect_dst_storms(vdst::Vector{Float64})
    n = length(vdst)
    storms = _DstStormEvent[]

    i = 1
    while i <= n
        # Look for the first point below the storm threshold.
        if vdst[i] >= _DTC_STORM_THRESHOLD
            i += 1
            continue
        end

        # -- Found a storm trigger at index `i`. Determine the full storm profile. -- #

        # Find the storm commencement (Dst maximum) by scanning backward. This is
        # used for the slope calculation and integration start, not for minimum search.
        start_idx, dst_max = _find_storm_start(vdst, i)

        # Find the Dst minimum (main phase end). Search from the TRIGGER index `i`,
        # not from start_idx, matching Fortran DSTMIN which starts from TSTART (the
        # storm onset point). Starting from start_idx would cause premature
        # termination via the IPTS counter during the pre-storm descent.
        min_idx, dst_min = _find_storm_minimum(vdst, i, n)

        # Magnitude check: ΔDst must be ≥ 50 nT AND min must be < -75.
        deldst = dst_max - dst_min
        if deldst < _DTC_STORM_MIN_MAGNITUDE || dst_min >= _DTC_STORM_THRESHOLD
            # Not a valid storm; advance past the minimum to avoid infinite loop.
            i = max(i + 1, min_idx + 1)
            continue
        end

        # Find the storm end (includes flat-bottom handling, new-storm detection).
        end_idx = _find_storm_end(vdst, min_idx, dst_min, dst_max, n)

        # Find the recovery slope change (centered derivative method).
        slope_change_idx = _find_slope_change(vdst, min_idx, end_idx, n)

        push!(storms, _DstStormEvent(
            start_idx, min_idx, slope_change_idx, end_idx, dst_min, dst_max,
        ))

        # Resume scanning after this storm (end_idx ≥ min_idx ≥ i, so i always advances).
        i = end_idx + 1
    end

    return storms
end

"""
    _find_storm_start(vdst, trigger_idx) -> (start_idx, dst_max)

Scan backward from the storm trigger (first Dst < -75) to find the Dst maximum (storm
commencement point). Based on DSTMAX from DTCMAKEDR.

Stops when 6 consecutive points ≥ -40 nT are found (quiet pre-storm period).
"""
function _find_storm_start(vdst::Vector{Float64}, trigger_idx::Int)
    max_val = vdst[trigger_idx]
    max_idx = trigger_idx
    quiet_count = 0

    for k in (trigger_idx - 1):-1:max(1, trigger_idx - 72)
        val = vdst[k]

        if val > max_val
            max_val = val
            max_idx = k
        end

        # Count consecutive quiet points (≥ -40). Reset if Dst drops below -60.
        if val < -60.0
            quiet_count = 0
        elseif val >= -40.0
            quiet_count += 1
        end

        if quiet_count >= 6
            break
        end
    end

    return max_idx, max_val
end

"""
    _find_storm_minimum(vdst, start_idx, n) -> (min_idx, dst_min)

Scan forward from the storm start to find the global Dst minimum.

Termination criteria (matching DSTMIN from DTCMAKEDR):
  - Recovery of 125 nT from minimum
  - Recovery of 75 nT AND current Dst > -75
  - 2 accumulated points ≥ -40 (after a valid minimum < -75 is found)
"""
function _find_storm_minimum(vdst::Vector{Float64}, start_idx::Int, n::Int)
    min_val = Float64(typemax(Int32))
    min_idx = start_idx
    max_since_min = Float64(typemin(Int32))
    ipts = 0

    for k in (start_idx + 1):min(n, start_idx + _DTC_MAX_STORM_SCAN)
        val = vdst[k]

        # Track global minimum.
        if val < min_val
            min_val = val
            min_idx = k
            max_since_min = min_val  # Reset max tracker (DSTMIN: IMAX = IMIN).
        end

        # Track max since last minimum.
        if val > max_since_min
            max_since_min = val
        end

        # Termination: recovery of 125 nT from minimum (DSTMIN line 1011).
        if max_since_min > min_val + 125
            break
        end

        # Termination: recovery of 75 nT AND max above -75 (DSTMIN lines 1013–1014).
        if (max_since_min - min_val > 75) && max_since_min > -75.0
            break
        end

        # Termination: 2 accumulated points ≥ -40 after a valid minimum (DSTMIN
        # lines 1021–1023). Points below -40 reset the counter.
        if val < -40.0
            ipts = 0
        end
        if min_val < -75.0
            ipts += 1
        end
        if ipts >= 2
            break
        end
    end

    # If no valid minimum was found, return the start index.
    if min_val > 0.0
        return start_idx, vdst[start_idx]
    end

    return min_idx, min_val
end

"""
    _find_slope_change(vdst, min_idx, end_idx, n) -> Int

After the Dst minimum, find the index where the recovery slope changes from fast (early
recovery) to slow (late recovery).

Detection method (matching DSTREC from DTCMAKEDR):
  - Compute centered Dst derivative: slope = (Dst[k+1] - Dst[k-1]) / (2 × Δt) [nT/day]
  - Slope change detected when slope < 100 nT/day for 3 instances
  - Also stops at 6 accumulated points ≥ -40 (backstop)
"""
function _find_slope_change(
    vdst::Vector{Float64},
    min_idx::Int,
    end_idx::Int,
    n::Int,
)
    dtdst = 1.0 / 24.0  # 1 hour in days
    irec = 0
    ipts = 0

    # Start 2 hours after minimum (DSTREC: TSTEP = TMIN + DTDST, then TSTEP + DTDST).
    for k in (min_idx + 2):min(n - 1, end_idx)
        # Centered derivative (DSTREC line 1064).
        slope = (vdst[k + 1] - vdst[k - 1]) / (2.0 * dtdst)

        if slope < _DTC_SLOPE_LIMIT
            irec += 1
            if irec >= 3
                return k - 1  # DSTREC: TREC = TSTEP - DTDST
            end
        end

        # Backstop: 6 accumulated points ≥ -40 (DSTREC lines 1073–1074).
        if vdst[k] >= -40.0
            ipts += 1
        end
        if ipts >= 6
            break
        end
    end

    # Default: end_idx (DSTREC: TREC = TEND).
    return end_idx
end

"""
    _find_storm_end(vdst, min_idx, dst_min, dst_max, n) -> Int

Determine the storm end point. Based on DSTEND from DTCMAKEDR.

1. Extends the minimum forward through flat bottoms (within 15 nT of minimum).
2. Computes estimated duration: 0.0075 × ΔDst days (where ΔDst = max − min).
3. Steps forward checking for:
   - 6 accumulated points with Dst > -75 nT → storm end
   - Dst drops by > 75 nT from a local max → new storm (end at local max)
   - Estimated duration reached → storm end
"""
function _find_storm_end(
    vdst::Vector{Float64},
    min_idx::Int,
    dst_min::Float64,
    dst_max::Float64,
    n::Int,
)
    # -- Flat bottom handling: extend minimum through points within 15 nT -- #
    # (DSTEND lines 1109–1121)
    min_ext_idx = min_idx
    for k in (min_idx + 1):min(n, min_idx + _DTC_MAX_STORM_SCAN)
        if vdst[k] > dst_min + 15.0
            min_ext_idx = k - 1
            break
        end
        min_ext_idx = k
    end

    # -- Compute estimated end time: 0.0075 × ΔDst days (DSTEND line 1124) -- #
    deldst = dst_max - dst_min  # Positive (e.g., 0 - (-200) = 200)
    estimated_days = 0.0075 * deldst
    estimated_hours = max(round(Int, estimated_days * 24.0), 6)
    max_end = min(n, min_ext_idx + estimated_hours)

    # -- Step forward looking for end conditions -- #
    # (DSTEND lines 1130–1157)
    ipts = 0
    local_max = dst_min
    local_max_idx = min_ext_idx

    for k in (min_ext_idx + 1):max_end
        val = vdst[k]

        # Track local maximum during recovery.
        if val > local_max
            local_max = val
            local_max_idx = k
        end

        # New storm detection: Dst drops by > 75 from local max (DSTEND line 1146).
        if val - local_max < -75
            return local_max_idx
        end

        # Accumulated points above -75 (DSTEND line 1152).
        if val > _DTC_STORM_THRESHOLD
            ipts += 1
        end
        if ipts >= 6
            return k
        end
    end

    return max_end
end

# -- dTc integration -------------------------------------------------------------------- #

"""
    _dtc_slope(dst_min::Float64) -> Float64

Compute the storm main phase slope S as a function of the storm Dst minimum. This is
Equation (10) from JB2008 / DTCMAKEDR line 376:

    S = -1.5050×10⁻⁵ × DstMIN² - 1.0604×10⁻² × DstMIN - 3.20

For very large storms (DstMIN < -450 nT), S is capped at -1.40.
"""
function _dtc_slope(dst_min::Float64)
    if dst_min < -450.0
        return -1.40
    end
    return -1.5050e-5 * dst_min^2 - 1.0604e-2 * dst_min - 3.20
end

# Restore baseline (or zero) dTc values for a range of indices. Called when a storm
# is terminated early due to dTc going negative (DTCMAKEDR April 2012 revision).
function _restore_baseline!(
    vdtc::Vector{Float64},
    vbaseline::Union{Vector{Float64}, Nothing},
    from_idx::Int,
    to_idx::Int,
)
    if !isnothing(vbaseline)
        for k in from_idx:to_idx
            vdtc[k] = vbaseline[k]
        end
    else
        for k in from_idx:to_idx
            vdtc[k] = 0.0
        end
    end
end

"""
    _integrate_storm_dtc!(vdtc, vdst, vbaseline, storm, initial_dtc) -> Nothing

Integrate the exospheric temperature change through a single storm event, writing the
results into `vdtc`. Matches the DSTDTC subroutine from DTCMAKEDR.

  - **Main phase** (start → min+lag): Equation (8) with slope S from Equation (10).
    Dst values are clamped to ≤ 0 to guard against SSC positive spikes.
    When Dst increases (substorms), Equation (11) is used instead.
    No dTc floor is applied during the main phase (per Fortran reference).
  - **Recovery** (min+lag → slope_change+lag): Equation (12)
  - **Late recovery** (slope_change+lag → end): Equation (13).
    When Dst dips (ΔDst < 0), the main phase slope S is used instead of -2.5.

In recovery and late recovery, if dTc goes negative the storm is terminated early and
the ap-based baseline is restored (DTCMAKEDR April 2012 revision, lines 407–414, 436–443).

The Fortran DTCMAKEDR applies a DELAY as a pure output time shift (lines 345–348,
457–458, 468–477): the integration runs at "integration time" TSTEP with Dst accessed
at TSTEP (no lag), and the output is mapped to time TSTEP + DELAY. This means:
  - Output at time T uses Dst from time T − DELAY (uniform lag on ALL phases)
  - Phase boundaries in the output domain are shifted by +DELAY

To match this, the lag is applied uniformly to ALL Dst accesses (not just main phase),
and the phase boundaries are shifted by +lag:
  - 0 hours for large storms (DstMIN < -350 nT)
  - 1 hour for moderate storms (-350 ≤ DstMIN < -250 nT)
  - 2 hours for minor storms (DstMIN ≥ -250 nT)
"""
function _integrate_storm_dtc!(
    vdtc::Vector{Float64},
    vdst::Vector{Float64},
    vbaseline::Union{Vector{Float64}, Nothing},
    storm::_DstStormEvent,
    initial_dtc::Float64,
)
    (; start_idx, min_idx, slope_change_idx, end_idx, dst_min) = storm

    # Compute the main phase slope.
    S = _dtc_slope(dst_min)

    # Determine the DELAY lag [hours] (DTCMAKEDR lines 345–347).
    lag = if dst_min < -350.0
        0
    elseif dst_min < -250.0
        1
    else
        2
    end

    # Phase boundaries shifted by lag to match Fortran's output time mapping
    # (DTCMAKEDR lines 396/422/449 use TMIN/TREC/TEND without DELAY, but the
    # output is at TSTEP + DELAY, so boundaries in the output domain are shifted).
    main_end  = min(end_idx, min_idx + lag)
    recov_end = min(end_idx, slope_change_idx + lag)

    dtc = initial_dtc

    for k in (start_idx + 1):end_idx
        # All Dst accesses use the lagged index (= integration time = output − DELAY).
        k_lag      = max(1, k - lag)
        k_lag_prev = max(1, k - 1 - lag)

        if k <= main_end
            # -- Main phase: Equation (8) with substorm correction (11) -- #

            # Clamp Dst to ≤ 0 to guard against SSC positive spikes
            # (DTCMAKEDR lines 382–383).
            dst_curr = min(0.0, Float64(vdst[k_lag]))
            dst_prev = min(0.0, Float64(vdst[k_lag_prev]))

            deldst = dst_curr - dst_prev

            if deldst >= 0.0
                # Dst increasing or flat (substorm recovery): Equation (11).
                #   dTc₁ = dTc₀ - SFAC × S × ΔDst
                # (DTCMAKEDR lines 387–388)
                dtc = dtc - _DTC_SFAC * S * deldst
            else
                # Dst decreasing (main phase intensification): Equation (8).
                #   dTc₁ = α × dTc₀ + S × [Dst₁ - β × Dst₀]
                # (DTCMAKEDR lines 390–391)
                dtc = _DTC_ALPHA * dtc + S * (dst_curr - _DTC_BETA * dst_prev)
            end

            # No dTc floor during main phase (per Fortran reference).

        elseif k <= recov_end
            # -- Recovery phase: Equation (12) -- #
            #   dTc₁ = dTc₀ + 0.13 × Dst₁  (Dst at integration time = k − lag)
            # (DTCMAKEDR lines 401–403)
            dtc = dtc + _DTC_RECOVERY_SLOPE * vdst[k_lag]

            # Terminate storm if dTc goes negative (DTCMAKEDR April 2012, lines 407–414).
            if dtc < 0.0
                dtc = 0.0
                vdtc[k] = dtc
                _restore_baseline!(vdtc, vbaseline, k + 1, end_idx)
                return nothing
            end

        else
            # -- Late recovery phase: Equation (13) -- #
            # Dst derivative at integration time (DTCMAKEDR lines 426–427).
            deldst = vdst[k_lag] - vdst[k_lag_prev]

            if deldst < 0.0
                # Dst dipping during late recovery: use main phase slope S
                # (DTCMAKEDR line 430: IF (DELDST.LT.0.D0) DERIV = SLPMAIN).
                dtc = dtc + S * deldst
            else
                # Dst recovering: use late recovery slope -2.5
                # (DTCMAKEDR lines 428–429).
                dtc = dtc + _DTC_LATE_RECOVERY_SLOPE * deldst
            end

            # Terminate storm if dTc goes negative (DTCMAKEDR April 2012, lines 436–443).
            if dtc < 0.0
                dtc = 0.0
                vdtc[k] = dtc
                _restore_baseline!(vdtc, vbaseline, k + 1, end_idx)
                return nothing
            end
        end

        vdtc[k] = dtc
    end

    return nothing
end
