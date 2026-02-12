module SpaceIndices

using DelimitedFiles
using Downloads
using JSON
using Reexport
using Scratch

import Downloads: download

@reexport using Dates
@reexport using OptionalData

############################################################################################
#                                          Types                                           #
############################################################################################

include("./types.jl")

############################################################################################
#                                        Constants                                         #
############################################################################################

# Global vector to store the registered space files.
const _SPACE_INDEX_SETS = NTuple{2, Any}[]

############################################################################################
#                                         Includes                                         #
############################################################################################

include("./api.jl")
include("./destroy.jl")
include("./download.jl")
include("./initialize.jl")
include("./interpolations.jl")

include("./space_index_sets/jb2008.jl")
include("./space_index_sets/celestrak.jl")
include("./space_index_sets/hpo.jl")
include("./space_index_sets/dst.jl")

end # module SpaceIndices
