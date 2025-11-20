# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==========================================================================================
#
# Hpo space index set.
# Default URLs:
#       https://kp.gfz.de/app/files/Hp30_ap30_complete_series.txt
#       https://kp.gfz.de/app/files/Hp60_ap60_complete_series.txt
#
# These files contains the Hpo geomagnetic indices from GFZ Helmholtz Centre Potsdam.
# The Hpo index provides high-cadence geomagnetic activity measurements with 30-minute
# (Hp30) and 60-minute (Hp60) resolution, similar to the Kp index but with finer temporal
# granularity. Documentation cna be found at:
#       https://www.gfz.de/en/hpo-index
#
# References
# Yamazaki, Y., Matzka, J. (2022). Hpo index: A new geomagnetic index with high time
# resolution. Geophysical Research Letters, 49, e2022GL098860.
# https://doi.org/10.1029/2022GL098860
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

############################################################################################
#                                        Structure                                         #
############################################################################################

# Exact mapping from Hp to ap values
const HP_VALUES = [
    0.000, 0.333, 0.667, 1.000, 1.333, 1.667, 2.000, 2.333, 2.667,
    3.000, 3.333, 3.667, 4.000, 4.333, 4.667, 5.000, 5.333, 5.667,
    6.000, 6.333, 6.667, 7.000, 7.333, 7.667, 8.000, 8.333, 8.667,
    9.000, 9.333, 9.667, 10.000, 10.333, 10.667, 11.000, 11.333,
    11.667, 12.000, 12.667, 13.333
]

const AP_VALUES = [
    0, 2, 3, 4, 5, 6, 7, 9, 12,
    15, 18, 22, 27, 32, 39, 48, 56, 67,
    80, 94, 111, 132, 154, 179, 207, 236, 265,
    294, 324, 355, 388, 421, 456, 494, 534,
    574, 617, 705, 801
]

struct Hpo <: SpaceIndexSet
    vjd::Vector{Float64}
    vhp30::Vector{NTuple{48, Float64}}
    vap30::Vector{NTuple{48, Float64}}
    vhp60::Vector{NTuple{24, Float64}}
    vap60::Vector{NTuple{24, Float64}}
end

function urls(::Type{Hpo})
    return [
        "https://kp.gfz.de/app/files/Hp30_ap30_complete_series.txt",
        "https://kp.gfz.de/app/files/Hp60_ap60_complete_series.txt",
        "https://isdc-data.gfz.de/geomagnetism/HpoForecast/v0102/output/Hpo/json/hpo_forecast_mean_bars_Hp30.json",
        "https://isdc-data.gfz.de/geomagnetism/HpoForecast/v0102/output/Hpo/json/hpo_forecast_mean_bars_Hp60.json"
    ]
end

expiry_periods(::Type{Hpo}) = [Day(1), Day(1), Day(1), Day(1)]

function parse_files(::Type{Hpo}, filepaths::Vector{String})
    length(filepaths) == 4 ||
        error("We need exactly 4 files to parse the Hpo index set.")

    # Parse the Hp30 historical file (complete record since 1985).
    # Returns: vjd, vhp30 (as NTuple{48}), vap30 (as NTuple{48})
    vjd_hp30, vhp30, vap30 = _parse_hpo_file_daily(filepaths[1], 48)

    # Parse the Hp60 historical file (complete record since 1985).
    # Returns: vjd, vhp60 (as NTuple{24}), vap60 (as NTuple{24})
    vjd_hp60, vhp60, vap60 = _parse_hpo_file_daily(filepaths[2], 24)

    # Verify that both files have the same dates
    if vjd_hp30 != vjd_hp60
        error("Hp30 and Hp60 files have different date ranges.")
    end

    # Parse the Hp30 forecast JSON file (3-day nowcast + 3-day forecast).
    vjd_hp30_fc, vhp30_fc, vap30_fc = _parse_hpo_forecast_json(filepaths[3], 48)

    # Parse the Hp60 forecast JSON file (3-day nowcast + 3-day forecast).
    vjd_hp60_fc, vhp60_fc, vap60_fc = _parse_hpo_forecast_json(filepaths[4], 24)

    # Merge historical and forecast data
    # Only append forecast data that extends beyond historical data
    vjd_final = copy(vjd_hp30)
    vhp30_final = copy(vhp30)
    vap30_final = copy(vap30)
    vhp60_final = copy(vhp60)
    vap60_final = copy(vap60)

    last_historical_jd = isempty(vjd_hp30) ? -Inf : vjd_hp30[end]

    for (i, jd) in enumerate(vjd_hp30_fc)
        if jd > last_historical_jd
            push!(vjd_final, jd)
            push!(vhp30_final, vhp30_fc[i])
            push!(vap30_final, vap30_fc[i])
            push!(vhp60_final, vhp60_fc[i])
            push!(vap60_final, vap60_fc[i])
        end
    end

    return Hpo(
        vjd_final,
        vhp30_final,
        vap30_final,
        vhp60_final,
        vap60_final
    )
