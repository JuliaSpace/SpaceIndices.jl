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
# Kyoto publishes provisional data with a multi-month lag, so hitting a missing month is the
# normal stopping condition — not an error.
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
            catch
                done = true
                break
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

During geomagnetic storms (Dst < -75 nT), the temperature change is integrated using the
differential equations from Burke et al. as extended by Bowman et al. (2008):
  - **Main phase**: Eq. (8)/(10) with storm-magnitude-dependent slope S
  - **Recovery**: Eq. (12) with τ₁=∞, τ₂=1, S=0.13
  - **Late recovery**: Eq. (13) with S=-2.5

During non-storm periods, dTc is the Jacchia 1970 ap-based temperature if Celestrak is
initialized, or 0 otherwise.

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
                    if !isnothing(m)
                        year  = parse(Int, m.captures[1])
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
temperature increment via `_ap_to_dtc`. Values above ap=50 produce a capped dTc=148 K
per JB2008 convention.

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
# Implements the geomagnetic storm temperature model from:
#   Bowman, B.R., et al., "A New Empirical Thermospheric Density Model JB2008 Using New
#   Solar and Geomagnetic Indices," AIAA 2008-6438, 2008.
#
# The algorithm detects storms (Dst < -75 nT) and integrates an exospheric temperature
# change (dTc) through four phases:
#   1. Main phase: temperature rises as ring current intensifies
#   2. Sub-storm correction: handles temporary Dst recoveries during main phase
#   3. Recovery phase: fast temperature decay after Dst minimum
#   4. Late recovery phase: slow temperature decay until storm end
#
# Outside of storms, dTc is set to the Jacchia 1970 ap-based temperature (if Celestrak is
# initialized) or 0 (if not). The ap-based baseline also provides the initial condition at
# storm commencement, matching the JB2008 reference implementation.
############################################################################################

# -- Non-storm dTc baseline (JB2008 DTCMAKEDR convention) -------------------------------- #

# Standard ap index values (quantized per NOAA/IAGA convention).
# The ap index only takes these discrete values.
const _AP_TABLE = Float64[
    0, 2, 3, 4, 5, 6, 7, 9, 12, 15, 18, 22, 27, 32, 39, 48,
    56, 67, 80, 94, 111, 132, 154, 179, 207, 236, 300, 400,
]

# Corresponding dTc values [K] from the JB2008 DTCMAKEDR program.
# These are the non-storm exospheric temperature increments used in DTCFILE.TXT,
# derived from Jacchia's 1970 geomagnetic activity equation as implemented in
# the JB2008 reference code. Values verified against DTCFILE.TXT for quiet periods.
#
# Per the JB2008 paper (Bowman et al., 2008, Section V.B): "if ap > 50, a value of
# 50 is used for the dTc" — meaning ap values above 50 are capped and produce dTc=148 K
# (the value at ap=50).
const _DTC_TABLE = Float64[
    0, 17, 24, 31, 38, 44, 50, 60, 74, 85, 94, 105, 115, 124, 135, 146,
    148, 148, 148, 148, 148, 148, 148, 148, 148, 148, 148, 148,
]

# Jacchia 1970 lag: the 3-hour ap value is taken from 6.7 hours earlier.
const _DTC_AP_LAG_HOURS = 6.7

"""
    _ap_to_dtc(ap::Float64) -> Float64

Look up the non-storm dTc [K] for a given 3-hour ap index value using the JB2008
DTCMAKEDR lookup table. Since the ap index is quantized to standard values, this
performs a nearest-neighbor lookup (with linear interpolation for any non-standard
values that may appear).
"""
function _ap_to_dtc(ap::Float64)
    ap <= 0.0 && return 0.0
    ap >= 400.0 && return _DTC_TABLE[end]
    # Find the bracketing interval and linearly interpolate.
    for i in 1:(length(_AP_TABLE) - 1)
        if ap <= _AP_TABLE[i + 1]
            t = (ap - _AP_TABLE[i]) / (_AP_TABLE[i + 1] - _AP_TABLE[i])
            return _DTC_TABLE[i] + t * (_DTC_TABLE[i + 1] - _DTC_TABLE[i])
        end
    end
    return _DTC_TABLE[end]
end

# -- Constants for the dTc computation -------------------------------------------------- #

# Temperature relaxation time constant τ₁ [hours].
const _DTC_TAU1 = 6.5

# Dst relaxation time constant τ₂ [hours].
const _DTC_TAU2 = 7.7

# Storm detection threshold [nT].
const _DTC_STORM_THRESHOLD = -75.0

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

# -- Storm structure -------------------------------------------------------------------- #

