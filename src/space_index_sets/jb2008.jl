## Description #############################################################################
#
# Space index set: JB2008
# Remote files:
#     - http://sol.spacenvironment.net/jb2008/indices/DTCFILE.TXT
#     - http://sol.spacenvironment.net/jb2008/indices/SOLFSMY.TXT
#
# This set contains the space indices used for the JB2008 atmospheric model.
#
############################################################################################

############################################################################################
#                                        Structure                                         #
############################################################################################

struct JB2008 <: SpaceIndexSet
    # File: DTCFILE.TXT
    vdatetime::Vector{Float64}
    vdtc::Vector{Float64}

    # File: SOLFSMY.TXT
    vdate::Vector{Float64}
    vf10::Vector{Float64}
    vf81a::Vector{Float64}
    vs10::Vector{Float64}
    vs81a::Vector{Float64}
    vm10::Vector{Float64}
    vm81a::Vector{Float64}
    vy10::Vector{Float64}
    vy81a::Vector{Float64}
end

############################################################################################
#                                           API                                            #
############################################################################################

urls(::Type{JB2008}) = [
    "https://sol.spacenvironment.net/JB2008/indices/DTCFILE.TXT"
    "https://sol.spacenvironment.net/JB2008/indices/SOLFSMY.TXT"
]

expiry_periods(::Type{JB2008}) = [Day(1), Day(1)]

function parse_files(::Type{JB2008}, filepaths::Vector{String}; kwargs...)
    vdatetime, vdtc = _parse_dtcfile(filepaths |> first)
    vdate, vf10, vf81a, vs10, vs81a, vm10, vm81a, vy10, vy81a = _parse_solfsmy(filepaths |> last)

    return JB2008(
        vdatetime,
        vdtc,
        vdate,
        vf10,
        vf81a,
        vs10,
        vs81a,
        vm10,
        vm81a,
        vy10,
        vy81a,
    )
end

@register JB2008

"""
    space_index(::Val{:DTC}, date::Number) -> Float64

Get the exospheric temperature variation [K] caused by the Dst index at `instant` (UTC).
"""
function space_index(::Val{:DTC}, date::Number)
    obj    = @object(JB2008)
    knots  = obj.vdatetime
    values = obj.vdtc
    return linear_interpolation(knots, values, date)
end

"""
    space_index(::Val{:S10}, date::Number) -> Float64

Get the EUV index (26-34 nm) scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the `instant` (UTC).
"""
function space_index(::Val{:S10}, date::Number)
    obj    = @object(JB2008)
    knots  = obj.vdate
    values = obj.vs10
    return constant_interpolation(knots, values, date)
end

"""
    space_index(::Val{:S81a}, date::Number) -> Float64

Get the 81-day averaged EUV index (26-34 nm) scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the
`instant` (UTC).
"""
function space_index(::Val{:S81a}, date::Number)
    obj    = @object(JB2008)
    knots  = obj.vdate
    values = obj.vs81a
    return constant_interpolation(knots, values, date)
end

"""
    get_space_index(::Val{:M10}, date::Number) -> Float64

Get the MG2 index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the `instant` (UTC).
"""
function space_index(::Val{:M10}, date::Number)
    obj    = @object(JB2008)
    knots  = obj.vdate
    values = obj.vm10
    return constant_interpolation(knots, values, date)
end

"""
    space_index(::Val{:M81a}, date::Number) -> Float64

Get the 81-day averaged MG2 index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the `instant`
(UTC).
"""
function space_index(::Val{:M81a}, date::Number)
    obj    = @object(JB2008)
    knots  = obj.vdate
    values = obj.vm81a
    return constant_interpolation(knots, values, date)
end

"""
    space_index(::Val{:Y10}, date::Number) -> Float64

Get the solar X-ray & Lya index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the `instant`
(UTC).
"""
function space_index(::Val{:Y10}, date::Number)
    obj    = @object(JB2008)
    knots  = obj.vdate
    values = obj.vy10
    return constant_interpolation(knots, values, date)
end

"""
    space_index(::Val{:Y81a}, date::Number) -> Float64

Get the 81-day averaged solar X-ray & Lya index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for
the `instant` (UTC).
"""
function space_index(::Val{:Y81a}, date::Number)
    obj    = @object(JB2008)
    knots  = obj.vdate
    values = obj.vy81a
    return constant_interpolation(knots, values, date)
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# Parse the DTCFILE.TXT and return the interpolators.
function _parse_dtcfile(filepath::String)
    # Allocate the raw data.
    vdatetime = Float64[]
    vdtc      = Float64[]

    open(filepath) do file
        line_num = 0

        for ln in eachline(file)
            line_num += 1

            # Ignore comments.
            (ln[1] == '#') && continue

            tokens   = split(ln)
            num_toks = length(tokens)

            # Ignore blank lines.
            (num_toks == 0) && continue

            # Ignore and print warning about lines with bad format.
            if (num_toks != 27) || (tokens[1] != "DTC")
                @warn "Line $line_num of file DTCFILE.TXT has invalid format!"
                continue
            end

            # Compute the Julian day at midnight of the day.
            year = parse(Int,     tokens[2])
            doy  = parse(Float64, tokens[3])

            datetime_0h = datetime2julian(DateTime(year, 1, 1, 0, 0, 0) + Day(doy - 1))
            # Parse the data.
            for k = 1:24
                push!(vdatetime, datetime_0h + (k-1)/24.0)
                push!(vdtc,      parse(Float64, tokens[k + 3]))
            end
        end
    end

    return vdatetime, vdtc
end

# Parse the SOLFSMY.TXT and return the interpolators.
function _parse_solfsmy(filepath::String)
    # Allocate the raw data.
    vdate = Float64[]
    vf10  = Float64[]
    vf81a = Float64[]
    vs10  = Float64[]
    vs81a = Float64[]
    vm10  = Float64[]
    vm81a = Float64[]
    vy10  = Float64[]
    vy81a = Float64[]

    # Read the raw data in the file.
    open(filepath) do file
        line_num = 0

        for ln in eachline(file)
            line_num += 1

            # Ignore comments.
            (ln[1] == '#') && continue

            tokens   = split(ln)
            num_toks = length(tokens)

            # Ignore blank lines.
            (num_toks == 0) && continue

            # Ignore and print warning about lines with bad format.
            if num_toks != 12
                @warn "Line $line_num of file SOLFSMY.TXT has invalid format!"
                continue
            end

            # Get the date.
            year = parse(Int, tokens[1])
            doy  = parse(Int, tokens[2])
            date = datetime2julian(DateTime(year, 1, 1) + Day(doy - 1))

            # Parse data.
            push!(vdate, date)
            push!(vf10 , parse(Float64, tokens[ 4]))
            push!(vf81a, parse(Float64, tokens[ 5]))
            push!(vs10 , parse(Float64, tokens[ 6]))
            push!(vs81a, parse(Float64, tokens[ 7]))
            push!(vm10 , parse(Float64, tokens[ 8]))
            push!(vm81a, parse(Float64, tokens[ 9]))
            push!(vy10 , parse(Float64, tokens[10]))
            push!(vy81a, parse(Float64, tokens[11]))
        end
    end

    return vdate, vf10, vf81a, vs10, vs81a, vm10, vm81a, vy10, vy81a
end
