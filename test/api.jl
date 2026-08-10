## Description #############################################################################
#
#   Tests related to the API to create new space indices.
#
############################################################################################

# == Custom Space Index Set ================================================================
#
# We create here a custom space index set to obtain GPS leap seconds. The purpose is to test
# if one can use the API to define custom space indices.

struct LeapSeconds <: SpaceIndexSet
    jd::Vector{Float64}
    leap_seconds::Vector{Float64}
end

SpaceIndices.urls(::Type{LeapSeconds}) =
    ["https://ronanarraes.com/space-indices/leap_seconds.csv"]
SpaceIndices.expiry_periods(::Type{LeapSeconds}) = [Day(365)]

function SpaceIndices.parse_files(::Type{LeapSeconds}, filepaths::Vector{String})
    filepath = first(filepaths)
    raw_data, ~ = readdlm(filepath, ';'; header = true)
    return LeapSeconds(raw_data[:, 1], raw_data[:, 2])
end

function SpaceIndices.space_index(::Val{:LeapSeconds}, instant::DateTime)
    obj = SpaceIndices.@object(LeapSeconds)
    jd_utc = datetime2julian(instant)
    id = findfirst(>=(jd_utc), obj.jd)

    if isnothing(id)
        id = length(obj.jd)
    end

    return obj.leap_seconds[id]
end

SpaceIndices.@register LeapSeconds

@testset "Default Operations" begin
    # Make sure the scratch space is clean.
    delete_scratch!(SpaceIndices, "LeapSeconds")

    # Download the file.
    @test_logs (
        :info,
        "Downloading the file 'leap_seconds.csv' from 'https://ronanarraes.com/space-indices/leap_seconds.csv'...",
    ) match_mode = :any SpaceIndices.init(LeapSeconds)

    # Test some values.
    @test space_index(Val(:LeapSeconds), DateTime(1000, 1, 1)) == 11.0
    @test space_index(Val(:LeapSeconds), DateTime(1979, 1, 1)) == 18.0
    @test space_index(Val(:LeapSeconds), DateTime(1980, 1, 1)) == 19.0

    # Delete all objects.
    SpaceIndices.destroy()

    # Obtain the timestamp for the following tests.
    cache_dir      = get_scratch!(SpaceIndices, "LeapSeconds")
    file_timestamp = joinpath(cache_dir, "leap_seconds.csv_timestamp")
    timestamp      = split(read(file_timestamp, String), '\n') |> first |> DateTime

    # If we fetch again, we should not download the file.
    @test_logs (
        :debug,
        "We found a file that is less than 365 days old (timestamp = $timestamp). Hence, we will use it.",
    ) min_level = Logging.Debug match_mode = :any SpaceIndices.init(LeapSeconds)

    # Test the some data.
    @test space_index(Val(:LeapSeconds), DateTime(1000, 1, 1)) == 11.0
    @test space_index(Val(:LeapSeconds), DateTime(1979, 1, 1)) == 18.0
    @test space_index(Val(:LeapSeconds), DateTime(1980, 1, 1)) == 19.0
end

