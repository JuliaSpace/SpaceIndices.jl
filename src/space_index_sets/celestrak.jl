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

function parse_files(::Type{Celestrak}, filepaths::Vector{String})
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

    # Store the latest processed day.
    jd_k_1 = datetime2julian(DateTime(0, 1, 1))

    file = readdlm(filepath, ','; skipstart=1)::Matrix{Any}

    for i in 1:size(file)[1]

        # The Julian day of the data will be computed at noon to allow using the
        # nearest-neighbor algorithm in the interpolations.
        date_str = split(file[i, 1], '-')
        year   = parse(Int, date_str[1])
        month  = parse(Int, date_str[2])
        day    = parse(Int, date_str[3])
        jd_k = datetime2julian(DateTime(year, month, day))

        # If the current data is equal to the last one, it means we have duplicated
        # information. In this case, always use the latest one.
        if jd_k == jd_k_1
            pop!(vjd)
            pop!(vBSRN)
            pop!(vND)
            pop!(vkp)
            pop!(vap)
            pop!(vCp)
            pop!(vC9)
            pop!(vISN)
            pop!(vap_daily)
            pop!(vf107_obs)
            pop!(vf107_adj)
            pop!(vf107_obs_avg_center81)
            pop!(vf107_obs_avg_last81)
            pop!(vf107_adj_avg_center81)
            pop!(vf107_adj_avg_last81)
        end

        jd_k_1 = jd_k

        # Skip these to Simplify Parsing, Only Grab Dates with all Indices
        file[i, 27] == "PRM" && continue

        # If we get errors during parsing, we skip this data.
        try
            BSRN_k                  = trunc(file[i, 2])
            ND_k                    = trunc(file[i, 3])
            kp_k                    = _round_Kp.(NTuple{8}(float(file[i, j]) for j in 4:11))
            ap_k                    = NTuple{8}(trunc(file[i, j]) for j in 13:20)
            Cp_k                    = float(file[i, 22])
            C9_k                    = float(file[i, 23])
            ISN_k                   = trunc(file[i, 24])
            ap_daily_k              = trunc(file[i, 21])
            f107_obs_k              = float(file[i, 25])
            f107_adj_k              = float(file[i, 26])
            f107_obs_avg_center81_k = float(file[i, 28])
            f107_obs_avg_last81_k   = float(file[i, 29])
            f107_adj_avg_center81_k = float(file[i, 30])
            f107_adj_avg_last81_k   = float(file[i, 31])

            # Notice that if we reach this point, all the parsing happened correctly. Thus,
            # we can consider that the operation that adds data to the vectors is "atomic".
            push!(vjd,                    jd_k)
            push!(vBSRN,                  BSRN_k)
            push!(vND,                    ND_k)
            push!(vkp,                    kp_k)
            push!(vap,                    ap_k)
            push!(vCp,                    Cp_k)
            push!(vC9,                    C9_k)
            push!(vISN,                   ISN_k)
            push!(vap_daily,              ap_daily_k)
            push!(vf107_obs,              f107_obs_k)
            push!(vf107_adj,              f107_adj_k)
            push!(vf107_obs_avg_center81, f107_obs_avg_center81_k)
            push!(vf107_obs_avg_last81,   f107_obs_avg_last81_k)
            push!(vf107_adj_avg_center81, f107_adj_avg_center81_k)
            push!(vf107_adj_avg_last81,   f107_adj_avg_last81_k)
        catch
            @debug "The line $i in the file $(filepaths |> first |> basename) could not be parsed."
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
    space_index(::Val{:BSRN}, jd::Number) -> Int64

Get the BSRN index for the day at `instant`
"""
function space_index(::Val{:BSRN}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vBSRN
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:ND}, jd::Number) -> Int64

Get the ND index for the day at `instant`
"""
function space_index(::Val{:ND}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vND
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Kp}, jd::Number) -> NTuple{8, Float64}

Get the Kp index for the day at `instant` compute every three hours.
"""
function space_index(::Val{:Kp}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vkp
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Ap}, jd::Number) -> NTuple{8, Float64}

Get the Ap index for the day at `instant` compute every three hours.
"""
function space_index(::Val{:Ap}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vap
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Cp}, jd::Number) -> Float64

Get the Cp index for the day at `instant`
"""
function space_index(::Val{:Cp}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vCp
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:C9}, jd::Number) -> Float64

Get the C9 index for the day at `instant`
"""
function space_index(::Val{:C9}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vC9
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:ISN}, jd::Number) -> Int64

Get the ISN index for the day at `instant`
"""
function space_index(::Val{:ISN}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vISN
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Ap_daily}, jd::Number) -> Int64

Get the daily Ap index for the day at `instant`.
"""
function space_index(::Val{:Ap_daily}, jd::Number)
    obj    = @object(Celestrak)
    knots  = obj.vjd
    values = obj.vap_daily
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Kp_daily}, jd::Number) -> Float64

Get the daily Kp index for the day at `instant`.
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

Get the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] for the `instant`
(UTC).
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

Get the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] for the `instant`
(UTC).
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

Get the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over 81
days centered for the `instant` (UTC).
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

Get the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over the
last 81 days from the `instant` (UTC).
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

Get the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over 81
days centered for the `instant` (UTC).
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

Get the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over the
last 81 days from the `instant` (UTC).
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
    _round_Kp(x::Float64)

Celestrak mulitples Kp by 10 and rounds to the nearest integer this puts it back.
"""
function _round_Kp(x::Float64)
    return round(round((x / 10.0) * 3) * 1/3; digits=3)
end
