## Description #############################################################################
#
#   API definitions for the space files.
#
############################################################################################

export space_index

############################################################################################
#                                          Macros                                          #
############################################################################################

"""
    @data_handler(T)

Return the optional data handler associated with space index set `T`. This variable stores
an instance of `T` if the set was already initialized.
"""
macro data_handler(T)
    return esc(:("_" * "OPDATA_" * uppercase(string(T)) |> Symbol))
end

"""
    @object(T)

Return the object associated with the space index set `T`.

# Throws

- `Error`: If the space index `T` was not initialized.
"""
macro object(T)
    object_data_handler = @data_handler($T)

    ex = quote
        isavailable($object_data_handler) || error(
            """
            The space index $(string($T)) was not initialized yet.
            See the function SpaceIndices.init() for more information."""
        )
        get($object_data_handler)
    end

    return esc(ex)
end

"""
    @register(T)

Register the the space index set `T`. This macro push the data into the global vector of
space files and also creates the optional data handler for the processed structure.
"""
macro register(T)
    opdata_handler = @data_handler(T)

    ex = quote
        @OptionalData(
            $opdata_handler,
            $T,
            "The space index set " * string($(Meta.quot(T))) * " was not initialized yet."
        )

        push!(SpaceIndices._SPACE_INDEX_SETS, ($T, $opdata_handler))

        return nothing
    end

    return esc(ex)
end

############################################################################################
#                                        Functions                                         #
############################################################################################

"""
    _auto_init(::Type{T}) where T<:SpaceIndexSet -> Bool

Return whether the space index set `T` should be initialized automatically by the no-
argument `init()`. Sets that return `false` (e.g. `Dst`) must be initialized explicitly via
`init(T)`.
"""
_auto_init(::Type{<:SpaceIndexSet}) = true

"""
    expiry_periods(::Type{T}) where T<:SpaceIndexSet -> Vector{DatePeriod}

Return the expiry periods for the remote files associated with the space index set `T`. If a
time interval greater than this period has elapsed since the last download, the remote files
will be downloaded again.
"""
expiry_periods

"""
    filenames(::Type{T}) where T<:SpaceIndexSet -> Vector{String}

Return the filenames for the remote files associated with the space index set `T`. If this
function is not defined for `T`, the filenames will be obtained based on the URLs.
"""
filenames(::Type{T}) where T<:SpaceIndexSet = nothing

"""
    urls(::Type{T}) where T<:SpaceIndexSet -> Vector{String}

Return the URLs to fetch the remote files associated with the space index set `T`.
"""
urls

"""
    space_index(::Val{:index}, jd::Number; kwargs...) -> Number
    space_index(::Val{:index}, date::DateTime; kwargs...) -> Number

Get the space `index` for the Julian day `jd` or the `instant`. The latter must be an object
of type `DateTime`. `kwargs...` can be used to pass additional configuration for the space
index.
"""
space_index

function space_index(index::Val, date::DateTime)
    return space_index(index, datetime2julian(date))
end

"""
    parse_files(::Type{T}, filepaths::Vector{String}) where T<:SpaceIndexSet -> T

Parse the files associated with the space index set `T` using the files in `filepaths`. It
must return an object of type `T` with the parsed data.
"""
parse_files

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# Fetch the files related to the space index set `T`. This function returns their file
# paths.
#
# Keywords
#
# - `force_download::Bool`: If `true`, the files will be downloaded regardless of its
#   timestamp. (**Default** = `false`)
function _fetch_files(::Type{T}; force_download::Bool = false) where T<:SpaceIndexSet
    # Get the information for the structure `T`.
    T_urls           = urls(T)
    T_filenames      = filenames(T)
    T_expiry_periods = expiry_periods(T)

    num_T_urls = length(T_urls)
    key        = string(T)

    # If we do not have file names, try obtaining them from the URL.
    if isnothing(T_filenames)
        T_filenames = String[]
        sizehint!(T_filenames, num_T_urls)

        for url in T_urls
            filename = basename(url)

            isempty(filename) && error("""
                The filename could not be obtained from the URL $url.
                Please, provide the information using the API function `SpaceIndices.filenames`."""
            )

            push!(T_filenames, filename)
        end
    end

    filepaths = Vector{String}(undef, num_T_urls)

    for k in 1:num_T_urls
        filepaths[k - 1 + begin] = _download_file(
                T_urls[k - 1 + begin],
                key,
                T_filenames[begin + k - 1];
                force_download = force_download,
                expiry_period  = T_expiry_periods[k - 1 + begin]
        )
    end

    return filepaths
end