struct _DstStormEvent
    start_idx::Int           # Index of storm commencement
    min_idx::Int             # Index of Dst minimum (end of main phase)
    slope_change_idx::Int    # Index where recovery transitions to late recovery
    end_idx::Int             # Index of storm end
    dst_min::Float64         # Minimum Dst value during the storm [nT]
end

# -- Main entry point ------------------------------------------------------------------- #

"""
    _compute_dtc_from_dst(vdst, vbaseline) -> Vector{Float64}
    _compute_dtc_from_dst(vdst)            -> Vector{Float64}

Compute the exospheric temperature change dTc [K] from an hourly Dst time series using the
JB2008 storm algorithm. Returns a vector of dTc values the same length as `vdst`.

If `vbaseline` is provided (same length as `vdst`), it supplies the Jacchia 1970 ap-based
temperature for each hour. This is used as:
  - The dTc value during non-storm periods.
  - The initial condition at storm commencement.

If omitted, the baseline is 0 everywhere (storm-only mode).

The algorithm is a two-pass procedure:
  1. Detect all storm events in the Dst time series.
  2. Integrate dTc through each storm using the appropriate phase equations.

For multi-storm sequences where one storm begins before the previous one has fully
recovered, the dTc is carried forward (not reset to zero).
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

        _integrate_storm_dtc!(vdtc, vdst, storm, initial_dtc)
    end

    return vdtc
end

# -- Storm detection -------------------------------------------------------------------- #

"""
    _detect_dst_storms(vdst::Vector{Float64}) -> Vector{_DstStormEvent}

Scan the hourly Dst time series and return a vector of detected storm events. A storm is
defined as a period where Dst drops below $(_DTC_STORM_THRESHOLD) nT.
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

        # Storm integration begins at the trigger (first Dst < threshold). Before this
        # point the Jacchia 1970 baseline provides the dTc value.
        start_idx = i

        # Find the Dst minimum (main phase end).
        min_idx, dst_min = _find_storm_minimum(vdst, i, n)

        # Find the recovery slope change (search up to 72 hours past minimum).
        slope_change_idx = _find_slope_change(vdst, min_idx, n)

        # Find the storm end (search based on estimated duration from minimum).
        end_idx = _find_storm_end(vdst, min_idx, dst_min, slope_change_idx, n)

        push!(storms, _DstStormEvent(start_idx, min_idx, slope_change_idx, end_idx, dst_min))

        # Resume scanning after this storm.
        i = end_idx + 1
    end

    return storms
end

"""
    _find_storm_minimum(vdst, trigger_idx, n) -> (min_idx, dst_min)

Scan forward from the trigger point to find the global Dst minimum within the storm.
The main phase is considered over when Dst has been rising for 12+ consecutive hours and
has recovered by at least 30% of the minimum magnitude.
"""
function _find_storm_minimum(vdst::Vector{Float64}, trigger_idx::Int, n::Int)
    min_idx = trigger_idx
    min_val = vdst[trigger_idx]

    # Track how long Dst has been above the current minimum — once it has risen
    # significantly for many consecutive hours, the main phase is over.
    consecutive_rise = 0

    for k in (trigger_idx + 1):min(n, trigger_idx + _DTC_MAX_STORM_SCAN)
        if vdst[k] <= min_val
            min_val = vdst[k]
            min_idx = k
            consecutive_rise = 0
        else
            consecutive_rise += 1
        end

        # The main phase is over when Dst has been rising for 12+ hours AND has recovered
        # by at least 30% of the minimum magnitude.
        if consecutive_rise >= 12 && (vdst[k] - min_val) > abs(min_val) * 0.3
            break
        end
    end

    return min_idx, min_val
end

"""
    _find_slope_change(vdst, min_idx, n) -> Int

After the Dst minimum, find the index where the recovery slope changes from fast (early
recovery) to slow (late recovery). This is detected as the point where Dst has recovered
to approximately 50% of its minimum value, or 24 hours after the minimum — whichever
comes first.
"""
function _find_slope_change(vdst::Vector{Float64}, min_idx::Int, n::Int)
    min_val = vdst[min_idx]
    threshold = min_val * 0.5  # e.g., -50 nT when min is -100 nT

    for k in (min_idx + 1):min(n, min_idx + 72)
        if vdst[k] >= threshold
            return k
        end
    end

    # Default: 24 hours after the minimum.
    return min(n, min_idx + 24)
end

"""
    _find_storm_end(vdst, min_idx, dst_min, slope_change_idx, n) -> Int

Determine the storm end point. The storm ends when Dst rises above $(_DTC_STORM_THRESHOLD)
nT, or after an estimated duration based on storm magnitude — whichever comes first.
"""
function _find_storm_end(
    vdst::Vector{Float64},
    min_idx::Int,
    dst_min::Float64,
    slope_change_idx::Int,
    n::Int,
)
    # Empirical duration estimate: larger storms last longer.
    # Clamped between 24 hours (minor storms) and 168 hours (7 days, extreme storms).
    estimated_hours = clamp(round(Int, -dst_min * 0.4), 24, 168)
    max_end = min(n, min_idx + estimated_hours)

    for k in slope_change_idx:max_end
        if vdst[k] >= _DTC_STORM_THRESHOLD
            return k
        end
    end

    return max_end
