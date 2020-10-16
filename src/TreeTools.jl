module TreeTools


using FastaIO
using JSON
using Dates
using Distributions
## Includes
include("objects.jl")
include("objectsmethods.jl")
include("mutations.jl")
include("prunegraft.jl")
include("reading.jl")
include("writing.jl")
include("misc.jl")
include("lbi.jl")
include("splits.jl") # Implementation of branches as splits of the leaf nodes. Allows one to check if a branch in one tree is also in another. 


end

## Todo
# the child field of `TreeNode` should be a set and not an array since ordering is not relevant? Howver it makes accessing more difficult. For now, giving up on this idea since I do not benefit from `Set` specific function implemented in Julia: they ultimately fall back to `===` which will consider equal nodes to be different. 
