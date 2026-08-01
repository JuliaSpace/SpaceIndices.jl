# API for Space Files

This document describes the API that must be followed for space index sets.

## Structure

Each space index set must have a structure that has `SpaceIndexSet` as its super-type. This
structure must contain all the required field to process and return the indices provided by
the set.

```julia
struct MySpaceIndex <: SpaceIndexSet
    ...
end
```

## Required API Functions

We must define the following functions for every space index set defined as in the previous
section.

```julia
function SpaceIndices.urls(::Type{T}) where T<:SpaceIndexSet -> Vector{String}
```

This function must return a `Vector{String}` with the URLs to download the files for the
indices. For example:

```julia
SpaceIndices.urls(::Type{MySpaceIndex}) = ["https://url.for.my/space.file.txt"]
```

---

```julia
function SpaceIndices.expiry_periods(::Type{T}) where T<:SpaceIndexSet -> Vector{DatePeriod}
```

This function must return the list with the expiry periods for the files in the space index
set `T`. The remote files will always be downloaded if a time greater than this period has
elapsed after the last download. For example:

```julia
SpaceIndices.expiry_periods(::Type{MySpaceIndex}) = [Day(7)]
```

---

```julia
SpaceIndices.parse_files(::Type{T}, filepaths::Vector{String}; kwargs...) where T<:SpaceIndexSet -> T
```

This function must parse the files related to the space index set `T` using the files in
`filepaths` and return an instance of `T` with the parsed data. For example,

```julia
function SpaceIndices.parse_files(::Type{MySpaceIndex}, filepaths::Vector{String})
    for filepath in filepaths
        open(filepath, "r") do f
            ...
        end
    end

    return MySpaceIndex(...)
end
```

All the keywords passed to the `SpaceIndices.init(T; kwargs...)` are redirected to
`parse_files`.

---

Finally, the new space index set must also implement a set of functions with the following
signature:

```julia
SpaceIndices.space_index(::Val{:index}, instant::DateTime; kwargs...) -> Number
SpaceIndices.space_index(::Val{:index}, jd::Number; kwargs...) -> Number
```

where the space `index` for the `instant` will be returned.

## Optional API Functions

```julia
function SpaceIndices.auto_init(::Type{T}) where T<:SpaceIndexSet -> Bool
```

This function returns whether the space index set `T` should be initialized automatically by
the no- argument `init()`. Sets that return `false` must be initialized explicitly via
`init(T)`. By default, it always returns `true`.

---

```julia
function SpaceIndices.filenames(::Type{T}) where T<:SpaceIndexSet -> Vector{String}
```

This function can return a `Vector{String}` with the names of the remote files. The system
will used this information to save the data in the package scratch space. For example:

```julia
SpaceIndices.filenames(::Type{MySpaceIndex}) = ["my_space_file.txt"]
```

If this function is not defined, the filename will be obtained from the URL using the
function `basename`.

!!! warning

    All functions that return a `Vector` must return an array with **the same number of
    elements**.