end

@register Hpo

"""
    space_index(::Val{:Hp30}, jd::Number) -> NTuple{48, Float64}

Return the Hp30 index for the day at Julian Day `jd`.

The Hp30 index represents geomagnetic activity with 30-minute resolution. This function
returns all 48 values for the day containing the given Julian Day.
"""
function space_index(::Val{:Hp30}, jd::Number)
    obj = @object(Hpo)
    knots = obj.vjd
    values = obj.vhp30
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Ap30}, jd::Number) -> NTuple{48, Float64}

Return the Ap30 index for the day at Julian Day `jd`.

The Ap30 index is the linear equivalent of Hp30 geomagnetic activity. This function
returns all 48 values for the day containing the given Julian Day.
"""
function space_index(::Val{:Ap30}, jd::Number)
    obj = @object(Hpo)
    knots = obj.vjd
    values = obj.vap30
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Hp60}, jd::Number) -> NTuple{24, Float64}

Return the Hp60 index for the day at Julian Day `jd`.

The Hp60 index represents geomagnetic activity with 60-minute (hourly) resolution. This
function returns all 24 values for the day containing the given Julian Day.
"""
function space_index(::Val{:Hp60}, jd::Number)
    obj = @object(Hpo)
    knots = obj.vjd
    values = obj.vhp60
    return constant_interpolation(knots, values, jd)
end

"""
    space_index(::Val{:Ap60}, jd::Number) -> NTuple{24, Float64}

Return the ap60 index for the day at Julian Day `jd`.

The ap60 index is the linear equivalent of Hp60 geomagnetic activity. This function
returns all 24 values for the day containing the given Julian Day.
"""
function space_index(::Val{:Ap60}, jd::Number)
    obj = @object(Hpo)
    knots = obj.vjd
    values = obj.vap60
    return constant_interpolation(knots, values, jd)
end

function _parse_hpo_file_daily(filepath::String, n_per_day::Int)
    # Dictionary to accumulate data by date
    # Key: (year, month, day), Value: Dict with interval index => (hp, ap)
    daily_data = Dict{Tuple{Int, Int, Int}, Dict{Int, Tuple{Float64, Float64}}}()

    # Open and parse the file.
    open(filepath, "r") do file
        for line in eachline(file)
            # Skip comment lines.
            startswith(line, "#") && continue

            # Parse the line.
            tokens = split(line)
            length(tokens) >= 10 || continue

            try
                # Extract fields.
                # Format: YYYY MM DD hh.h hh._m days days_m Hp ap D
                year   = parse(Int, tokens[1])
                month  = parse(Int, tokens[2])
                day    = parse(Int, tokens[3])
                hh_h   = parse(Float64, tokens[4])  # Start hour of interval
                hp     = parse(Float64, tokens[8])
                ap     = parse(Float64, tokens[9])

                # Calculate which interval this is within the day
                # For Hp30: hh_h = 0.0, 0.5, 1.0, ..., 23.5 (48 values)
                # For Hp60: hh_h = 0.0, 1.0, 2.0, ..., 23.0 (24 values)
                interval_duration = 24.0 / n_per_day  # 0.5 for Hp30, 1.0 for Hp60
                interval_index = round(Int, hh_h / interval_duration) + 1  # 1-indexed

                # Ensure the date entry exists
                date_key = (year, month, day)
                if !haskey(daily_data, date_key)
                    daily_data[date_key] = Dict{Int, Tuple{Float64, Float64}}()
                end

                # Store the values (even if missing, marked as -1)
                daily_data[date_key][interval_index] = (hp, ap)
            catch e
                # Log debug message for parsing errors but continue processing.
                @debug "Error parsing line in Hpo file: $line" exception=e
                continue
            end
        end
    end

    # Sort dates and create output vectors
    sorted_dates = sort(collect(keys(daily_data)))

    vjd = Float64[]
    vhp = NTuple{n_per_day, Float64}[]
    vap = NTuple{n_per_day, Float64}[]

    for date_key in sorted_dates
        year, month, day = date_key

        # Calculate Julian Day
        jd = datetime2julian(DateTime(year, month, day, 0, 0, 0))

        # Get the data for this day
        day_data = daily_data[date_key]

        # Build tuples for this day (initialize with NaN for missing values)
        hp_array = fill(NaN, n_per_day)
        ap_array = fill(NaN, n_per_day)

        for i in 1:n_per_day
            if haskey(day_data, i)
                hp_val, ap_val = day_data[i]
                # Replace -1 (missing marker) with NaN
                hp_array[i] = hp_val < 0 ? NaN : hp_val
                ap_array[i] = ap_val < 0 ? NaN : ap_val
            end
        end

        # Only add days that have at least some valid data
        if any(!isnan, hp_array) && any(!isnan, ap_array)
            push!(vjd, jd)
            push!(vhp, Tuple(hp_array))
            push!(vap, Tuple(ap_array))
        end
    end

    return vjd, vhp, vap
