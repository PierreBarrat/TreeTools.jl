
"""
	struct Mutation{T}

```
	i::Int
	old::T
	new::T
```
"""
struct Mutation{T}
	i::Int
	old::T
	new::T
end
function Mutation(x::Tuple{Int,T,T} where T)
	return Mutation(x[1],x[2],x[3])
end

function Base.:(==)(x::Mutation, y::Mutation)
	mapreduce(f->getfield(x,f)==getfield(y,f), *, fieldnames(Mutation), init=true)
end
Base.isequal(x::Mutation, y::Mutation) = (==(x,y))
Base.reverse(x::Mutation) = Mutation(x.i, x.new. x.old)
function isreverse(x::Mutation, y::Mutation)
	(x.i == y.i) && (x.old == y.new) && (x.new == y.old)
end


function parse_mutation(mut::AbstractString)
	oldstate = mut[1]
	newstate = mut[end]
	pos = parse(Int, mut[2:end-1])
	return Mutation(pos, oldstate, newstate)
end
function parse_mutation(mut::AbstractString, ::Val{T}) where T
	oldstate = mut[1]
	newstate = mut[end]
	pos = parse(Int, mut[2:end-1])
	return Mutation{T}(pos, oldstate, newstate)
end
parse_mutation(mut::AbstractString, T) = parse_mutation(mut, Val(T))
parse_mutation(mut::Mutation) = mut


function compute_mutations!(f::Function, n::TreeNode, outkey, T=eltype(f(n));
	ignore_gaps=true
)
	TreeTools.recursive_set!(n.data.dat, Array{Mutation,1}(undef, 0), outkey)
	n.isroot && return nothing
	for (i,a) in enumerate(f(n))
		if a != f(n.anc)[i] && (!ignore_gaps || (!isgap(a) && !isgap(f(n.anc)[i])))
			TreeTools.recursive_push!(n.data.dat, Mutation{T}(i, f(n.anc)[i], a), outkey)
		end
	end
	nothing
end

"""
	compute_mutations!(f::Function, t::Tree{MiscData}, outkey, T)
	compute_mutations!(f::Function, t::Tree{MiscData}, outkey)

Compute mutations on each branch of `t`. Store result at `n.data.dat[outkey]`
For each `TreeNode` `n`, sequence is accessed by calling `f(n)`.
`T` defines the type of `Mutation{T}`.
"""
function compute_mutations!(f::Function, t::Tree{MiscData}, outkey, T)
	for n in values(t.lnodes)
		compute_mutations!(f, n, outkey, T)
	end
end
function compute_mutations!(f::Function, t::Tree{MiscData}, outkey)
	for n in values(t.lnodes)
		compute_mutations!(f, n, outkey)
	end
end