@testset "Expiry date" begin
    # Obtain the timestamp for the following tests.
    cache_dir      = get_scratch!(SpaceIndices, "LeapSeconds")
    file_timestamp = joinpath(cache_dir, "leap_seconds.csv_timestamp")
    timestamp      = split(read(file_timestamp, String), '\n') |> first |> DateTime
    new_timestamp  = timestamp - Day(196)

    # If the timestamp is 196 days old, we should not download the file.
    open(file_timestamp, "w") do f
        write(f, string(new_timestamp))
    end

    @test_logs (
        :debug,
        "We found a file that is less than 365 days old (timestamp = $new_timestamp). Hence, we will use it.",
    ) min_level = Logging.Debug match_mode = :any SpaceIndices.init(LeapSeconds)

    # Test the some data.
    @test space_index(Val(:LeapSeconds), DateTime(1000, 1, 1)) == 11.0
    @test space_index(Val(:LeapSeconds), DateTime(1979, 1, 1)) == 18.0
    @test space_index(Val(:LeapSeconds), DateTime(1980, 1, 1)) == 19.0

    # Now we change the timestamp to be 365 days old. In this case, the file should be
    # downloaded again.
    new_timestamp = timestamp - Day(365)
    open(file_timestamp, "w") do f
        write(f, string(new_timestamp))
    end

    @test_logs (
        :info,
        "Downloading the file 'leap_seconds.csv' from 'https://ronanarraes.com/space-indices/leap_seconds.csv'...",
    ) match_mode = :any SpaceIndices.init(LeapSeconds)

    # Test the some data.
    @test space_index(Val(:LeapSeconds), DateTime(1000, 1, 1)) == 11.0
    @test space_index(Val(:LeapSeconds), DateTime(1979, 1, 1)) == 18.0
    @test space_index(Val(:LeapSeconds), DateTime(1980, 1, 1)) == 19.0

    # If we set `force_download = true`, the file must be downloads.
    @test_logs (
        :info,
        "Downloading the file 'leap_seconds.csv' from 'https://ronanarraes.com/space-indices/leap_seconds.csv'...",
    ) match_mode = :any SpaceIndices.init(LeapSeconds, force_download = true)

    # Test the some data.
    @test space_index(Val(:LeapSeconds), DateTime(1000, 1, 1)) == 11.0
    @test space_index(Val(:LeapSeconds), DateTime(1979, 1, 1)) == 18.0
    @test space_index(Val(:LeapSeconds), DateTime(1980, 1, 1)) == 19.0

    # If the timestamp file is invalid, we should download the file again.
    open(file_timestamp, "w") do f
        write(f, "THIS CANNOT BE CONVERTED TO DATATIME")
    end

    @test_logs (
        :info,
        "Downloading the file 'leap_seconds.csv' from 'https://ronanarraes.com/space-indices/leap_seconds.csv'...",
    ) match_mode = :any SpaceIndices.init(LeapSeconds)
end

# == Dummy Space Index Set =================================================================
#
# This dummy space index set is used only to test if the optional API function `filenames`
# is working properly.

struct DummySet <: SpaceIndexSet end

SpaceIndices.urls(::Type{DummySet}) =
    ["https://ronanarraes.com/space-indices/leap_seconds.csv"]
SpaceIndices.expiry_periods(::Type{DummySet}) = [Day(365)]
SpaceIndices.filenames(::Type{DummySet}) = ["dummy.csv"]
SpaceIndices.parse_files(::Type{DummySet}, filepaths::Vector{String}) = DummySet()

SpaceIndices.@register DummySet

@testset "Optional API Functions" begin
    # Make sure the scratch space is clean.
    delete_scratch!(SpaceIndices, "DummySet")

    @test_logs (
        :info,
        "Downloading the file 'dummy.csv' from 'https://ronanarraes.com/space-indices/leap_seconds.csv'...",
    ) match_mode = :any SpaceIndices.init(DummySet)

    # Check if the file exits.
    cache_dir = get_scratch!(SpaceIndices, "DummySet")
    filepath  = joinpath(cache_dir, "dummy.csv")
    @test isfile(filepath) == true
end

@testset "Download Retries and Cached File Fallback" begin
    # Make sure the scratch space is clean.
    delete_scratch!(SpaceIndices, "DownloadFallback")

    bad_url = "https://this-domain-does-not-exist.invalid/data.csv"

    # Without a cached file, the error must be rethrown after all the download attempts.
    @test_throws Exception SpaceIndices._download_file(
        bad_url, "DownloadFallback", "data.csv"
    )

    # Create a cached file with an expired timestamp.
    cache_dir      = get_scratch!(SpaceIndices, "DownloadFallback")
    filepath       = joinpath(cache_dir, "data.csv")
    file_timestamp = filepath * "_timestamp"
    old_timestamp  = DateTime(2000, 1, 1)

    write(filepath, "cached data")
    write(file_timestamp, string(old_timestamp))

    # With a cached file, the fallback must return it, keeping its content and timestamp
    # untouched so the next initialization tries to download the file again.
    r = SpaceIndices._download_file(
        bad_url, "DownloadFallback", "data.csv"; expiry_period = Day(1)
    )

    @test r == filepath
    @test read(filepath, String) == "cached data"
    @test SpaceIndices.get_download_timestamp(filepath) == old_timestamp
end
