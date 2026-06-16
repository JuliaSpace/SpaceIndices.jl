# Initialization of Space Indices

```@meta
CurrentModule = SpaceIndices
```

```@setup init
using SpaceIndices
SpaceIndices.Scratch.clear_scratchspaces!(SpaceIndices)
```

The files of all the registered space indices can be automatically downloaded using:

```julia
SpaceIndices.init(; kwargs...) -> Nothing
```

If a file exists, the function checks if its expiry period has passed. If so, it downloads
the file again.

```julia-repl
julia> SpaceIndices.init()
```

If the user does not want to download a set of space indices, they can pass them in the
keyword `blocklist` to the function `SpaceIndices.init`.

```julia-repl
julia> SpaceIndices.init(; blocklist = [SpaceIndices.Celestrak])
```

If the user wants to initialize only one space index set, they can pass it to the same
function:

```julia
SpaceIndices.init(::Type{T}; kwargs...) where T<:SpaceIndexSet -> Nothing
```

where `T` must be the space index set. In this case, the user have access to the following
keywords:

- `force_download::Bool`: If `true`, the remote files will be downloaded regardless of their
    timestamps.
    (**Default** = `false`)
- `filepaths::Union{Nothing, Vector{String}}`: If it is `nothing`, the function will
    download the space index files from the locations specified in the [`urls`](@ref)
    API function. However, the user can pass a vector with the file locations, which will be
    used instead of downloading the data. In this case, the user must provide all the files
    in the space index set `T`.
    (**Default** = `nothing`)

```@repl init
SpaceIndices.init()
```

```julia-repl
julia> SpaceIndices.init(SpaceIndices.Celestrak; filepaths = ["./SW-All.csv"])
```

## Dst Index Set

The `Dst` index set is **not** included in the default `SpaceIndices.init()` call because it
downloads many monthly HTML files from the Kyoto WDC (final, provisional, and real-time
quicklook data). It must be initialized separately:

```julia-repl
julia> SpaceIndices.init()                           # Initialize all default sets first
julia> SpaceIndices.init(SpaceIndices.Dst)           # Then initialize Dst
```

The `Dst` set provides one index: `:Dst` (the raw hourly Dst index in nT).