end

# -- dTc integration -------------------------------------------------------------------- #

"""
    _dtc_slope(dst_min::Float64) -> Float64

Compute the storm main phase slope S as a function of the storm Dst minimum. This is
Equation (10) from JB2008:

    S = -1.5050×10⁻⁵ × DstMIN² - 1.0604×10⁻² × DstMIN - 3.20

For very large storms (DstMIN < -450 nT), S is capped at -1.40.
"""
function _dtc_slope(dst_min::Float64)
    if dst_min < -450.0
        return -1.40
    end
    return -1.5050e-5 * dst_min^2 - 1.0604e-2 * dst_min - 3.20
end

"""
    _integrate_storm_dtc!(vdtc, vdst, storm, initial_dtc) -> Nothing

Integrate the exospheric temperature change through a single storm event, writing the
results into `vdtc`. The integration follows the JB2008 algorithm:

  - **Main phase** (start → min): Equation (8) with slope S from Equation (10).
    When Dst temporarily increases (substorms), Equation (11) is used instead.
  - **Recovery** (min → slope_change): Equation (12) — `dTc₁ = dTc₀ + 0.13 × Dst₁`
  - **Late recovery** (slope_change → end): Equation (13) — `dTc₁ = dTc₀ - 2.5(Dst₁-Dst₀)`

A main-phase lag is applied to the Dst input:
  - 0 hours for large storms (DstMIN < -350 nT)
  - 1 hour for moderate storms (-350 ≤ DstMIN < -250 nT)
  - 2 hours for minor storms (DstMIN ≥ -250 nT)

dTc is clamped to be non-negative at every step.
"""
function _integrate_storm_dtc!(
    vdtc::Vector{Float64},
    vdst::Vector{Float64},
    storm::_DstStormEvent,
    initial_dtc::Float64,
)
    (; start_idx, min_idx, slope_change_idx, end_idx, dst_min) = storm

    # Compute the main phase slope.
    S = _dtc_slope(dst_min)

    # Determine the main phase lag [hours].
    lag = if dst_min < -350.0
        0
    elseif dst_min < -250.0
        1
    else
        2
    end

    dtc = initial_dtc

    for k in (start_idx + 1):end_idx
        if k <= min_idx
            # -- Main phase: Equation (8) with substorm correction (11) -- #
            k_curr = max(1, k - lag)
            k_prev = max(1, k - 1 - lag)
            dst_curr = vdst[k_curr]
            dst_prev = vdst[k_prev]

            if dst_curr <= dst_prev
                # Dst decreasing (main phase intensification): Equation (8).
                #   dTc₁ = α × dTc₀ + S × [Dst₁ - β × Dst₀]
                # S is negative, and [Dst₁ - β×Dst₀] is typically negative when Dst is
                # dropping, so the product S×[...] is positive → dTc increases.
                dtc = _DTC_ALPHA * dtc + S * (dst_curr - _DTC_BETA * dst_prev)
            else
                # Dst increasing during main phase (substorm recovery): Equation (11).
                #   dTc₁ = dTc₀ - SFAC × S × (Dst₁ - Dst₀)
                # S is negative, (Dst₁ - Dst₀) > 0, so -SFAC×S×(...) > 0 → dTc continues
                # to increase (the thermosphere doesn't cool during brief substorms).
                dtc = dtc - _DTC_SFAC * S * (dst_curr - dst_prev)
            end

        elseif k <= slope_change_idx
            # -- Recovery phase: Equation (12) -- #
            #   dTc₁ = dTc₀ + 0.13 × Dst₁
            # Dst₁ is negative → dTc decreases (temperature recovering).
            dtc = dtc + _DTC_RECOVERY_SLOPE * vdst[k]

        else
            # -- Late recovery phase: Equation (13) -- #
            #   dTc₁ = dTc₀ + S_late × (Dst₁ - Dst₀)
            # S_late = -2.5. Dst is recovering (Dst₁ > Dst₀), so (Dst₁-Dst₀) > 0
            # and S_late×(...) < 0 → dTc decreases.
            dtc = dtc + _DTC_LATE_RECOVERY_SLOPE * (vdst[k] - vdst[k - 1])
        end

        # dTc cannot be negative (the thermosphere doesn't cool below the quiet-time
        # baseline from this mechanism alone).
        dtc = max(0.0, dtc)

        vdtc[k] = dtc
    end

    return nothing
end
