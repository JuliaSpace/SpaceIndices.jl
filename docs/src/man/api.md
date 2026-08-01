# SpaceIndices.jl API

```@meta
CurrentModule = SpaceIndices
```

This package defines an API to allow user to defin new space indices. We describe this API
in the following.

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
get_filenames(::Type{MySpaceIndex}) = [Day(7)]
```

---

```julia
SpaceIndices.parse_files(::Type{T}, filepaths::Vector{String}) where T<:SpaceIndexSet -> T
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

Finally, the new space index set must also implement a set of functions with the following
signature:

```julia
SpaceIndices.space_index(::Val{:index}, instant::DateTime; kwargs...) -> Number
SpaceIndices.space_index(::Val{:index}, jd::Number; kwargs...) -> Number
```

where the space `index` for the `instant` will be returned.

## Optional API Functions

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

## Example: Leap Seconds

We will use the API to define a new space index set that has the GPS leap seconds. The file
has a CSV-like format but the values are separated by `;`. It has two columns. The first
contains the Julian days in which the leap seconds were modified to the values in the second
column:

```text
Julian Day;Leap Seconds
2441499.500000;11.0
2441683.500000;12.0
2442048.500000;13.0
2442413.500000;14.0
...
```

First, we need to load the required packages to process the information in the space index
file:

```julia
julia> using DelimitedFiles, Dates
```

Now, we need to create its structure:

```julia
struct LeapSeconds <: SpaceIndexSet
    jd::Vector{Float64}
    leap_seconds::Vector{Float64}
end
```

where `jd` contains the Julian days in which the leap seconds were modified to the values in
`leap_seconds`.

We also need to overload the API functions:

```julia
SpaceIndices.urls(::Type{LeapSeconds}) = ["https://ronanarraes.com/space-indices/leap_seconds.csv"]
SpaceIndices.expiry_periods(::Type{LeapSeconds}) = [Day(365)]

function SpaceIndices.parse_files(::Type{LeapSeconds}, filepaths::Vector{String})
    filepath = first(filepaths)
    raw_data, ~ = readdlm(filepath, ';'; header = true)
    return LeapSeconds(raw_data[:, 1], raw_data[:, 2])
end
```

We also need to populate the function `space_index` with the supported index in this file:

```julia
function SpaceIndices.space_index(::Val{:LeapSeconds}, instant::DateTime)
    obj = SpaceIndices.@object(LeapSeconds)
    jd = datetime2julian(instant)
    id = findfirst(>=(jd_utc), obj.jd)

    if isnothing(id)
        id = length(obj.jd)
    end

    return obj.leap_seconds[id]
end
```

Finally, we need to register the new space index file:

```julia
SpaceIndices.@register LeapSeconds
```

We can now use the **SpaceIndices.jl** system to fetch the information:

```julia
julia> SpaceIndices.init()
[ Info: Downloading the file 'DTCFILE.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/DTCFILE.TXT'...
[ Info: Downloading the file 'SOLFSMY.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/SOLFSMY.TXT'...
[ Info: Downloading the file 'SW-All.csv' from 'https://celestrak.org/SpaceData/SW-All.csv'...

julia> space_index(Val(:LeapSeconds), now())
37.0
```
