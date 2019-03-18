module TreeTools

## Includes
include("objects.jl")
include("objectsmethods.jl")
include("prunegraft.jl")
include("datamethods.jl")
include("reading.jl")
include("writing.jl")
include("misc.jl")

end

## Todo
# Separate general trees and binary trees 
# See if it would be interesting to use sets instead of arrays in some datamethods or objectmethods functions
# the child field of `TreeNode` should be a set and not an array since ordering is not relevant? Howver it makes accessing more difficult. For now, giving up on this idea since I do not benefit from `Set` specific function implemented in Julia: they ultimately fall back to `===` which will consider equal nodes to be different. 
# Indexing nodes using integers is *very* confusing! For different trees, the same individual will have different indices which makes it a mess to compare things. Leaves at least should be identified by their label

