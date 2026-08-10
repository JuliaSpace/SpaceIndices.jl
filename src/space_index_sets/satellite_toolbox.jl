## Description #############################################################################
#
# Space index set: SatelliteToolboxSpaceIndexSets (predicted F10.7)
# Source: JuliaSpace/SatelliteToolboxSpaceIndexSets repository
# URL: https://github.com/JuliaSpace/SatelliteToolboxSpaceIndexSets
#
# This space index set provides a long-term prediction of the F10.7 index (10.7-cm solar
# flux). The prediction is computed using a harmonic model with six harmonics fitted to the
# observed F10.7 data provided by CelesTrak since 1957-10-02:
#
#   F̄10.7(t) = F₀ + Σᵢ₌₁⁶ [aᵢ sin(2πi (t - t₀) / P) + bᵢ cos(2πi (t - t₀) / P)],
#
# where t₀ is the reference epoch [Julian Day], F₀ is the mean value of the F10.7 index
# [sfu], P is the fitted period of the solar cycle [days], and aᵢ and bᵢ are the harmonic
# coefficients [sfu].
#
# The coefficients are fitted daily by a GitHub action in the repository
# JuliaSpace/SatelliteToolboxSpaceIndexSets, which stores the result in the file
# f107_prediction_coefficients.csv.
#
## References ##############################################################################
#
# [1] Whitlock, D. (2006). Modeling the Effect of High Solar Activity on the Orbital Debris
#     Environment. Orbital Debris Quarterly News, vol. 10, n. 2, April 2006.
#
############################################################################################

############################################################################################
#                                        Structure                                         #
############################################################################################

"""
    struct SatelliteToolboxSpaceIndexSets

Store the coefficients of the harmonic model used to predict the F10.7 index. The model is
described in the file `src/space_index_sets/satellite_toolbox.jl`.

# Fields

- `t₀::Float64`: Reference epoch of the harmonic model [Julian Day, UTC].
- `F₀::Float64`: Mean value of the F10.7 index [10⁻²² W / (m² ⋅ Hz)].
- `P::Float64`: Fitted period of the solar cycle [days].
- `a::NTuple{6, Float64}`: Sine coefficients of the six harmonics [10⁻²² W / (m² ⋅ Hz)].
- `b::NTuple{6, Float64}`: Cosine coefficients of the six harmonics [10⁻²² W / (m² ⋅ Hz)].
"""
struct SatelliteToolboxSpaceIndexSets <: SpaceIndexSet
    t₀::Float64
    F₀::Float64
    P::Float64
    a::NTuple{6, Float64}
    b::NTuple{6, Float64}
end

# Default values for the SatelliteToolboxSpaceIndexSets structure. These values are used
# when the space index set cannot be parsed, leading to a constant predicted F10.7 index of
# 120 sfu. The reference epoch is 1957-10-02T00:00:00.000 UTC, which is the first day of
# the observed data used in the fitting.
const _DEFAULT_SATELLITE_TOOLBOX_SPACE_INDEX_SETS = SatelliteToolboxSpaceIndexSets(
    2436113.5, 120.0, 3900.0, (0.0, 0.0, 0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
)

############################################################################################
#                                           API                                            #
############################################################################################

function urls(::Type{SatelliteToolboxSpaceIndexSets})
    return [
        "https://raw.githubusercontent.com/JuliaSpace/SatelliteToolboxSpaceIndexSets/refs/heads/main/files/f107_prediction_coefficients.csv",
    ]
end

expiry_periods(::Type{SatelliteToolboxSpaceIndexSets}) = [Day(1)]

function parse_files(
    ::Type{SatelliteToolboxSpaceIndexSets}, filepaths::Vector{String}; kwargs...
)
    # We only have one file here.
    filepath = first(filepaths)

    # Read and parse the CSV file. The expected format is a header line followed by a
    # single data line with the 15 model coefficients.
    for (l, line) in enumerate(eachline(filepath))
        # Skip the header and empty lines.
        ((l == 1) || isempty(strip(line))) && continue

        tokens = split(line, ',')

        # Skip lines that do not have all the expected columns.
        if length(tokens) != 15
            @error "SatelliteToolboxSpaceIndexSets: The file $(basename(filepath)) does " *
                "not have the expected number of columns (15). Using the default " *
                "coefficients."
            return _DEFAULT_SATELLITE_TOOLBOX_SPACE_INDEX_SETS
        end

        # Parse all the columns, aborting if any value is invalid.
        coefs  = Vector{Float64}(undef, 15)
        parsed = true

        for k in 1:15
            v = tryparse(Float64, tokens[k])

            if isnothing(v)
                parsed = false
                break
            end

            coefs[k] = v
        end

        if !parsed
            @error "SatelliteToolboxSpaceIndexSets: The file $(basename(filepath)) " *
                "contains values that could not be parsed as numbers. Using the " *
                "default coefficients."
            return _DEFAULT_SATELLITE_TOOLBOX_SPACE_INDEX_SETS
        end

        t₀ = coefs[1]
        F₀ = coefs[2]
        P  = coefs[3]
        a  = (coefs[4], coefs[5], coefs[6], coefs[7], coefs[8], coefs[9])
        b  = (coefs[10], coefs[11], coefs[12], coefs[13], coefs[14], coefs[15])

        return SatelliteToolboxSpaceIndexSets(t₀, F₀, P, a, b)
    end

    @error "SatelliteToolboxSpaceIndexSets: The file $(basename(filepath)) does not " *
        "contain any data line. Using the default coefficients."
    return _DEFAULT_SATELLITE_TOOLBOX_SPACE_INDEX_SETS
end

@register SatelliteToolboxSpaceIndexSets

"""
    space_index(::Val{:F10predicted}, jd::Number) -> Float64

Get the predicted F10.7 index (10.7-cm solar flux) [10⁻²² W / (m² ⋅ Hz)] at the Julian Day
`jd` [UTC].

The prediction is computed using a harmonic model with six harmonics fitted to the
observed F10.7 data provided by CelesTrak since 1957-10-02. Hence, it only captures the
mean solar cycle behavior, being intended for long-term analyses such as satellite decay
studies. It must not be used as a short-term forecast of the solar activity.

If the remote coefficient file could not be parsed during the initialization, the model
falls back to a constant value of 120 [10⁻²² W / (m² ⋅ Hz)].

# References

- **[1]** Whitlock, D. (2006). *Modeling the Effect of High Solar Activity on the Orbital
    Debris Environment*. Orbital Debris Quarterly News, vol. 10, n. 2, April 2006.
"""
function space_index(::Val{:F10predicted}, jd::Number)
    obj = @object(SatelliteToolboxSpaceIndexSets)

    t₀ = obj.t₀
    F₀ = obj.F₀
    P  = obj.P
    a  = obj.a
    b  = obj.b

    # Angular position of `jd` within the solar cycle.
    ω = 2π * (jd - t₀) / P

    # We must accumulate the harmonics in a variable with the same type as `ω` to keep this
    # function type stable when `jd` is not a `Float64`, e.g. when computing derivatives
    # using automatic differentiation.
    acc = zero(ω)

    @inbounds for i in 1:6
        s, c = sincos(i * ω)
        acc += a[i] * s + b[i] * c
    end

    return F₀ + acc
end
