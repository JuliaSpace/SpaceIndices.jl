## Description #############################################################################
#
# Space index set: Dst (Disturbance Storm Time)
# Source: WDC for Geomagnetism, Kyoto University
# URL: https://wdc.kugi.kyoto-u.ac.jp/dstdir/
#
# The Dst (Disturbance Storm Time) index is an hourly measure of the equatorial geomagnetic
# disturbance level. It represents the axially symmetric disturbance magnetic field at the
# dipole equator on the Earth's surface, measured in nanoTesla (nT). Negative Dst values
# indicate geomagnetic storms.
#
# Data categories:
#   - Final:       1957/01 - 2020/12 (definitive, quality-checked)
#   - Provisional: 2021/01 - present (visually screened for artificial noise)
#   - Real-time:   Where provisional ends - present (unverified quicklook, for monitoring)
#
# The data is downloaded as monthly HTML pages from the Kyoto WDC. Each page contains 24
# hourly Dst values for every day in the month.
#
## References ##############################################################################
#
# [1] Sugiura, M. (1964), Hourly values of equatorial Dst for the IGY, Ann. Int. Geophys.
#     Year, 35, 9-45.
#
# [2] Bowman, B.R., Tobiska, W.K., Marcos, F.A., Huang, C.Y., Lin, C.S., and Burke, W.J.
#     (2008), "A New Empirical Thermospheric Density Model JB2008 Using New Solar and
#     Geomagnetic Indices," AIAA/AAS Astrodynamics Specialist Conference, AIAA 2008-6438.
#
# [3] Bowman, B.R. (2008), DTCMAKEDR_AUTO.f — Fortran reference implementation of the dTc
#     storm-time exospheric temperature correction algorithm for JB2008. Revised by D.
#     Bouwer (2011–2023) and S. Mutschler (2023).
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
    "JANUARY"   => 1,
    "FEBRUARY"  => 2,
    "MARCH"     => 3,
    "APRIL"     => 4,
    "MAY"       => 5,
    "JUNE"      => 6,
    "JULY"      => 7,
    "AUGUST"    => 8,
    "SEPTEMBER" => 9,
    "OCTOBER"   => 10,
    "NOVEMBER"  => 11,
    "DECEMBER"  => 12
)

############################################################################################
#                                        Structure                                         #
############################################################################################

"""
    struct Dst

Store the Dst (Disturbance Storm Time) hourly index together with the exospheric
temperature variation derived from it.

# Fields

- `vjd::Vector{Float64}`: Julian dates of the hourly samples.
- `vdst::Vector{Float64}`: Dst values [nT] at each sample.
- `vdtc::Vector{Float64}`: Exospheric temperature variation [K] caused by geomagnetic
    activity, computed from `vdst` using the JB2008 storm algorithm.
"""
struct Dst <: SpaceIndexSet
    vjd::Vector{Float64}
    vdst::Vector{Float64}
    vdtc::Vector{Float64}
end

############################################################################################
#                                           API                                            #
############################################################################################

auto_init(::Type{Dst}) = false

function expiry_periods(::Type{Dst})
    vfiles = filenames(Dst)
    vexpiry_periods = DatePeriod[]
    sizehint!(vexpiry_periods, length(vfiles))

    for file in vfiles
        file_expiry_period = if startswith(file, "dst_final")
            Year(100)
        elseif startswith(file, "dst_prov")
            Month(1)
        else
            Day(0)
        end

        push!(vexpiry_periods, file_expiry_period)
    end

    return vexpiry_periods
end

