module TreeTools


using FastaIO
using JSON
using Dates
using Distributions


##
import Base.iterate, Base.length, Base.isequal, Base.in, Base.getindex, Base.setdiff, Base.lastindex, Base.isempty
import Base: ==
## Includes
include("objects.jl")
include("objectsmethods.jl")
include("mutations.jl")
include("prunegraft.jl")
include("reading.jl")
include("writing.jl")
include("misc.jl")
include("lbi.jl")
include("splits.jl") 


end

