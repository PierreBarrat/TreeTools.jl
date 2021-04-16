module TreeTools


using FastaIO # Needed?
using FASTX
using JSON
using Dates
using Distributions
using Debugger
using BioSequences

##
import Base.iterate, Base.length, Base.isequal, Base.in, Base.getindex, Base.setdiff, Base.lastindex, Base.isempty
import Base: ==, unique, unique!, Base.cat, Base.intersect
## Includes
include("objects.jl")
include("objectsmethods.jl")
include("iterators.jl")
include("mutations.jl")
include("prunegraft.jl")
include("reading.jl")
include("writing.jl")
include("misc.jl")
include("lbi.jl")
include("splits.jl") 
include("resolving.jl")
include("sequences.jl")


end

