## Description #############################################################################
#
# Space index file: SW-All.csv
# Default URL: https://celestrak.org/SpaceData/SW-All.csv
#
# This file stores the historic and predicted geomagnetic and solar flux data used in space
# weather models. Documentation can be found at:
#
#     https://celestrak.org/SpaceData/SpaceWx-format.php
#
############################################################################################

############################################################################################
#                                        Structure                                         #
############################################################################################

struct Celestrak <: SpaceIndexSet
    vjd::Vector{Float64}
    vBSRN::Vector{Float64}
    vND::Vector{Float64}
    vkp::Vector{NTuple{8, Float64}}
    vap::Vector{NTuple{8, Float64}}
    vCp::Vector{Float64}
    vC9::Vector{Float64}
    vISN::Vector{Float64}
    vap_daily::Vector{Float64}
    vf107_obs::Vector{Float64}
    vf107_adj::Vector{Float64}
    vf107_obs_avg_center81::Vector{Float64}
    vf107_obs_avg_last81::Vector{Float64}
    vf107_adj_avg_center81::Vector{Float64}
    vf107_adj_avg_last81::Vector{Float64}
end

function urls(::Type{Celestrak})
    ["https://celestrak.org/SpaceData/SW-All.csv"]
end

expiry_periods(::Type{Celestrak}) = [Day(1)]

function parse_files(::Type{Celestrak}, filepaths::Vector{String}; kwargs...)
    # We only have one file here.
    filepath = first(filepaths)

    # Allocate raw data.
    vjd = Float64[]
    vBSRN = Float64[]
    vND = Float64[]
    vkp = NTuple{8, Float64}[]
    vap = NTuple{8, Float64}[]
    vCp = Float64[]
    vC9 = Float64[]
    vISN = Float64[]
    vap_daily = Float64[]
    vf107_obs = Float64[]
    vf107_adj = Float64[]
    vf107_obs_avg_center81 = Float64[]
    vf107_obs_avg_last81 = Float64[]
    vf107_adj_avg_center81 = Float64[]
    vf107_adj_avg_last81 = Float64[]

    open(filepath, "r") do file
        # Skip the header line.
        readline(file)

        line_num = 1

        for line in eachline(file)
            line_num += 1

            tokens = split(line, ',')

            # Skip lines that do not have all the expected columns.
            if length(tokens) != 31
                @debug "The line $line_num in the file $(basename(filepath)) could not be parsed."
                continue
            end

            # Skip these to simplify parsing, only grab dates with all indices.
            tokens[27] == "PRM" && continue

            # Parse the date, which is in the ISO format `YYYY-MM-DD`.
            date = tryparse(Date, tokens[1])

            if isnothing(date)
                @debug "The line $line_num in the file $(basename(filepath)) could not be parsed."
                continue
            end

            jd_k = datetime2julian(DateTime(date))

            # If we get errors during parsing, we skip this data.
            BSRN_k                  = _parse_float(tokens[2])
            ND_k                    = _parse_float(tokens[3])
            kp_k                    = _parse_float_ntuple(tokens, 4, Val(8))
            ap_k                    = _parse_float_ntuple(tokens, 13, Val(8))
            Cp_k                    = _parse_float(tokens[22])
            C9_k                    = _parse_float(tokens[23])
            ISN_k                   = _parse_float(tokens[24])
            ap_daily_k              = _parse_float(tokens[21])
            f107_obs_k              = _parse_float(tokens[25])
            f107_adj_k              = _parse_float(tokens[26])
            f107_obs_avg_center81_k = _parse_float(tokens[28])
            f107_obs_avg_last81_k   = _parse_float(tokens[29])
            f107_adj_avg_center81_k = _parse_float(tokens[30])
            f107_adj_avg_last81_k   = _parse_float(tokens[31])

            if (
                isnothing(BSRN_k)                  ||
                isnothing(ND_k)                    ||
                isnothing(kp_k)                    ||
                isnothing(ap_k)                    ||
                isnothing(Cp_k)                    ||
                isnothing(C9_k)                    ||
                isnothing(ISN_k)                   ||
                isnothing(ap_daily_k)              ||
                isnothing(f107_obs_k)              ||
                isnothing(f107_adj_k)              ||
                isnothing(f107_obs_avg_center81_k) ||
                isnothing(f107_obs_avg_last81_k)   ||
                isnothing(f107_adj_avg_center81_k) ||
                isnothing(f107_adj_avg_last81_k)
            )
                @debug "The line $line_num in the file $(basename(filepath)) could not be parsed."
                continue
            end

            # If the current date is equal to the last stored one, it means we have
            # duplicated information. In this case, always use the latest one. Notice that
            # we compare against the last **stored** day. Hence, we never remove data
            # related to another day if the previous lines were skipped.
            if !isempty(vjd) && (vjd[end] == jd_k)
                vBSRN[end]                  = trunc(BSRN_k)
                vND[end]                    = trunc(ND_k)
                vkp[end]                    = _round_Kp.(kp_k)
                vap[end]                    = trunc.(ap_k)
                vCp[end]                    = Cp_k
                vC9[end]                    = C9_k
                vISN[end]                   = trunc(ISN_k)
                vap_daily[end]              = trunc(ap_daily_k)
                vf107_obs[end]              = f107_obs_k
                vf107_adj[end]              = f107_adj_k
                vf107_obs_avg_center81[end] = f107_obs_avg_center81_k
                vf107_obs_avg_last81[end]   = f107_obs_avg_last81_k
                vf107_adj_avg_center81[end] = f107_adj_avg_center81_k
                vf107_adj_avg_last81[end]   = f107_adj_avg_last81_k
            else
                push!(vjd,                    jd_k)
                push!(vBSRN,                  trunc(BSRN_k))
                push!(vND,                    trunc(ND_k))
                push!(vkp,                    _round_Kp.(kp_k))
                push!(vap,                    trunc.(ap_k))
                push!(vCp,                    Cp_k)
                push!(vC9,                    C9_k)
                push!(vISN,                   trunc(ISN_k))
                push!(vap_daily,              trunc(ap_daily_k))
                push!(vf107_obs,              f107_obs_k)
                push!(vf107_adj,              f107_adj_k)
                push!(vf107_obs_avg_center81, f107_obs_avg_center81_k)
                push!(vf107_obs_avg_last81,   f107_obs_avg_last81_k)
                push!(vf107_adj_avg_center81, f107_adj_avg_center81_k)
                push!(vf107_adj_avg_last81,   f107_adj_avg_last81_k)
            end
        end
    end

    return Celestrak(
        vjd,
        vBSRN,
        vND,
        vkp,
        vap,
        vCp,
        vC9,
        vISN,
        vap_daily,
        vf107_obs,
        vf107_adj,
        vf107_obs_avg_center81,
        vf107_obs_avg_last81,
        vf107_adj_avg_center81,
        vf107_adj_avg_last81
    )
