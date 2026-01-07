## Description #############################################################################
#
# Definition of types and structures.
#
############################################################################################

export SpaceIndexSet, SpaceIndexSeries

"""
    abstract type SpaceIndexSet

Abstract type for all structures that represent space index sets.
"""
abstract type SpaceIndexSet end

"""
    SpaceIndexSeries{T,R} <: AbstractVector{T}

A time series of space index values with associated dates. Behaves like a vector of values
while also providing access to the corresponding dates.

# Indexing

- `series[i]` returns the value at index `i`.
- `series.dates` returns the date range.
- `series.values` returns the vector of values.
"""
struct SpaceIndexSeries{T, R <: AbstractRange{DateTime}} <: AbstractVector{T}
    dates::R
    values::Vector{T}
end

# AbstractVector interface
Base.size(s::SpaceIndexSeries) = size(s.values)
Base.getindex(s::SpaceIndexSeries, i::Int) = s.values[i]
