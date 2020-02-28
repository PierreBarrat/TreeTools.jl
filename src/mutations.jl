export compute_mutations!, make_mutdict!, make_mutdict

"""
	compute_mutations(tree::Tree{EvoData})

Compute mutation on each branch of `tree`. Each node of `tree` must have a sequence. 
"""
function compute_mutations!(tree::Tree{EvoData})
	for n in values(tree.nodes)
		if !n.isroot
			if 	isempty(n.data.sequence) || isempty(n.anc.data.sequence)
				error("Node $(n.label) or its ancestor does not have a sequence.")
			elseif length(n.data.sequence) != length(n.anc.data.sequence)
				error("Node $(n.label) and its ancestor do not have sequences of the same length")
			else
				if !isempty(n.data.mutations)
					n.data.mutations = Array{Mutation,1}(undef, 0)
				end
				for i in 1:length(n.data.sequence)
					if n.data.sequence[i] != n.anc.data.sequence[i]
						push!(n.data.mutations, Mutation(i, n.anc.data.sequence[i], n.data.sequence[i]))
					end
				end
			end
		end
	end
end

"""
"""
function make_mutdict!(tree::Tree{EvoData}, labellist)
	compute_mutations!(tree)
	mutdict = Dict{Tuple{Int64,Int64,Int64}, Int64}()
	for l in labellist
		for m in tree.lnodes[l].data.mutations
			key = map(f->getfield(m, f), fieldnames(Mutation))
			mutdict[key] = get(mutdict, key, 0) + 1 
		end
	end	
	return mutdict
end

"""
	make_mutdict!(tree:Tree{EvoData})

Make a dictionary of mutations that appear in `tree`, mapping each mutation to the number of times it appears. 
"""
function make_mutdict!(tree::Tree{EvoData}; gaps=false)
	compute_mutations!(tree)
	mutdict = Dict{Tuple{Int64,Int64,Int64}, Int64}()
	mutloc = Dict{Tuple{Int64,Int64,Int64}, Array{String,1}}()
	make_mutdict!(mutdict, mutloc, tree.root, gaps)
	return mutdict, mutloc
end

"""
"""
function make_mutdict!(mutdict, mutloc, node::TreeNode{EvoData}, gaps::Bool)
	for m in node.data.mutations
		key = map(f->getfield(m, f), fieldnames(Mutation))
		if !gaps || key[2]<5 || key[3]<5
			mutdict[key] = get(mutdict, key, 0) + 1 
			if length(get(mutloc,key,[])) == 0
				mutloc[key] = [node.label]
			else
				push!(mutloc[key], node.label)
			end
		end
	end
	if !node.isleaf
		for c in node.child
			make_mutdict!(mutdict, mutloc, c, gaps)
		end
	end
end

"""
	find_mut_root(n::TreeTools.TreeNode, i::Int64, val)
	
Find most recent ancestor of `n` that bears the mutation `i`-->`val`. Return its label. 
"""
function find_mut_root(n::TreeTools.TreeNode, i::Int64, val)
	if n.isroot
		return n.label
	end
	for m in  n.data.mutations
		if m.i == i && m.new == val
			return n.label
		end
	end
	# 
	return find_mut_root(n.anc, i, val)
end