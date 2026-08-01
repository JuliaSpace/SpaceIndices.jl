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

# Cache with the latest provisional month obtained from the remote server. The first
# element is the instant in which the information was obtained, and the second is the
# result. This cache avoids probing the remote server multiple times during the same
# initialization, since `filenames`, `urls`, and `expiry_periods` are all called when
# initializing the Dst space index set. It also guarantees that those functions see a
# consistent file list.
const _DST_PROV_MONTH_CACHE_VALIDITY = Minute(15)
const _DST_PROV_MONTH_CACHE =
    Ref{Tuple{DateTime, Union{Nothing, Tuple{Int, Int}}}}((DateTime(0), nothing))

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
"""
struct Dst <: SpaceIndexSet
    vjd::Vector{Float64}
    vdst::Vector{Float64}
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
            ((year == last_prov_year) && (month > last_prov_month)) && break

            push!(vfilenames, "dst_prov_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    # == Real-Time Dst files ===============================================================

    for year in last_prov_year:current_year
        start_month = (year == last_prov_year) ? last_prov_month + 1 : 1

        for month in start_month:12
            ((year == current_year) && (month > current_month)) && break
            push!(vfilenames, "dst_realtime_$(year)_$(lpad(month, 2, '0')).html")
        end
    end

    return vfilenames
end

function parse_files(::Type{Dst}, filepaths::Vector{String}; kwargs...)
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

    return Dst(vjd, vdst)
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

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _get_latest_month_with_provisional_data() -> Union{Tuple{Int, Int}, Nothing}

Return the latest year and month for which Kyoto WDC has published provisional Dst data.

The result is obtained with [`_probe_latest_month_with_provisional_data`](@ref) and cached
for `_DST_PROV_MONTH_CACHE_VALIDITY`. Hence, the functions `filenames`, `urls`, and
`expiry_periods`, which are all called when initializing the Dst space index set, probe the
remote server only once and see a consistent file list.

# Returns

- `Union{Tuple{Int, Int}, Nothing}`: Tuple `(year, month)` with the latest provisional
    month, or `nothing` if no provisional month could be determined.
"""
function _get_latest_month_with_provisional_data()
    cache_instant, cache_value = _DST_PROV_MONTH_CACHE[]

    if now() - cache_instant <= _DST_PROV_MONTH_CACHE_VALIDITY
        return cache_value
    end

    r = _probe_latest_month_with_provisional_data()
    _DST_PROV_MONTH_CACHE[] = (now(), r)

    return r
end

"""
    _probe_latest_month_with_provisional_data() -> Union{Tuple{Int, Int}, Nothing}

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
function _probe_latest_month_with_provisional_data()
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
line contains a day number followed by 24 hourly values, each in a fixed-width 4-character
field. The fill value `9999`, used by Kyoto for hours that are not yet available in real-time
data, is ignored.
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

        # Parse the day number from the start of the line. The Kyoto `<pre>` block uses a
        # fixed-width format: the day field is right-justified (leading spaces + 1–2 digits
        # + space) and is immediately followed by 24 hourly Dst values, each in a
        # 4-character field. A generic integer regex would mis-tokenise sequences like "
        # -129999", where the space-padded negative value " -12" (4 chars) and the fill
        # value "9999" (4 chars) are stored back-to-back without a separator.
        m_day = match(r"^\s*(\d{1,2})\s", clean)
        isnothing(m_day) && continue

        day = tryparse(Int, m_day.captures[1]::SubString{String})
        (isnothing(day) || !(1 <= day <= 31)) && continue
        day > Dates.daysinmonth(year, month) && continue

        # Everything after the day field (whose byte-length equals ncodeunits(m_day.match))
        # consists of consecutive 4-character hourly value fields.
        data = clean[(m_day.offset + ncodeunits(m_day.match)):end]

        for h in 0:23
            # We need to account for a spurious extra space that appears after the 8th and
            # 16th hourly values.
            fstart = 4h + 1 + (h >= 8 ? 1 : 0) + (h >= 16 ? 1 : 0)
            fend   = fstart + 3
            fend > ncodeunits(data) && break

            dst_val = tryparse(Float64, data[fstart:fend])
            isnothing(dst_val) && continue

            # Kyoto uses 9999 as fill for hours not yet available; real Dst never
            # exceeds a few hundred nT so any |value| >= 9999 is invalid.
            abs(dst_val) >= 9999.0 && continue

            jd = datetime2julian(DateTime(year, month, day, h, 0, 0))
            push!(vjd,  jd)
            push!(vdst, dst_val)
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
