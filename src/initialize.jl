## Description #############################################################################
#
# Function to initialize all space indices.
#
############################################################################################

"""
    init(::Type{T}; kwargs...) where T<:SpaceIndexSet -> Nothing

Initialize the space index set `T`.

This function will download the remote files associated with the space index set `T` if they
do not exist or if their expiry period has been elapsed. Aftward, it will parse the files
and populate the object to be accessed by the function [`space_index`](@ref).

# Keywords

- `force_download::Bool`: If `true`, the remote files will be downloaded regardless of their
    timestamps.
    (**Default** = `false`)
- `filepaths::Union{Nothing, Vector{String}}`: If it is `nothing`, the function will
    download the space index files from the locations specified in the [`urls`](@ref)
    API function. However, the user can pass a vector with the file locations, which will be
    used instead of downloading the data. In this case, the user must provide all the files
    in the space index set `T`.
    (**Default** = `nothing`)
"""
function init(
    ::Type{T};
    filepaths::Union{Nothing, Vector{String}} = nothing,
    force_download::Bool = false
) where T<:SpaceIndexSet
    id = findfirst(x -> first(x) === T, _SPACE_INDEX_SETS)
    isnothing(id) && throw(ArgumentError("The space index set $T is not registered!"))

    # Get the space index file handler.
    handler = _SPACE_INDEX_SETS[id] |> last

    # Fetch the files, if necessary, and parse it.
    if isnothing(filepaths)
        fp = _fetch_files(T; force_download=force_download)
    else
        # We must check if the number of files in `filepaths` is the same as in the `url`
        # function.
        lu = length(urls(T))
        lf = length(filepaths)

        (lu != lf) && error(
            "We expected $lu files for the space index set $T in the keyword `filepath`. However, $lf files were provided."
        )

        fp = filepaths
    end

    obj = parse_files(T, fp)
    push!(handler, obj)

    return nothing
end

"""
    init(; blocklist::Vector = []) -> Nothing

Initialize all the registered space index sets.

This function will download the remote files associated to the space index sets if they do
not exist or if the expiry period has been elapsed. Afterward, it will parse the files and
populate the objects to be accessed by the function [`space_index`](@ref).

Space index sets where `_auto_init(T)` returns `false` (e.g. `Dst`) are always skipped and
must be initialized explicitly via `init(T)`.

If the user does not want to initialize some additional sets, they can pass them in the
keyword `blocklist`.
"""
function init(; blocklist::Vector = [])
    # The vector `_SPACE_INDEX_SETS` contains a set of `Tuple`s with the space file
    # structure and its optional data handler.
    for (T, handler) in _SPACE_INDEX_SETS
        # Skip sets that require explicit initialization or are in the block list.
        if !_auto_init(T) || (T ∈ blocklist)
            @debug "Skipping the space file $T."
            continue
        end

        # Fetch the space file, if necessary, and parse it.
        filepaths = _fetch_files(T)
        obj = parse_files(T, filepaths)
        push!(handler, obj)
    end
end
