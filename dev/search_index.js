var documenterSearchIndex = {"docs":
[{"location":"man/get/#Obtaining-the-Space-Indices","page":"Get space indices","title":"Obtaining the Space Indices","text":"","category":"section"},{"location":"man/get/","page":"Get space indices","title":"Get space indices","text":"CurrentModule = SpaceIndices\nDocTestSetup = quote\n    using Dates\n    using SpaceIndices\nend","category":"page"},{"location":"man/get/","page":"Get space indices","title":"Get space indices","text":"After the initialization shown in Initialization of Space Indices, the user can obtain the space index value using the function:","category":"page"},{"location":"man/get/","page":"Get space indices","title":"Get space indices","text":"function space_index(::Val{:index}, jd::Number; kwargs...) -> Number\nfunction space_index(::Val{:index}, instant::DateTime; kwargs...) -> Number","category":"page"},{"location":"man/get/","page":"Get space indices","title":"Get space indices","text":"where index is the desired space index and jd is the Julian Day to obtain the information. The latter can also be specified using instant, which is a DateTime object.","category":"page"},{"location":"man/get/","page":"Get space indices","title":"Get space indices","text":"julia> SpaceIndices.init()\n\njulia> space_index(Val(:F10adj), DateTime(2020, 6, 19))\n71.1\n\njulia> space_index(Val(:F10adj), 2.4590195e6)\n71.1","category":"page"},{"location":"man/get/","page":"Get space indices","title":"Get space indices","text":"The following space indices are currently supported:","category":"page"},{"location":"man/get/","page":"Get space indices","title":"Get space indices","text":"Space Index Set Index Description Unit\nCelestrak F10obs Observed F10.7 (10.7-cm solar flux) 10⁻²² W / (M² ⋅ Hz)\n F10adj Adjusted F10.7 (10.7-cm solar flux) 10⁻²² W / (M² ⋅ Hz)\n f107_obs_avg_center81 Observed F10.7 (10.7-cm solar flux) averaged over 81 days centered 10⁻²² W / (M² ⋅ Hz)\n f107_obs_avg_last81 Observed F10.7 (10.7-cm solar flux) averaged over 81 last days 10⁻²² W / (M² ⋅ Hz)\n f107_adj_avg_center81 Observed F10.7 (10.7-cm solar flux) averaged over 81 days centered 10⁻²² W / (M² ⋅ Hz)\n f107_adj_avg_last81 Observed F10.7 (10.7-cm solar flux) averaged over 81 last days 10⁻²² W / (M² ⋅ Hz)\n Ap Ap index computed every three hours. \n Ap_daily Daily Ap index. \n Kp Kp index computed every three hours. \n Kp_daily Daily Kp index. \n Cp Daily Planetary Character Figure \n C9 Daily Magnetic Index on Cp Basis \n ISN International Sunspot Number \n BSRN Bartels Solar Rotation Number \n ND Number of Days into Bartels Solar Rotation Cycle Days\nJB2008 DTC Exospheric temperature variation caused by the Dst index. K\n S10 EUV index (26-34 nm) scaled to F10.7 10⁻²² W / (M² ⋅ Hz)\n M10 MG2 index scaled to F10.7. 10⁻²² W / (M² ⋅ Hz)\n Y10 Solar X-ray & Lya index scaled to F10.7 10⁻²² W / (M² ⋅ Hz)\n S81a 81-day averaged EUV index (26-34 nm) scaled to F10.7 10⁻²² W / (M² ⋅ Hz)\n M81a 81-day averaged MG2 index scaled to F10.7. 10⁻²² W / (M² ⋅ Hz)\n Y81a 81-day averaged solar X-ray & Lya index scaled to F10.7 10⁻²² W / (M² ⋅ Hz)","category":"page"},{"location":"man/initialization/#Initialization-of-Space-Indices","page":"Initialization","title":"Initialization of Space Indices","text":"","category":"section"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"CurrentModule = SpaceIndices\nDocTestSetup = quote\n    using SpaceIndices\nend","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"The files of all the registered space indices can be automatically downloaded using:","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"function SpaceIndices.init(; kwargs...) -> Nothing","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"If a file exists, the function checks if its expiry period has passed. If so, it downloads the file again.","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"julia> SpaceIndices.init()","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"If the user does not want to download a set of space indices, they can pass them in the keyword blocklist to the function SpaceIndices.init.","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"julia> SpaceIndices.init(; blocklist = [SpaceIndices.Celestrak])","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"If the user wants to initialize only one space index set, they can pass it to the same function:","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"function SpaceIndices.init(::Type{T}; force_download::Bool = true) where T<:SpaceIndexSet -> Nothing","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"where T must be the space index set. In this case, the user have access to the keyword force_download. If it is true, the remote files will be download regardless their timestamp.","category":"page"},{"location":"man/initialization/","page":"Initialization","title":"Initialization","text":"julia> SpaceIndices.init()\n[ Info: Downloading the file 'DTCFILE.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/DTCFILE.TXT'...\n[ Info: Downloading the file 'SOLFSMY.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/SOLFSMY.TXT'...\n[ Info: Downloading the file 'SW-All.csv' from 'https://celestrak.org/SpaceData/SW-All.csv'...\n","category":"page"},{"location":"lib/library/#Library","page":"Library","title":"Library","text":"","category":"section"},{"location":"lib/library/","page":"Library","title":"Library","text":"Documentation for SpaceIndices.jl.","category":"page"},{"location":"lib/library/","page":"Library","title":"Library","text":"Modules = [SpaceIndices]","category":"page"},{"location":"lib/library/#SpaceIndices.SpaceIndexSet","page":"Library","title":"SpaceIndices.SpaceIndexSet","text":"abstract type SpaceIndexSet\n\nAbstract type for all structures that represent space index sets.\n\n\n\n\n\n","category":"type"},{"location":"lib/library/#SpaceIndices.constant_interpolation-Union{Tuple{Tk}, Tuple{AbstractVector{Tk}, AbstractVector, Tk}} where Tk","page":"Library","title":"SpaceIndices.constant_interpolation","text":"constant_interpolation(knots::Vector{Date}, values::AbstractVector, x::Date) -> eltype(values)\n\nPerform a constant interpolation at x of values evaluated at knots. The interpolation returns value(knots[k-1]) in which knots[k-1] <= x < knots[k].\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.destroy-Tuple{}","page":"Library","title":"SpaceIndices.destroy","text":"destroy() -> Nothing\n\nDestroy the objects of all space index sets that were initialized.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.expiry_periods","page":"Library","title":"SpaceIndices.expiry_periods","text":"expiry_periods(::Type{T}) where T<:SpaceIndexSet -> Vector{DatePeriod}\n\nReturn the expiry periods for the remote files associated with the space index set T. If a time interval greater than this period has elapsed since the last download, the remote files will be downloaded again.\n\n\n\n\n\n","category":"function"},{"location":"lib/library/#SpaceIndices.filenames-Union{Tuple{Type{T}}, Tuple{T}} where T<:SpaceIndexSet","page":"Library","title":"SpaceIndices.filenames","text":"filenames(::Type{T}) where T<:SpaceIndexSet -> Vector{String}\n\nReturn the filenames for the remote files associated with the space index set T. If this function is not defined for T, the filenames will be obtained based on the URLs.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.init-Tuple{}","page":"Library","title":"SpaceIndices.init","text":"init(; blocklist::Vector = []) -> Nothing\n\nInitialize all the registered space index sets.\n\nThis function will download the remote files associated to the space index sets if they do not exist or if the expiry period has been elapsed. Aftward, it will parse the files and populate the objects to be accessed by the function space_index.\n\nIf the user does not want to initialize some sets, they can pass them in the keyword blocklist.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.init-Union{Tuple{Type{T}}, Tuple{T}} where T<:SpaceIndexSet","page":"Library","title":"SpaceIndices.init","text":"init(::Type{T}; kwargs...) where T<:SpaceIndexSet -> Nothing\n\nInitialize the space index set T.\n\nThis function will download the remote files associated with the space index set T if they do not exist or if their expiry period has been elapsed. Aftward, it will parse the files and populate the object to be accessed by the function space_index.\n\nKeywords\n\nforce_download::Bool: If true, the remote files will be downloaded regardless of their   timestamps. (Default = false)\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.linear_interpolation-Union{Tuple{Tv}, Tuple{Tk}, Tuple{AbstractVector{Tk}, AbstractVector{Tv}, Tk}} where {Tk, Tv}","page":"Library","title":"SpaceIndices.linear_interpolation","text":"linear_interpolation(knots::AbstractVector{Tk}, values::AbstractVector{Tv}, x::Tk) where {Tk, Tv}\n\nPerform a linear interpolation at x of values evaluated at knots.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.parse_files","page":"Library","title":"SpaceIndices.parse_files","text":"parse_files(::Type{T}, filepaths::Vector{String}) where T<:SpaceIndexSet -> T\n\nParse the files associated with the space index set T using the files in filepaths. It must return an object of type T with the parsed data.\n\n\n\n\n\n","category":"function"},{"location":"lib/library/#SpaceIndices.roundKp-Tuple{Float64}","page":"Library","title":"SpaceIndices.roundKp","text":"Celestrak Mulitples Kp by 10 and rounds to the nearest integer this puts it back\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:index}, jd::Number; kwargs...) -> Number\nspace_index(::Val{:index}, instant::DateTime; kwargs...) -> Number\n\nGet the space index for the Julian day jd or the instant. The latter must be an object of type DateTime. kwargs... can be used to pass additional configuration for the space index.\n\n\n\n\n\n","category":"function"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:Ap_daily}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:Ap_daily}, instant::DateTime) -> Int64\n\nGet the daily Ap index for the day at instant.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:Ap}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:Ap}, instant::DateTime) -> NTuple{8, Float64}\n\nGet the Ap index for the day at `instant` compute every three hours.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:BSRN}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:BSRN}, instant::DateTime) -> Int64\n\nGet the BSRN index for the day at instant\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:C9}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:C9}, instant::DateTime) -> Float64\n\nGet the C9 index for the day at instant\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:Cp}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:Cp}, instant::DateTime) -> Float64\n\nGet the Cp index for the day at instant\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:DTC}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:DTC}, instant::DateTime) -> Float64\n\nGet the exospheric temperature variation [K] caused by the Dst index at instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:F10adj_avg_center81}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:F10adj_avg_center81}, instant::DateTime) -> Float64\n\nGet the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over 81 days centered for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:F10adj_avg_last81}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:F10adj_avg_last81}, instant::DateTime) -> Float64\n\nGet the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over the last 81 days for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:F10adj}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:F10adj}, instant::DateTime) -> Float64\n\nGet the adjusted F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:F10obs_avg_center81}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:F10obs_avg_center81}, instant::DateTime) -> Float64\n\nGet the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over 81 days centered for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:F10obs_avg_last81}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:F10obs_avg_last81}, instant::DateTime) -> Float64\n\nGet the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] averaged over the last 81 days for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:F10obs}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:F10obs}, instant::DateTime) -> Float64\n\nGet the observed F10.7 index (10.7-cm solar flux) [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:ISN}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:ISN}, instant::DateTime) -> Int64\n\nGet the ISN index for the day at instant\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:Kp_daily}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:Kp_daily}, instant::DateTime) -> Float64\n\nGet the daily Kp index for the day at instant.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:Kp}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:Kp}, instant::DateTime) -> NTuple{8, Float64}\n\nGet the Kp index for the day at `instant` compute every three hours.\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:M10}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"get_space_index(::Val{:M10}, instant::DateTime) -> Float64\n\nGet the MG2 index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:M81a}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:M81a}, instant::DateTime) -> Float64\n\nGet the 81-day averaged MG2 index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:ND}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:ND}, instant::DateTime) -> Int64\n\nGet the ND index for the day at instant\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:S10}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:S10}, instant::DateTime) -> Float64\n\nGet the EUV index (26-34 nm) scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:S81a}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:S81a}, instant::DateTime) -> Float64\n\nGet the 81-day averaged EUV index (26-34 nm) scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:Y10}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:Y10}, instant::DateTime) -> Float64\n\nGet the solar X-ray & Lya index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.space_index-Tuple{Val{:Y81a}, DateTime}","page":"Library","title":"SpaceIndices.space_index","text":"space_index(::Val{:Y81a}, instant::DateTime) -> Float64\n\nGet the 81-day averaged solar X-ray & Lya index scaled to F10.7 [10⁻²² W / (M² ⋅ Hz)] for the instant (UTC).\n\n\n\n\n\n","category":"method"},{"location":"lib/library/#SpaceIndices.urls","page":"Library","title":"SpaceIndices.urls","text":"urls(::Type{T}) where T<:SpaceIndexSet -> Vector{String}\n\nReturn the URLs to fetch the remote files associated with the space index set T.\n\n\n\n\n\n","category":"function"},{"location":"lib/library/#SpaceIndices.@data_handler-Tuple{Any}","page":"Library","title":"SpaceIndices.@data_handler","text":"@data_handler(T)\n\nReturn the optional data handler associated with space index set T. This variable stores an instance of T if the set was already initialized.\n\n\n\n\n\n","category":"macro"},{"location":"lib/library/#SpaceIndices.@object-Tuple{Any}","page":"Library","title":"SpaceIndices.@object","text":"@object(T)\n\nReturn the object associated with the space index set T.\n\nThrows\n\nError: If the space index T was not initialized.\n\n\n\n\n\n","category":"macro"},{"location":"lib/library/#SpaceIndices.@register-Tuple{Any}","page":"Library","title":"SpaceIndices.@register","text":"@register(T)\n\nRegister the the space index set T. This macro push the data into the global vector of space files and also creates the optional data handler for the processed structure.\n\n\n\n\n\n","category":"macro"},{"location":"#SpaceIndices.jl","page":"Home","title":"SpaceIndices.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package allows to automatically fetch and parse space indices.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The space index sets supported in this version are:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Space Index Set File Expiry period Information\nCelestrak SW-All.csv 1 day F10.7 flux data (observed and adjusted). Kp and Ap an\n   Derived indices. Some Sun Indicies.\n   Historic and Predicted for all.\nJB2008 DTCFILE.TXT 1 day Exospheric temperature variation caused by the Dst index.\n SOLFSMY.TXT 1 day Indices necessary for the JB2008 atmospheric model.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package can be installed using:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> using Pkg\njulia> Pkg.add(\"SpaceIndices\")","category":"page"},{"location":"man/api/#SpaceIndices.jl-API","page":"API","title":"SpaceIndices.jl API","text":"","category":"section"},{"location":"man/api/","page":"API","title":"API","text":"CurrentModule = SpaceIndices\nDocTestSetup = quote\n    using SpaceIndices\nend","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"This package defines an API to allow user to defin new space indices. We describe this API in the following.","category":"page"},{"location":"man/api/#Structure","page":"API","title":"Structure","text":"","category":"section"},{"location":"man/api/","page":"API","title":"API","text":"Each space index set must have a structure that has SpaceIndexSet as its super-type. This structure must contain all the required field to process and return the indices provided by the set.","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"struct MySpaceIndex <: SpaceIndexSet\n    ...\nend","category":"page"},{"location":"man/api/#Required-API-Functions","page":"API","title":"Required API Functions","text":"","category":"section"},{"location":"man/api/","page":"API","title":"API","text":"We must define the following functions for every space index set defined as in the previous section.","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"function SpaceIndices.urls(::Type{T}) where T<:SpaceIndexFile -> Vector{String}","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"This function must return a Vector{String} with the URLs to download the files for the indices. For example:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"SpaceIndices.urls(::Type{MySpaceIndex}) = [\"https://url.for.my/space.file.txt\"]","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"function SpaceIndices.expiry_periods(::Type{T}) where T<:SpaceIndexFile -> Vector{DatePeriod}","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"This function must return the list with the expiry periods for the files in the space index set T. The remote files will always be downloaded if a time greater than this period has elapsed after the last download. For example:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"get_filenames(::Type{MySpaceIndex}) = [Day(7)]","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"SpaceIndices.parse_files(::Type{T}, filepaths::Vector{String}) where T<:SpaceIndexFile -> T","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"This function must parse the files related to the space index set T using the files in filepaths and return an instance of T with the parsed data. For example,","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"function SpaceIndices.parse_files(::Type{MySpaceIndex}, filepaths::Vector{String})\n    for filepath in filepaths\n        open(filepath, \"r\") do f\n            ...\n        end\n    end\n        \n    return MySpaceIndex(...)\nend","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"Finally, the new space index set must also implement a set of functions with the following signature:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"SpaceIndices.space_index(::Val{:index}, instant::DateTime; kwargs...) -> Number","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"where the space index for the instant will be returned.","category":"page"},{"location":"man/api/#Optional-API-Functions","page":"API","title":"Optional API Functions","text":"","category":"section"},{"location":"man/api/","page":"API","title":"API","text":"function SpaceIndices.filenames(::Type{T}) where T<:SpaceIndexFile -> Vector{String}","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"This function can return a Vector{String} with the names of the remote files. The system will used this information to save the data in the package scratch space.  For example:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"SpaceIndices.filenames(::Type{MySpaceIndex}) = [\"my_space_file.txt\"]","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"If this function is not defined, the filename will be obtained from the URL using the function basename.","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"warning: Warning\nAll functions that return a Vector must return an array with the same number of elements.","category":"page"},{"location":"man/api/#Example:-Leap-Seconds","page":"API","title":"Example: Leap Seconds","text":"","category":"section"},{"location":"man/api/","page":"API","title":"API","text":"We will use the API to define a new space index set that has the GPS leap seconds. The file has a CSV-like format but the values are separated by ;. It has two columns. The first contains the Julian days in which the leap seconds were modified to the values in the second column:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"Julian Day;Leap Seconds\n2441499.500000;11.0\n2441683.500000;12.0\n2442048.500000;13.0\n2442413.500000;14.0\n...","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"First, we need to load the required packages to process the information in the space index file:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"julia> using DelimitedFiles, Dates","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"Now, we need to create its structure:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"struct LeapSeconds <: SpaceIndexSet\n    jd::Vector{Float64}\n    leap_seconds::Vector{Float64}\nend","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"where jd contains the Julian days in which the leap seconds were modified to the values in leap_seconds.","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"We also need to overload the API functions:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"SpaceIndices.urls(::Type{LeapSeconds}) = [\"https://ronanarraes.com/space-indices/leap_seconds.csv\"]\nSpaceIndices.expiry_periods(::Type{LeapSeconds}) = [Day(365)]\n\nfunction SpaceIndices.parse_file(::Type{LeapSeconds}, filepaths::Vector{String})\n    filepath = first(filepaths)\n    raw_data, ~ = readdlm(filepath, ';'; header = true)\n    return LeapSeconds(raw_data[:, 1], raw_data[:, 2])\nend","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"We also need to populate the function space_index with the supported index in this file:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"function SpaceIndices.space_index(::Val{:LeapSeconds}, instant::DateTime)\n    obj = SpaceIndices.@object(LeapSeconds)\n    jd = datetime2julian(instant)\n    id = findfirst(>=(jd_utc), obj.jd)\n\n    if isnothing(id)\n        id = length(obj.jd)\n    end\n\n    return obj.leap_seconds[id]\nend","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"Finally, we need to register the new space index file:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"SpaceIndices.@register LeapSeconds","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"We can now use the SpaceIndices.jl system to fetch the information:","category":"page"},{"location":"man/api/","page":"API","title":"API","text":"julia> SpaceIndices.init()\n[ Info: Downloading the file 'DTCFILE.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/DTCFILE.TXT'...\n[ Info: Downloading the file 'SOLFSMY.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/SOLFSMY.TXT'...\n[ Info: Downloading the file 'SW-All.csv' from 'https://celestrak.org/SpaceData/SW-All.csv'...\n\njulia> space_index(Val(:LeapSeconds), now())\n37.0","category":"page"},{"location":"man/quick_start/#Quick-Start","page":"Quick start","title":"Quick Start","text":"","category":"section"},{"location":"man/quick_start/","page":"Quick start","title":"Quick start","text":"CurrentModule = SpaceIndices\nDocTestSetup = quote\n    using SpaceIndices\nend","category":"page"},{"location":"man/quick_start/","page":"Quick start","title":"Quick start","text":"This quick tutorial will show how to use SpaceIndicies.jl to obtain the F10.7 index at 2020-06-19.","category":"page"},{"location":"man/quick_start/","page":"Quick start","title":"Quick start","text":"First, we need to initialize all the space indices:","category":"page"},{"location":"man/quick_start/","page":"Quick start","title":"Quick start","text":"julia> SpaceIndices.init()\n[ Info: Downloading the file 'DTCFILE.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/DTCFILE.TXT'...\n[ Info: Downloading the file 'SOLFSMY.TXT' from 'http://sol.spacenvironment.net/jb2008/indices/SOLFSMY.TXT'...\n[ Info: Downloading the file 'SW-All.csv' from 'https://celestrak.org/SpaceData/SW-All.csv'...","category":"page"},{"location":"man/quick_start/","page":"Quick start","title":"Quick start","text":"Afterward, we can obtain the desired space index using:","category":"page"},{"location":"man/quick_start/","page":"Quick start","title":"Quick start","text":"julia> space_index(Val(:F10adj), DateTime(2020, 6, 19))\n71.1","category":"page"}]
}
