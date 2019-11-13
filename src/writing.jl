export write_newick, write_fasta, write_newick!, write_branchlength

using JSON

"""
"""
function write_newick(file::String, tree::Tree)
	write_newick(file, tree.root)
end


"""
"""
function write_newick(file::String, root::TreeNode)
	out = write_newick!("", root)
	out *= ';'
	f = open(file, "w")
	write(f, out)
	close(f)
end


"""
"""
function write_newick!(s::String, root::TreeNode)
	if !isempty(root.child)
		s *= '('
		temp = sort(root.child, by=x->length(node_leavesclade(x)))
		for c in temp
			s = write_newick!(s, c)
			s *= ','
		end
		s = s[1:end-1] # Removing trailing ','
		s *= ')'
	end
	s *= root.label
	if !ismissing(root.data.tau)
		s *= ':'
		s *= string(root.data.tau)
	end
	return s
end

"""
"""
function write_newick(root::TreeNode)
	return write_newick!("", root)*";"
end

"""
	 write_fasta(file::String, tree::Tree ; internal = false)
"""
function write_fasta(file::String, tree::Tree ; internal = false)
	write_fasta(file, tree.root, internal = internal)
end

"""
	write_fasta(file::String, root::TreeNode ; internal = false)
"""
function write_fasta(file::String, root::TreeNode ; internal = false)
	out = write_fasta!("", root, internal)
	f = open(file, "w")
	write(f, out)
	close(f)
end

"""
"""
function write_fasta!(s::String, root::TreeNode{EvoData}, internal::Bool)
	if internal || root.isleaf
		# s = s * ">$(root.label)\n$(num2seq(root.data.sequence))\n"
		s = s * ">$(root.label)\n$(prod(root.data.sequence))\n"
	end
	for c in root.child
		s = write_fasta!(s, c, internal)
	end
	return s
end

"""
"""
function num2seq(numseq::Array{Int64,1})
	mapping = "ACGT-NWSMKRYBDHV"
	seq = ""
	for a in numseq
		seq *= mapping[a]
	end
	return seq
end	

"""
	write_branchlength(tree::Tree, msaname::String, treename::String)

Create a JSON file storing branch lengths of all branches in `tree`. This is intended for reading with auspice.  
"""
function write_branchlength(jsonfile::String, tree::Tree, jsontemplate::String)

end


"""
	write_branchlength(tree::Tree, msaname::String, treename::String)

Create a JSON file storing branch lengths of all branches in `tree`. This is intended for reading with auspice.  
"""
function write_branchlength(jsonfile::String, tree::Tree, msaname::String, treename::String ; order = keys(tree.lnodes))
	out = Dict()
	node = Dict();
	for k in order
		n = tree.lnodes[k]
		node[n.label] = Dict("branch_length"=>n.data.tau)
	end
	out["nodes"] = node
	out["input_tree"] = treename
	out["alignment"] = msaname
	open(jsonfile, "w") do f 
		JSON.print(f, out)
	end
end

