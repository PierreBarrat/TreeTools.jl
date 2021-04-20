struct Mutation
	i::Int64
	old
	new
end
function Mutation(x::Tuple{Int64,Any,Any})
	return Mutation(x[1],x[2],x[3])
end

function ==(x::Mutation, y::Mutation)
	mapreduce(f->getfield(x,f)==getfield(y,f), *, fieldnames(Mutation), init=true)
end
isequal(x::Mutation, y::Mutation) = (==(x,y))

reverse(x::Mutation) = Mutation(x.i, x.new. x.old)
function isreverse(x::Mutation, y::Mutation)
	(x.i == y.i) && (x.old == y.new) && (x.new == y.old)
end


function parse_mutation(mut::AbstractString)
	oldstate = mut[1]
	newstate = mut[end]
	pos = parse(Int64, mut[2:end-1])
	return Mutation(pos, oldstate, newstate)
end
parse_mutation(mut::Mutation) = mut


function compute_mutations!(f::Function, n::TreeNode, outkey)
	n.isroot && return nothing
	n.data.dat[outkey] = Array{Mutation,1}(undef, 0)
	for (i,a) in enumerate(f(n))
		if a != f(n.anc)[i]
			TreeTools.recursive_push!(n.data.dat, Mutation(i, f(n.anc)[i], a), outkey)
		end
	end
	nothing
end

"""
	compute_mutations!(t::Tree, seqkey, outkey)
"""
function compute_mutations!(f::Function, t::Tree, outkey)
	for n in values(t.lnodes)
		compute_mutations!(f, n, outkey)
	end
end


