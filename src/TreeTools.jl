module TreeTools

using Dates
## Includes
include("objects.jl")
include("objectsmethods.jl")
include("mutations.jl")
include("prunegraft.jl")
include("datamethods.jl")
include("reading.jl")
include("writing.jl")
include("misc.jl")
include("lbi.jl")

end

## Todo
# the child field of `TreeNode` should be a set and not an array since ordering is not relevant? Howver it makes accessing more difficult. For now, giving up on this idea since I do not benefit from `Set` specific function implemented in Julia: they ultimately fall back to `===` which will consider equal nodes to be different. 


