"""
	write_newick(file::String, tree::Tree)
"""
function write_newick(file::String, tree::Tree)
	write_newick(file, tree.root)
end


"""
	write_newick(file::String, root::TreeNode)
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
	write_newick(root::TreeNode)

Return a newick string.
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


