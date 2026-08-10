## Description #############################################################################
#
# Function to download files into scratch space.
#
############################################################################################

# Maximum number of attempts when downloading a remote file and the delay [s] before each
# retry. Transient network failures (e.g. connection timeouts) are common in the remote
# providers, so we retry before giving up.
const _DOWNLOAD_MAX_ATTEMPTS = 3
const _DOWNLOAD_RETRY_DELAYS = (1, 3)

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

        # We download to a temporary file because a failed download deletes the output
        # file, destroying a previously downloaded version we might need afterwards.
        tmp_filepath = filepath * ".download"

        for attempt in 1:_DOWNLOAD_MAX_ATTEMPTS
            try
                download(url, tmp_filepath)
                mv(tmp_filepath, filepath; force = true)
                update_download_timestamp(filepath)
                break
            catch e
                rm(tmp_filepath; force = true)

                if attempt < _DOWNLOAD_MAX_ATTEMPTS
                    delay = _DOWNLOAD_RETRY_DELAYS[attempt]

                    @warn "Failed to download the file '$filename' from '$url' " *
                        "(attempt $attempt of $_DOWNLOAD_MAX_ATTEMPTS): " *
                        "$(sprint(showerror, e)). Retrying in $delay s..."

                    sleep(delay)
                    continue
                end

                # All the attempts failed. If an old version of the file exists, we use it
                # instead of throwing an error. Notice that we do not update the download
                # timestamp in this case. Hence, the next initialization will try to
                # download the file again.
                isfile(filepath) || rethrow()

                timestamp_str = isnothing(timestamp) ? "an unknown time" : "$timestamp"

                @warn "All attempts to download the file '$filename' from '$url' " *
                    "failed: $(sprint(showerror, e)). Using the cached version " *
                    "obtained at $timestamp_str."
            end
        end
    end

    # Return the file path.
    return filepath
end