function filenames(::Type{Dst})
    current_dt = now()
    current_year = Dates.year(current_dt)
    current_month = Dates.month(current_dt)

    vfilenames = String[]
    sizehint!(vfilenames, (current_year - _DST_FINAL_START_YEAR + 1) * 12)

    # == Final Dst Files ===================================================================

    for year in _DST_FINAL_START_YEAR:_DST_FINAL_END_YEAR
        for month in 1:12
            push!(vfilenames, "dst_final_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    # Now, we need to check what is the latest month for the provisional files, and we need
    # to add the real-time files until the current month.
    r = _get_latest_month_with_provisional_data()

    # If we could not obtain this information, we only download the final files.
    isnothing(r) && return vfilenames

    last_prov_year, last_prov_month = r

    # == Provisional Dst files =============================================================

    for year in _DST_PROV_START_YEAR:last_prov_year
        for month in 1:12
            ((year == last_prov_year) && (month == last_prov_month)) && break

            push!(vfilenames, "dst_prov_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    # == Real-Time Dst files ===============================================================

    for year in last_prov_year:current_year
        start_month = (year == last_prov_year) ? last_prov_month + 1 : 1

        for month in start_month:12
            ((year == current_year) && (month == current_month)) && break
            push!(vfilenames, "dst_realtime_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    return vfilenames
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

    # Extend the Dst series with quiet-time values (Dst = 0) beyond the last observation
    # out to 5 days past the current time. This ensures:
    #   - Any storm in progress at the data boundary recovers naturally through the
    #     integral (the algorithm needs Dst = 0 to complete recovery/late-recovery phases).
    #   - Queries for near-future times return physically consistent dTc values.
    if !isempty(vjd)
        jd_now  = datetime2julian(now(Dates.UTC))
        jd_end  = max(last(vjd), jd_now) + 5.0  # 5 days of padding.
        jd_step = 1.0 / 24.0                    # 1-hour step.
        jd_next = last(vjd) + jd_step

        while jd_next <= jd_end
            push!(vjd,  jd_next)
            push!(vdst, 0.0)
            jd_next += jd_step
        end
    end

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

function urls(::Type{Dst})
    vfiles = filenames(Dst)
    vurls = String[]
    sizehint!(vurls, length(vfiles))

    for file in vfiles
        if startswith(file, "dst_final")
            year = file[11:14]
            month = file[16:17]
            push!(vurls, "https://wdc.kugi.kyoto-u.ac.jp/dst_final/$(year)$(month)/index.html")
        elseif startswith(file, "dst_prov")
            year = file[10:13]
            month = file[15:16]
            push!(vurls, "https://wdc.kugi.kyoto-u.ac.jp/dst_provisional/$(year)$(month)/index.html")
        elseif startswith(file, "dst_realtime")
            year = file[14:17]
            month = file[19:20]
            push!(vurls, "https://wdc.kugi.kyoto-u.ac.jp/dst_realtime/$(year)$(month)/index.html")
        else
            @warn "Unrecognized DST filename format: $file"
        end
    end

    return vurls
end

@register Dst

"""
    space_index(::Val{:Dst}, jd::Number) -> Float64

Get the Dst (Disturbance Storm Time) index [nT] at the Julian Day `jd`.

The Dst index measures the intensity of the globally symmetric part of the equatorial
ring current. Negative values indicate geomagnetic storms. Values are linearly
interpolated between hourly observations.

For times beyond the last available observation, the Dst series is extended with quiet-time
values (0 nT) so that any in-progress storm recovery completes naturally through the dTc
integral.

# Reference

- **[1]** WDC for Geomagnetism, Kyoto University. https://wdc.kugi.kyoto-u.ac.jp/dstdir/
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

- **Main phase**: Eq. (8)/(10) with storm-magnitude-dependent slope S; Dst clamped to ≤ 0,
    no dTc floor.
- **Recovery**: Eq. (12) with S = 0.13; storm terminates if dTc < 0.
- **Late recovery**: Eq. (13) with S = -2.5 (uses main-phase S when Dst dips).

During non-storm periods, dTc is the Jacchia 1970 ap-based temperature (ap capped at 50)
if Celestrak is initialized, or 0 otherwise.

For times beyond the last available Dst observation, the Dst series is extended with
quiet-time values (0 nT) so that any in-progress storm recovery completes naturally through
the integral. In quiet extended regions the dTc converges to the ap baseline.

# Reference

- **[1]** Bowman, B.R., et al., "A New Empirical Thermospheric Density Model JB2008 Using
    New Solar and Geomagnetic Indices," AIAA 2008-6438, 2008.
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

"""
    _get_latest_month_with_provisional_data() -> Union{Tuple{Int, Int}, Nothing}

Determine the latest year and month for which Kyoto WDC has published provisional Dst
data. The function first downloads the index page
`https://wdc.kugi.kyoto-u.ac.jp/dst_provisional/` to a temporary file and scans it for
`YYYYMM` references.

If the index page cannot be downloaded or no valid month is found in it, the function
falls back to probing the monthly pages in reverse, starting from the current month and
walking back to the start of the provisional period, returning the first month that
downloads successfully.

# Returns

- `Union{Tuple{Int, Int}, Nothing}`: Tuple `(year, month)` with the latest provisional
    month, or `nothing` if no provisional month could be determined.
"""
function _get_latest_month_with_provisional_data()
    url = "https://wdc.kugi.kyoto-u.ac.jp/dst_provisional/"
    filepath = tempname() * ".html"

    try
        download(url, filepath)
    catch err
        @debug "Failed to download provisional Dst index page: $err"
    end

    content = nothing
    if isfile(filepath)
        try
            content = read(filepath, String)
        catch err
            @debug "Failed to read the downloaded Dst index page: $err"
        finally
            rm(filepath; force = true)
        end
    end

    latest_year  = 0
    latest_month = 0

    if !isnothing(content)
        for m in eachmatch(r"(\d{4})(\d{2})/?\"?\s*>?", content)
            year_str  = m.captures[1]
            month_str = m.captures[2]

            (isnothing(year_str) || isnothing(month_str)) && continue

            year  = tryparse(Int, year_str)
            month = tryparse(Int, month_str)

            (isnothing(year) || isnothing(month)) && continue
            (year < _DST_PROV_START_YEAR || month < 1 || month > 12) && continue

            if (year > latest_year) || (year == latest_year && month > latest_month)
                latest_year  = year
                latest_month = month
            end
        end

        (latest_year != 0) && return latest_year, latest_month
    end

    # Fallback: probe monthly pages in reverse from the current month back to
    # `_DST_PROV_START_YEAR`, stopping at the first month that returns successfully. This
    # kicks in when the index page layout changes and the regex above no longer matches any
    # YYYYMM links.
    if latest_year == 0
        current_dt = now()
        year  = Dates.year(current_dt)
        month = Dates.month(current_dt)

        while year > _DST_PROV_START_YEAR || (year == _DST_PROV_START_YEAR && month >= 1)
            ym = string(year) * lpad(month, 2, '0')
            probe = tempname() * ".html"

            ok = true
            try
                download(
                    "https://wdc.kugi.kyoto-u.ac.jp/dst_provisional/$(ym)/index.html",
                    probe,
                )
            catch
                ok = false
            finally
                rm(probe; force = true)
            end

            if ok
                latest_year  = year
                latest_month = month
                break
            end

            month -= 1
            if month < 1
                month = 12
                year -= 1
            end
        end
    end

    latest_year == 0 && return nothing

    return latest_year, latest_month
end

"""
    _parse_dst_html!(
        vjd::Vector{Float64},
        vdst::Vector{Float64},
        filepath::String
    ) -> Nothing

Parse the Dst HTML file `filepath` from the Kyoto WDC and append the hourly Julian dates to
`vjd` and the corresponding Dst values to `vdst`.

The Kyoto WDC HTML pages embed Dst data in a `<pre>` block with one line per day. Each data
line contains a day number followed by 24 hourly values. Adjacent negative values can be
packed without spaces (e.g. `-235-217-225`), so the function uses a regex to extract all
integers from each line and treats lines with up to 25 integers (1 day + 24 values) as data.
The fill value `9999`, used by Kyoto for hours that are not yet available in real-time data,
is ignored.
"""
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
        # A complete DST data line has 25 integers: 1 day + 24 hourly values.
        # Partial lines (e.g. current day in real-time data) may have fewer because
        # Kyoto fills not-yet-available hours with 9999 which can merge with adjacent
        # values in the fixed-width format.
        int_matches = collect(eachmatch(r"-?\d+", clean))
        (2 <= length(int_matches) <= 25) || continue

        try
            day = parse(Int, int_matches[1].match)
            (1 <= day <= 31) || continue

            # Validate the date against the calendar.
            day > Dates.daysinmonth(year, month) && continue

            n_hours = min(length(int_matches) - 1, 24)
            for h in 0:(n_hours - 1)
                dst_val = parse(Float64, int_matches[h + 2].match)

                # Kyoto real-time pages use 9999 as a fill value for hours not yet
                # available. Skip any value with |Dst| >= 9999 (real Dst never exceeds
                # a few hundred nT).
                abs(dst_val) >= 9999.0 && continue

                jd = datetime2julian(DateTime(year, month, day, h, 0, 0))
                push!(vjd,  jd)
                push!(vdst, dst_val)
            end
        catch
            continue
        end
    end
end

"""
    _deduplicate_dst!(vjd::Vector{Float64}, vdst::Vector{Float64}) -> Nothing

Remove duplicate Julian dates from `vjd` in-place, keeping the last `vdst` value for each
date. The function assumes that `vjd` is sorted in ascending order and resizes both
vectors to the deduplicated length.
"""
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

# == Non-storm dTc Baseline from ap Data ===================================================

"""
    _build_ap_baseline(vjd::Vector{Float64}, ap_source::Symbol) -> Union{Vector{Float64}, Nothing}

Build the hourly Jacchia 1970 dTc baseline from ap index data for the Julian dates in `vjd`.
Returns `nothing` if the required index set is not initialized, in which case the caller
falls back to a zero baseline.

For each hour, the ap value from 6.7 hours earlier is looked up and converted to a
temperature increment via `_ap_to_dtc` (Jacchia 1970 formula with ap capped at 50).

# Arguments

- `vjd::Vector{Float64}`: Vector of Julian dates of the Dst time series.
- `ap_source::Symbol`: Source of the ap index. Use `:celestrak` for the 3-hour ap from
    Celestrak, or `:hpo` for the hourly ap60 from the GFZ Hpo index.
"""
function _build_ap_baseline(vjd::Vector{Float64}, ap_source::Symbol)
    if ap_source === :celestrak
        return _build_baseline_celestrak(vjd)
    elseif ap_source === :hpo
        return _build_baseline_hpo(vjd)
    else
        throw(ArgumentError("Unknown ap_source: $ap_source"))
    end
end

# -- Celestrak (3-hour ap) -----------------------------------------------------------------

"""
    _build_baseline_celestrak(vjd::Vector{Float64}) -> Union{Vector{Float64}, Nothing}

Build the dTc baseline using the 3-hour ap values from the `Celestrak` index set evaluated
at the Julian dates `vjd` (with a 6.7-hour lag applied per the Jacchia 1970 model). Returns
`nothing` if `Celestrak` is not initialized.
"""
function _build_baseline_celestrak(vjd::Vector{Float64})
    local celestrak
    try
        celestrak = @object(Celestrak)
    catch
        return nothing
    end

    vbaseline = Float64[]
    sizehint!(vbaseline, length(vjd))

    # Celestrak stores daily records with 8 three-hourly ap values per day
    # (0-3h, 3-6h, ..., 21-24h).
    ap_jd     = celestrak.vjd
    ap_tuples = celestrak.vap

    for i in eachindex(vjd)
        jd_lagged = vjd[i] - _DTC_AP_LAG_HOURS / 24.0
        ap_val = _lookup_3h_ap(ap_jd, ap_tuples, jd_lagged)
        push!(vbaseline, _ap_to_dtc(ap_val))
    end

    return vbaseline
end

"""
    _lookup_3h_ap(ap_jd::Vector{Float64}, ap_tuples::Vector{NTuple{8, Float64}}, jd::Float64) -> Float64

Look up the 3-hour ap value at the Julian date `jd` from the Celestrak daily ap data,
where `ap_jd` contains the Julian dates at the start of each day and `ap_tuples` contains
the 8 three-hourly ap values for each day. Returns the quiet-time default `4.0` if `jd`
falls outside the available range.
"""
function _lookup_3h_ap(
    ap_jd::Vector{Float64},
    ap_tuples::Vector{NTuple{8, Float64}},
    jd::Float64
)
    idx = searchsortedlast(ap_jd, jd)

    (idx < 1 || idx > length(ap_jd)) && return 4.0  # Quiet-time default if out of range.

    fraction_of_day = jd - ap_jd[idx]
    hour_of_day = fraction_of_day * 24.0
    block = clamp(floor(Int, hour_of_day / 3.0) + 1, 1, 8)

    return ap_tuples[idx][block]
end

# -- Hpo (hourly ap60) ---------------------------------------------------------------------

"""
    _build_baseline_hpo(vjd::Vector{Float64}) -> Union{Vector{Float64}, Nothing}

Build the dTc baseline using the hourly ap60 values from the `Hpo` index set evaluated at
the Julian dates `vjd` (with a 6.7-hour lag applied per the Jacchia 1970 model). Returns
`nothing` if `Hpo` is not initialized.
"""
function _build_baseline_hpo(vjd::Vector{Float64})
    local hpo
    try
        hpo = @object(Hpo)
    catch
        return nothing
    end

    vbaseline = Float64[]
    sizehint!(vbaseline, length(vjd))

    # Hpo stores daily records with 24 hourly ap60 values per day (0-1h, 1-2h, ..., 23-24h).
    ap_jd     = hpo.vjd
    ap_tuples = hpo.vap60

    for i in eachindex(vjd)
        jd_lagged = vjd[i] - _DTC_AP_LAG_HOURS / 24.0
        ap_val = _lookup_hourly_ap(ap_jd, ap_tuples, jd_lagged)
        push!(vbaseline, isnan(ap_val) ? 0.0 : _ap_to_dtc(ap_val))
    end

    return vbaseline
end

"""
    _lookup_hourly_ap(
        ap_jd::Vector{Float64},
        ap_tuples::Vector{NTuple{24, Float64}},
        jd::Float64
    ) -> Float64

Look up the hourly ap60 value at the Julian date `jd` from the Hpo daily ap data, where
`ap_jd` contains the Julian dates at the start of each day and `ap_tuples` contains the 24
hourly ap values for each day. Returns the quiet-time default `4.0` if `jd` falls outside
the available range.
"""
function _lookup_hourly_ap(
    ap_jd::Vector{Float64},
    ap_tuples::Vector{NTuple{24, Float64}},
    jd::Float64,
)
    idx = searchsortedlast(ap_jd, jd)

    (idx < 1 || idx > length(ap_jd)) && return 4.0  # Quiet-time default if out of range.

    fraction_of_day = jd - ap_jd[idx]
    hour_of_day = fraction_of_day * 24.0
    block = clamp(floor(Int, hour_of_day) + 1, 1, 24)

    return ap_tuples[idx][block]
end

# == dTc Computation from Dst (JB2008 Storm Algorithm) =====================================
#
# Implements the geomagnetic storm temperature model from the DTCMAKEDR Fortran reference
# code by Bruce R. Bowman (June 2008, rev. G May 2017), distributed with:
#
#     Bowman, B.R., et al., "A New Empirical Thermospheric Density Model JB2008 Using New
#     Solar and Geomagnetic Indices," AIAA 2008-6438, 2008.
#
# The algorithm detects storms (Dst < -75 nT, ΔDst ≥ 50 nT) and integrates an exospheric
# temperature change (dTc) through four phases:
#
# 1. Main phase: temperature rises as ring current intensifies (Eq. 8/10/11).
# 2. Sub-storm correction: handles temporary Dst recoveries during main phase (Eq. 11).
# 3. Recovery phase: fast temperature decay after Dst minimum (Eq. 12).
# 4. Late recovery phase: slow temperature decay until storm end (Eq. 13).
#
# Key behaviors matched to the Fortran reference (DTCMAKEDR_AUTO.f):
#
# - Dst values clamped to ≤ 0 during main phase (SSC protection, lines 382–383).
# - No dTc floor during main phase; floor only in recovery/late recovery (Apr 2012 rev).
# - Storm terminated when dTc < 0 in recovery/late recovery → ap baseline (lines 407–414).
# - Late recovery uses main-phase slope S when Dst dips (line 430).
# - ap capped at 50 before Jacchia 1970 equation (line 251).
# - Slope change detected via centered Dst derivative < 100 nT/day (DSTREC).
# - Storm end duration = 0.0075 × ΔDst days with flat-bottom extension (DSTEND).
#
# Outside of storms, dTc is set to the Jacchia 1970 ap-based temperature (if Celestrak is
# initialized) or 0 (if not). The ap-based baseline also provides the initial condition at
# storm commencement, matching the JB2008 reference implementation.

# -- Non-storm dTc baseline (JB2008 DTCMAKEDR convention) ----------------------------------

# Jacchia 1970 lag: the 3-hour ap value is taken from 6.7 hours earlier.
const _DTC_AP_LAG_HOURS = 6.7

"""
    _ap_to_dtc(ap::Float64) -> Float64

Compute the non-storm dTc [K] from the 3-hour ap index value `ap` using the Jacchia 1970
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

# -- Constants for the dTc computation -----------------------------------------------------

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

# -- Storm Structure -----------------------------------------------------------------------

"""
    struct _DstStormEvent

Describe a single geomagnetic storm event detected in a Dst time series.

# Fields

- `start_idx::Int`: Index of the storm commencement (Dst maximum before the drop).
- `min_idx::Int`: Index of the Dst minimum (end of the main phase).
- `slope_change_idx::Int`: Index where the recovery transitions to late recovery.
- `end_idx::Int`: Index of the storm end.
- `dst_min::Float64`: Minimum Dst value during the storm [nT].
- `dst_max::Float64`: Dst value at the storm commencement [nT].
"""
struct _DstStormEvent
    start_idx::Int
    min_idx::Int
    slope_change_idx::Int
    end_idx::Int
    dst_min::Float64
    dst_max::Float64
end

# -- Main Entry Point ----------------------------------------------------------------------

"""
    _compute_dtc_from_dst(
        vdst::Vector{Float64},
        vbaseline::Union{Vector{Float64}, Nothing} = nothing
    ) -> Vector{Float64}

Compute the exospheric temperature change dTc [K] from the hourly Dst time series `vdst`
using the JB2008 storm algorithm (DTCMAKEDR). The result has the same length as `vdst`.

If `vbaseline` is provided (same length as `vdst`), it supplies the Jacchia 1970 ap-based
temperature for each hour, which is used as the dTc value during non-storm periods and as
the initial condition at storm commencement. If `vbaseline` is `nothing`, the baseline is
0 everywhere (storm-only mode).

The algorithm is a two-pass procedure:

1. Detect all storm events in the Dst time series.
2. Integrate dTc through each storm using the appropriate phase equations.

When dTc goes negative during recovery or late recovery, the storm is terminated early and
the ap-based baseline is restored (matching DTCMAKEDR April 2012 revision).
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

    # == Pass 1: Detect All Storm Events ===================================================

    storms = _detect_dst_storms(vdst)

    # == Pass 2: Integrate dTc for Each Storm ==============================================

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

# -- Storm Detection -----------------------------------------------------------------------

"""
    _detect_dst_storms(vdst::Vector{Float64}) -> Vector{_DstStormEvent}

Scan the hourly Dst time series `vdst` and return a vector of detected storm events.

A storm requires:

- Dst minimum < $(_DTC_STORM_THRESHOLD) nT
- Magnitude ΔDst (max − min) ≥ $(_DTC_STORM_MIN_MAGNITUDE) nT

Based on DSTSTM / DSTBEG / DSTMAX / DSTMIN / DSTREC / DSTEND from DTCMAKEDR.
"""
function _detect_dst_storms(vdst::Vector{Float64})
    n = length(vdst)
    storms = _DstStormEvent[]

    i = 1
    # Track the most recent storm's end_idx so the next storm's backward scan in
    # _find_storm_start cannot cross into the previous storm's window. 0 = no prior
    # storm (start of series). Matches Fortran DSTSTM passing TSTART = TEND of the
    # previous storm to DSTMAX (DTCMAKEDR_AUTO.f lines 582–585, 603–605).
    prev_end_idx = 0
    while i <= n
        # Look for the first point below the storm threshold.
        if vdst[i] >= _DTC_STORM_THRESHOLD
            i += 1
            continue
        end

        # -- Found a storm trigger at index `i`. Determine the full storm profile. -- #

        # Find the storm commencement (Dst maximum) by scanning backward. This is
        # used for the slope calculation and integration start, not for minimum search.
        # The backward scan is bounded by `prev_end_idx + 1` so that a long-recovery
        # storm which re-dips below -75 nT during late recovery cannot re-discover the
        # previous storm's SSC and produce overlapping storm windows.
        start_idx, dst_max = _find_storm_start(
            vdst, i; min_idx_bound = prev_end_idx + 1
        )

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

        push!(
            storms,
            _DstStormEvent(start_idx, min_idx, slope_change_idx, end_idx, dst_min, dst_max)
        )

        # Resume scanning after this storm (end_idx ≥ min_idx ≥ i, so i always advances).
        prev_end_idx = end_idx
        i = end_idx + 1
    end

    # Post-condition: storm windows must be strictly non-overlapping. Overlap would
    # corrupt _integrate_storm_dtc! by re-integrating across an already-resolved range
    # with a different slope, lag, and initial condition (the chaining branch in
    # _compute_dtc_from_dst would silently mask the bug with inflated peaks). Fail
    # loudly if anything upstream regresses.
    for s in 2:length(storms)
        prev = storms[s - 1]
        curr = storms[s]
        if curr.start_idx <= prev.end_idx
            error(
                "Internal invariant violated in _detect_dst_storms: overlapping " *
                "storm windows (storm $(s - 1): [$(prev.start_idx), $(prev.end_idx)], " *
                "storm $s: [$(curr.start_idx), $(curr.end_idx)])."
            )
        end
    end

    return storms
end

"""
    _find_storm_start(vdst::Vector{Float64}, trigger_idx::Int; min_idx_bound=1) -> Tuple{Int, Float64}

Scan backward in `vdst` from the storm trigger index `trigger_idx` (first Dst < -75) to find
the Dst maximum (storm commencement point) and return the tuple `(start_idx, dst_max)`.
Based on DSTMAX from DTCMAKEDR; the scan stops when 6 consecutive points ≥ -40 nT are found
(quiet pre-storm period).

The backward scan is bounded by `min_idx_bound` (default = 1, i.e. start of series).
For the second and later storms in `_detect_dst_storms`, this MUST be set to the
previous storm's `end_idx + 1` so consecutive storm windows cannot share a `start_idx`.
This matches the Fortran DSTMAX `TBEG` argument: DSTSTM passes `TSTART = TEND` of the
previous storm so the backward scan stops at the previous storm boundary
(DTCMAKEDR_AUTO.f lines 582–585, 603–605).
"""
function _find_storm_start(
    vdst::Vector{Float64},
    trigger_idx::Int;
    min_idx_bound::Int = 1,
)
    max_val = vdst[trigger_idx]
    max_idx = trigger_idx
    quiet_count = 0

    for k in (trigger_idx - 1):-1:max(min_idx_bound, trigger_idx - 72)
        val = vdst[k]

        if val > max_val
            max_val = val
            max_idx = k
        end

        # Count consecutive quiet points (≥ -40). Reset if Dst drops below -60.
        if val < -60
            quiet_count = 0
        elseif val >= -40
            quiet_count += 1
        end

        (quiet_count >= 6) && break
    end

    return max_idx, max_val
end

"""
    _find_storm_minimum(vdst::Vector{Float64}, start_idx::Int, n::Int) -> Tuple{Int, Float64}

Scan forward in `vdst` from `start_idx` to find the global Dst minimum, considering at
most `n` samples. Returns the tuple `(min_idx, dst_min)`.

Termination criteria (matching DSTMIN from DTCMAKEDR):

- Recovery of 125 nT from minimum.
- Recovery of 75 nT AND current Dst > -75.
- 2 accumulated points ≥ -40 (after a valid minimum < -75 is found).
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
        (max_since_min > min_val + 125) && break

        # Termination: recovery of 75 nT AND max above -75 (DSTMIN lines 1013–1014).
        ((max_since_min - min_val > 75) && max_since_min > -75.0) && break

        # Termination: 2 accumulated points ≥ -40 after a valid minimum (DSTMIN
        # lines 1021–1023). Points below -40 reset the counter.
        if val < -40.0
            ipts = 0
        end

        if min_val < -75.0
            ipts += 1
        end

        (ipts >= 2) && break
    end

    # If no valid minimum was found, return the start index.
    (min_val > 0.0) && return start_idx, vdst[start_idx]

    return min_idx, min_val
end

"""
    _find_slope_change(vdst::Vector{Float64}, min_idx::Int, end_idx::Int, n::Int) -> Int

After the Dst minimum at `min_idx`, find the index in `vdst` where the recovery slope
changes from fast (early recovery) to slow (late recovery), bounded by `end_idx` and the
total number of samples `n`.

Detection method (matching DSTREC from DTCMAKEDR):

- Compute centered Dst derivative: slope = (Dst[k+1] - Dst[k-1]) / (2 × Δt) [nT/day].
- Slope change detected when slope < 100 nT/day for 3 instances.
- Also stops at 6 accumulated points ≥ -40 (backstop).
"""
function _find_slope_change(vdst::Vector{Float64}, min_idx::Int, end_idx::Int, n::Int)
    dtdst = 1.0 / 24.0  # 1 hour in days
    irec = 0
    ipts = 0

    # Start 2 hours after minimum (DSTREC: TSTEP = TMIN + DTDST, then TSTEP + DTDST).
    for k in (min_idx + 2):min(n - 1, end_idx)
        # Centered derivative (DSTREC line 1064).
        slope = (vdst[k + 1] - vdst[k - 1]) / (2.0 * dtdst)

        if slope < _DTC_SLOPE_LIMIT
            irec += 1
            (irec >= 3) && return k - 1  # DSTREC: TREC = TSTEP - DTDST
        end

        # Backstop: 6 accumulated points ≥ -40 (DSTREC lines 1073–1074).
        if vdst[k] >= -40.0
            ipts += 1
        end

        (ipts >= 6) && break
    end

    # Default: end_idx (DSTREC: TREC = TEND).
    return end_idx
end

"""
    _find_storm_end(
        vdst::Vector{Float64},
        min_idx::Int,
        dst_min::Float64,
        dst_max::Float64,
        n::Int
    ) -> Int

Determine the storm end index in `vdst`, given the storm minimum index `min_idx`, the storm
minimum Dst `dst_min`, the storm maximum Dst `dst_max`, and the total number of samples `n`.
Based on DSTEND from DTCMAKEDR.

1. Extends the minimum forward through flat bottoms (within 15 nT of minimum).
2. Computes the estimated duration: 0.0075 × ΔDst days (where ΔDst = max − min).
3. Steps forward checking for:
    - 6 accumulated points with Dst > -75 nT → storm end.
    - Dst drops by > 75 nT from a local max → new storm (end at local max).
    - Estimated duration reached → storm end.
"""
function _find_storm_end(
    vdst::Vector{Float64},
    min_idx::Int,
    dst_min::Float64,
    dst_max::Float64,
    n::Int
)
    # == Flat Bottom Handling: Extend Minimum Through Points Within 15 nT ==================
    #
    # (DSTEND lines 1109–1121)
    min_ext_idx = min_idx

    for k in (min_idx + 1):min(n, min_idx + _DTC_MAX_STORM_SCAN)
        if vdst[k] > dst_min + 15.0
            min_ext_idx = k - 1
            break
        end

        min_ext_idx = k
    end

    # == Compute Estimated End Time: 0.0075 × ΔDst days (DSTEND line 1124) =================

    deldst = dst_max - dst_min  # Positive (e.g., 0 - (-200) = 200)
    estimated_days = 0.0075 * deldst
    estimated_hours = max(round(Int, estimated_days * 24.0), 6)
    max_end = min(n, min_ext_idx + estimated_hours)

    # -- Step Forward Looking for End Conditions -------------------------------------------
    #
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
        (val - local_max < -75) && return local_max_idx

        # Accumulated points above -75 (DSTEND line 1152).
        if val > _DTC_STORM_THRESHOLD
            ipts += 1
        end

        (ipts >= 6) && return k
    end

    return max_end
end

# -- dTc integration -----------------------------------------------------------------------

"""
    _dtc_slope(dst_min::Float64) -> Float64

Compute the storm main phase slope S as a function of the storm Dst minimum `dst_min`. This
is Equation (10) from JB2008 / DTCMAKEDR line 376:

    S = -1.5050×10⁻⁵ × DstMIN² - 1.0604×10⁻² × DstMIN - 3.20

For very large storms (`dst_min` < -450 nT), S is capped at -1.40.
"""
function _dtc_slope(dst_min::Float64)
    (dst_min < -450) && return -1.40

    return -1.5050e-5 * dst_min^2 - 1.0604e-2 * dst_min - 3.20
end

"""
    _restore_baseline!(
        vdtc::Vector{Float64},
        vbaseline::Union{Vector{Float64}, Nothing},
        from_idx::Int,
        to_idx::Int
    ) -> Nothing

Restore the baseline dTc values in `vdtc` over the index range `from_idx:to_idx`. If
`vbaseline` is `nothing`, the values are set to 0. This is called when a storm is terminated
early because dTc went negative (DTCMAKEDR April 2012 revision).
"""
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

    return nothing
end

"""
    _integrate_storm_dtc!(
        vdtc::Vector{Float64},
        vdst::Vector{Float64},
        vbaseline::Union{Vector{Float64}, Nothing},
        storm::_DstStormEvent,
        initial_dtc::Float64
    ) -> Nothing

Integrate the exospheric temperature change through a single storm event `storm`, writing
the results into `vdtc`. The hourly Dst series is `vdst`, the optional ap-based baseline
is `vbaseline`, and `initial_dtc` is the dTc value at storm commencement. Matches the
DSTDTC subroutine from DTCMAKEDR.

- **Main phase** (start → min+lag): Equation (8) with slope S from Equation (10). Dst
    values are clamped to ≤ 0 to guard against SSC positive spikes. When Dst increases
    (substorms), Equation (11) is used instead. No dTc floor is applied during the main
    phase (per Fortran reference).
- **Recovery** (min+lag → slope_change+lag): Equation (12).
- **Late recovery** (slope_change+lag → end): Equation (13). When Dst dips (ΔDst < 0),
    the main phase slope S is used instead of -2.5.

In recovery and late recovery, if dTc goes negative the storm is terminated early and the
ap-based baseline is restored (DTCMAKEDR April 2012 revision, lines 407–414, 436–443).

The Fortran DTCMAKEDR applies a DELAY as a pure output time shift (lines 345–348, 457–458,
468–477): the integration runs at "integration time" TSTEP with Dst accessed at TSTEP (no
lag), and the output is mapped to time TSTEP + DELAY. This means:

- Output at time T uses Dst from time T − DELAY (uniform lag on ALL phases).
- Phase boundaries in the output domain are shifted by +DELAY.

To match this, the lag is applied uniformly to ALL Dst accesses (not just main phase),
and the phase boundaries are shifted by +lag:

- 0 hours for large storms (DstMIN < -350 nT).
- 1 hour for moderate storms (-350 ≤ DstMIN < -250 nT).
- 2 hours for minor storms (DstMIN ≥ -250 nT).
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

    # Phase boundaries shifted by lag to match Fortran's output time mapping (DTCMAKEDR
    # lines 396/422/449 use TMIN/TREC/TEND without DELAY, but the output is at TSTEP +
    # DELAY, so boundaries in the output domain are shifted).
    main_end  = min(end_idx, min_idx + lag)
    recov_end = min(end_idx, slope_change_idx + lag)

    dtc = initial_dtc

    for k in (start_idx + 1):end_idx
        # All Dst accesses use the lagged index (= integration time = output − DELAY).
        k_lag      = max(1, k - lag)
        k_lag_prev = max(1, k - 1 - lag)

        if k <= main_end
            # == Main Phase: Equation (8) With Substorm Correction (11) ====================

            # Clamp Dst to ≤ 0 to guard against SSC positive spikes
            # (DTCMAKEDR lines 382–383).
            dst_curr = min(0.0, Float64(vdst[k_lag]))
            dst_prev = min(0.0, Float64(vdst[k_lag_prev]))

            deldst = dst_curr - dst_prev

            if deldst >= 0.0
                # Dst increasing or flat (substorm recovery): Equation (11).
                #     dTc₁ = dTc₀ - SFAC × S × ΔDst
                # (DTCMAKEDR lines 387–388)
                dtc = dtc - _DTC_SFAC * S * deldst
            else
                # Dst decreasing (main phase intensification): Equation (8).
                #     dTc₁ = α × dTc₀ + S × [Dst₁ - β × Dst₀]
                # (DTCMAKEDR lines 390–391)
                dtc = _DTC_ALPHA * dtc + S * (dst_curr - _DTC_BETA * dst_prev)
            end

            # No dTc floor during main phase (per Fortran reference).

        elseif k <= recov_end
            # == Recovery Phase: Equation (12) =============================================
            #
            # dTc₁ = dTc₀ + 0.13 × Dst₁  (Dst at integration time = k − lag)
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
            # == Late recovery phase: Equation (13) ========================================
            #
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
