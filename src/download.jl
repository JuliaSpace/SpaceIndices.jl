## Description #############################################################################
#
# Function to download files into scratch space.
#
############################################################################################

# Download the file in `url` to `filename` using the scratch space `key`. If
# `force_download` is `true`, it will always download the file. Otherwise, it will avoid
# downloading it again if the file exists and a time period less than `expiry_period`
# has passed.
#
# The instant in which the file was obtained is written to a file with the prefix
# `_timestamp` using the default `DateTime` format.
function _download_file(
    url::String,
    key::String,
    filename::String;
    force_download::Bool = false,
    expiry_period::DatePeriod = Day(7),
)
    filepath = get_filepath(filename, key)

    # We need to verify if we must re-download the data.
    download_file = false
    timestamp = get_download_timestamp(filepath)

    if force_download || isnothing(timestamp) || (now() >= timestamp + expiry_period)
        download_file = true
    else
        @debug "We found a file that is less than $expiry_period old (timestamp = $timestamp). Hence, we will use it."
    end

    # If we need to re-download, we will rebuild the scratch space.
    if download_file
        @info "Downloading the file '$filename' from '$url'..."
        download(url, filepath)
        update_download_timestamp(filepath)
    end

    # Return the file path.
    return filepath
end
