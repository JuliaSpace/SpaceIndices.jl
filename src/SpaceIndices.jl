module SpaceIndices

using Reexport
using Scratch

@reexport using Dates
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

include("./api.jl")
include("./destroy.jl")
include("./download.jl")
include("./initialize.jl")
include("./interpolations.jl")

include("./space_index_sets/fluxtable.jl")
include("./space_index_sets/jb2008.jl")
include("./space_index_sets/kp_ap.jl")

end # module SpaceIndices