end

function _hp_to_ap(hp::Float64)
    # Conversion table from Hp to ap (linear equivalent)
    # Based on the actual Hp to ap conversion from GFZ data
    # Reference: Yamazaki & Matzka (2022), GRL
    # Data source: https://kp.gfz.de/app/files/Hp30_ap30_complete_series.txt

    isnan(hp) && return NaN

    # Round hp to nearest 1/3 to match the discrete values
    hp_rounded = round(hp * 3) / 3

    # Find exact match in the table
    for i in 1:length(HP_VALUES)
        if abs(hp_rounded - HP_VALUES[i]) < 0.01  # Small tolerance for floating point comparison
            return Float64(AP_VALUES[i])
        end
    end

    # If no exact match, find the nearest lower value
    for i in length(HP_VALUES):-1:1
        if hp_rounded >= HP_VALUES[i]
            return Float64(AP_VALUES[i])
        end
    end

    return 0.0
end

function _parse_hpo_forecast_json(filepath::String, n_per_day::Int)
    # Read and parse the JSON file
    json_data = JSON.parsefile(filepath)::Dict{String, Any}

    # Use MEDIAN forecast values
    median_data = json_data["MEDIAN"]::Dict{String, Any}

    # Dictionary to accumulate data by date
    daily_data = Dict{Tuple{Int, Int, Int}, Dict{Int, Float64}}()

    # Parse timestamps and Hp values
    for (timestamp_str, hp_value) in median_data
        # Parse timestamp: "2025-10-21T22:00:00.000"
        dt = DateTime(timestamp_str[1:19], "yyyy-mm-ddTHH:MM:SS")
        year = Dates.year(dt)
        month = Dates.month(dt)
        day = Dates.day(dt)
        hour = Dates.hour(dt)
        minute = Dates.minute(dt)

        # Calculate which interval this is within the day
        interval_duration = 24.0 / n_per_day  # 0.5 for Hp30, 1.0 for Hp60
        hour_decimal = hour + minute / 60.0
        interval_index = round(Int, hour_decimal / interval_duration) + 1  # 1-indexed

        # Ensure the date entry exists
        date_key = (year, month, day)
        if !haskey(daily_data, date_key)
            daily_data[date_key] = Dict{Int, Float64}()
        end

        # Store the Hp value
        daily_data[date_key][interval_index] = hp_value
    end

    # Sort dates and create output vectors
    sorted_dates = sort(collect(keys(daily_data)))

    vjd = Float64[]
    vhp = NTuple{n_per_day, Float64}[]
    vap = NTuple{n_per_day, Float64}[]

    for date_key in sorted_dates
        year, month, day = date_key

        # Calculate Julian Day at midnight
        jd = datetime2julian(DateTime(year, month, day, 0, 0, 0))

        # Get the data for this day
        day_data = daily_data[date_key]

        # Build tuples for this day (initialize with NaN for missing values)
        hp_array = fill(NaN, n_per_day)
        ap_array = fill(NaN, n_per_day)

        for i in 1:n_per_day
            if haskey(day_data, i)
                hp_val = day_data[i]
                hp_array[i] = hp_val < 0 ? NaN : hp_val
                # Convert Hp to ap
                ap_array[i] = _hp_to_ap(hp_val)
            end
        end

        # Only add days that have at least some valid data
        if any(!isnan, hp_array)
            push!(vjd, jd)
            push!(vhp, Tuple(hp_array))
            push!(vap, Tuple(ap_array))
        end
    end

    return vjd, vhp, vap
end