end

@register Celestrak

"""
    space_index(::Val{:BSRN}, jd::Number) -> Float64

Get the Bartels Solar Rotation Number (BSRN) for the day at the Julian day `jd` (UTC).
"""
function space_index(::Val{:BSRN}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vBSRN
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:ND}, jd::Number) -> Float64

Get the number of the day within the Bartels 27-day cycle (ND) for the day at the Julian
day `jd` (UTC).
"""
function space_index(::Val{:ND}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vND
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Kp}, jd::Number) -> NTuple{8, Float64}

Get the Kp index for the day at the Julian day `jd` (UTC), computed every three hours.
"""
function space_index(::Val{:Kp}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vkp
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Ap}, jd::Number) -> NTuple{8, Float64}

Get the Ap index for the day at the Julian day `jd` (UTC), computed every three hours.
"""
function space_index(::Val{:Ap}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vap
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Cp}, jd::Number) -> Float64

Get the Cp index for the day at the Julian day `jd` (UTC).
"""
function space_index(::Val{:Cp}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vCp
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:C9}, jd::Number) -> Float64

Get the C9 index for the day at the Julian day `jd` (UTC).
"""
function space_index(::Val{:C9}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vC9
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:ISN}, jd::Number) -> Float64

Get the International Sunspot Number (ISN) for the day at the Julian day `jd` (UTC).
"""
function space_index(::Val{:ISN}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vISN
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Ap_daily}, jd::Number) -> Float64

