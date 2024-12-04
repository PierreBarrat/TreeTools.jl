module Generate

using ArgCheck
using Distributions
using StatsBase
using TreeTools

include("simple_shapes.jl")
export star_tree, balanced_binary_tree, ladder_tree

include("coalescent.jl")
export Coalescent, KingmanCoalescent, YuleCoalescent
export coalescence_times, genealogy

include("birth_death.jl")
export birth_death

end
