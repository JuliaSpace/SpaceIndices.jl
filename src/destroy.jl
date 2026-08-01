## Description #############################################################################
#
# Function to destroy all space indices.
#
############################################################################################

"""
    destroy() -> Nothing

Destroy the objects of all space index sets that were initialized.
"""
function destroy()
    # The vector `_SPACE_INDEX_SETS` contains a set of `Tuple`s with the space file
    # structure and its optional data handler.
    for (_, handler) in _SPACE_INDEX_SETS
        handler.data = nothing
    end

    return nothing
end
