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


function compute_mutations!(n::TreeNode, seqkey, outkey)
	n.isroot && return nothing
	n.data.dat[outkey] = Array{Mutation,1}(undef, 0)
	for (i,a) in enumerate(n.data.dat[seqkey])
		if a != n.anc.data.dat[seqkey][i]
			push!(n.data.dat[outkey], Mutation(i, n.anc.data.dat[seqkey][i], a))
		end
	end
	nothing
end
function compute_mutations!(n::TreeNode, seqkey::Tuple, outkey::Tuple)
	n.isroot && return nothing
	muts = Array{Mutation,1}(undef,0)
	seq = recursive_get(n.data.dat, seqkey...)
	aseq = recursive_get(n.anc.data.dat, seqkey...)
	for (i, (a,b)) in enumerate(zip(seq, aseq))
		if a != b
			push!(muts, Mutation(i, n.anc.data.dat[seqkey][i], a))
		end
	end	
	recursive_set!(n.data.dat, muts, outkey...)
	nothing
end
"""
	compute_mutations!(t::Tree, seqkey, outkey)
"""
function compute_mutations!(t::Tree, seqkey, outkey)
	for n in values(tree.lnodes)
		compute_mutations!(n, seqkey, outkey)
	end
end


