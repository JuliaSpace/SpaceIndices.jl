module SpaceIndices

using Dates
using Interpolations
using Reexport
using Scratch

@reexport using OptionalData

############################################################################################
#                                          Types
############################################################################################

include("./types.jl")

############################################################################################
#                                        Constants
############################################################################################

# Global vector to store the registered space files.
const _SPACE_INDEX_SETS = NTuple{2, Any}[]

############################################################################################
#                                         Includes
############################################################################################

include("./helpers.jl")

include("./api.jl")
include("./destroy.jl")
include("./download.jl")
include("./initialize.jl")

include("./space_index_sets/fluxtable.jl")
include("./space_index_sets/jb2008.jl")

end # module SpaceIndices
