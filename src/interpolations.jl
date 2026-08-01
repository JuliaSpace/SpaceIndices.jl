## Description #############################################################################
#
# Implementation of simple interpolations used for the space indices.
#
# We do not need to import Interpolations.jl because the space indices require only very
# simple interpolations (1D-constant and linear).
#
############################################################################################

"""
    constant_interpolation(knots::AbstractVector, values::AbstractVector, x) -> eltype(values)

Perform a constant interpolation at `x` of `values` evaluated at `knots`. The interpolation
returns `value(knots[k-1])` in which `knots[k-1] <= x < knots[k]`.
"""
function constant_interpolation(knots::AbstractVector, values::AbstractVector, x::Number)
    # First, we need to verify if `x` is inside the domain.
    knots_beg = first(knots)
    knots_end = last(knots)

    if !(knots_beg <= x <= knots_end)
        x_dt = julian2datetime(x)
        knots_beg_dt = julian2datetime(knots_beg)
        knots_end_dt = julian2datetime(knots_end)

        throw(ArgumentError("""
            There is no available data for x = $(x_dt)!
            The available interval is: x ∈ [$knots_beg_dt, $knots_end_dt]."""))
    end

    # Find the vector index related to the request interval using binary search. We can
    # apply this algorithm because we assume that `knots` are unique and increasing.
    id = searchsortedlast(knots, x)

    return values[id]
end

"""
    linear_interpolation(knots::AbstractVector, values::AbstractVector, x)

Perform a linear interpolation at `x` of `values` evaluated at `knots`.
"""
function linear_interpolation(knots::AbstractVector, values::AbstractVector, x::Number)
    # First, we need to verify if `x` is inside the domain.
    knots_beg = first(knots)
    knots_end = last(knots)

    if !(knots_beg <= x <= knots_end)
        x_dt = julian2datetime(x)
        knots_beg_dt = julian2datetime(knots_beg)
        knots_end_dt = julian2datetime(knots_end)

        throw(ArgumentError("""
            There is no available data for x = $(x_dt)!
            The available interval is: x ∈ [$knots_beg_dt -- $knots_end_dt]."""))
    end

    # Find the vector index related to the request interval using binary search. We can
    # apply this algorithm because we assume that `knots` are unique and increasing.
    id = searchsortedlast(knots, x)

    # If we are at the knot precisely, just return it.
    if x == knots[id]
        return values[id]

    else
        # Here, we need to perform the interpolation using the adjacent knots.
        x₀ = knots[id]
        x₁ = knots[id + 1]

        y₀ = values[id]
        y₁ = values[id + 1]

        Δy = y₁ - y₀
        Δx = x₁ - x₀

        y = y₀ + Δy * (x - x₀) / Δx

        return y
    end
end