Get the daily Ap index for the day at the Julian day `jd` (UTC).
"""
function space_index(::Val{:Ap_daily}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vap_daily
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Kp_daily}, jd::Number) -> Float64

Get the daily Kp index for the day at the Julian day `jd` (UTC).
"""
function space_index(::Val{:Kp_daily}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vkp
    vkp    = constant_interpolation(knots, values, jd)

    return sum(vkp) / length(vkp)
end


"""
    space_index(::Val{:F10obs}, jd::Number) -> Float64

Get the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (m² ⋅ Hz)] at the Julian day
`jd` (UTC).
"""
function space_index(::Val{:F10obs}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd 
    values = obj.vf107_obs
    # Shift 8 hours to move center of interval to midnight since F10.7 measurement occurs at
    # 20:00 UTC.
    jd_shift = jd - 8 / 24
    return constant_interpolation(knots, values, jd_shift)
end

"""
    space_index(::Val{:F10adj}, jd::Number) -> Float64

Get the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (m² ⋅ Hz)] at the Julian day
`jd` (UTC).
"""
function space_index(::Val{:F10adj}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vf107_adj
    # Shift 8 hours to move center of interval to midnight since F10.7 measurement occurs at
    # 20:00 UTC.
    jd_shift = jd - 8 / 24
    return constant_interpolation(knots, values, jd_shift)
end

"""
    space_index(::Val{:F10obs_avg_center81}, jd::Number) -> Float64

Get the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (m² ⋅ Hz)] averaged over 81
days centered at the Julian day `jd` (UTC).
"""
function space_index(::Val{:F10obs_avg_center81}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vf107_obs_avg_center81
    # Shift 8 hours to move center of interval to midnight since F10.7 measurement occurs at
    # 20:00 UTC.
    jd_shift = jd - 8 / 24
    return constant_interpolation(knots, values, jd_shift)
end

"""
    space_index(::Val{:F10obs_avg_last81}, jd::Number) -> Float64

Get the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (m² ⋅ Hz)] averaged over the
last 81 days from the Julian day `jd` (UTC).
"""
function space_index(::Val{:F10obs_avg_last81}, jd::Number)
    obj      = @object(Celestrak)
    knots    = obj.vjd
    values   = obj.vf107_obs_avg_last81
    # Shift 8 hours to move center of interval to midnight since F10.7 measurement occurs at
    # 20:00 UTC.
    jd_shift = jd - 8 / 24
    return constant_interpolation(knots, values, jd_shift)
end

"""
    space_index(::Val{:F10adj_avg_center81}, jd::Number) -> Float64

Get the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (m² ⋅ Hz)] averaged over 81
days centered at the Julian day `jd` (UTC).
"""
function space_index(::Val{:F10adj_avg_center81}, jd::Number)
    obj      = @object(Celestrak)
    knots    = obj.vjd
    values   = obj.vf107_adj_avg_center81
    # Shift 8 hours to move center of interval to midnight since F10.7 measurement occurs at
    # 20:00 UTC.
    jd_shift = jd - 8 / 24
    return constant_interpolation(knots, values, jd_shift)
end

"""
    space_index(::Val{:F10adj_avg_last81}, jd::Number) -> Float64

Get the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (m² ⋅ Hz)] averaged over the
last 81 days from the Julian day `jd` (UTC).
"""
function space_index(::Val{:F10adj_avg_last81}, jd::Number)
    obj      = @object(Celestrak)
    knots    = obj.vjd
    values   = obj.vf107_adj_avg_last81
    # Shift 8 hours to move center of interval to midnight since F10.7 measurement occurs at
    # 20:00 UTC.
    jd_shift = jd - 8 / 24
    return constant_interpolation(knots, values, jd_shift)
end

############################################################################################
#                                    Private Functions
############################################################################################

"""
    _parse_float(token::AbstractString) -> Union{Nothing, Float64}

Parse the `token` as a `Float64`, returning `nothing` if the operation fails.
"""
_parse_float(token::AbstractString) = tryparse(Float64, token)

"""
    _parse_float_ntuple(tokens::Vector{<:AbstractString}, first_index::Int, ::Val{N}) where N -> Union{Nothing, NTuple{N, Float64}}

Parse `N` consecutive elements of `tokens` as `Float64`s, starting at `first_index`. The
function returns `nothing` if any element cannot be parsed.
"""
function _parse_float_ntuple(
    tokens::Vector{<:AbstractString},
    first_index::Int,
    ::Val{N}
) where N
    values = ntuple(i -> tryparse(Float64, tokens[first_index + i - 1]), Val(N))
    any(isnothing, values) && return nothing
    return map(v -> something(v), values)
end

"""
    _round_Kp(x::Float64) -> Float64

Convert the Kp value `x` back to its original scale. CelesTrak multiplies Kp by 10 and
rounds it to the nearest integer.
"""
function _round_Kp(x::Float64)
    return round(round((x / 10.0) * 3) * 1/3; digits=3)
end
