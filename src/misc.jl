## Description #############################################################################
#
# Miscellaneous functions that are used in the package.
#
############################################################################################

"""
    get_filepath(filename::String, key::String) -> String

Return the absolute path of `filename` inside the scratch space identified by `key`.

If the scratch space associated with `key` does not exist yet, it is created.
"""
function get_filepath(filename::String, key::String)
    cache_dir = @get_scratch!(key)
    return joinpath(cache_dir, filename)
end

"""
    get_download_timestamp(filepath::String) -> Union{DateTime, Nothing}

Return the download timestamp associated with the file `filepath`.

The timestamp is read from a companion file with the same path as `filepath` and the suffix
`_timestamp`. If either the data file or the timestamp file is missing, or if the timestamp
cannot be parsed, the function returns `nothing`.
"""
function get_download_timestamp(filepath::String)
    filepath_timestamp = filepath * "_timestamp"

    (!isfile(filepath) || !isfile(filepath_timestamp)) && return nothing

    # Read the timestamp so the caller can decide whether the file must be re-downloaded.
    try
        return DateTime(strip(readline(filepath_timestamp)))
    catch
        return nothing
    end
end

"""
    update_download_timestamp(filepath::String) -> Nothing

Write the current time as the download timestamp of the file `filepath`.

The timestamp is stored in a companion file with the same path as `filepath` and the suffix
`_timestamp`, using the default `DateTime` string representation.
"""
function update_download_timestamp(filepath::String)
    filepath_timestamp = filepath * "_timestamp"

    open(filepath_timestamp, "w") do f
        return write(f, string(now()))
    end

    return nothing
end
