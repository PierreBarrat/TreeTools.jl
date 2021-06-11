"""
	write_newick([file::String,] tree::Tree)

Write `tree` as a newick string in `file`.
  If `file` is not provided, return the newick string.
"""
write_newick(file::String, tree::Tree) = write_newick(file, tree.root)
write_newick(tree::Tree) = write_newick(tree.root)



"""
	write_newick([file::String,] root::TreeNode)
"""
function write_newick(file::String, root::TreeNode)
	out = write_newick(root)
	open(file, "w") do f
		write(f, out)
	end

	return nothing
end
write_newick(root::TreeNode) = write_newick!("", root)*";"



"""
"""
function write_newick!(s::String, root::TreeNode)
	if !isempty(root.child)
		s *= '('
		temp = sort(root.child, by=x->length(POTleaves(x)))
		for c in temp
			s = write_newick!(s, c)
			s *= ','
		end
		s = s[1:end-1] # Removing trailing ','
		s *= ')'
	end
	s *= root.label
	if !ismissing(root.tau)
		s *= ':'
		s *= string(root.tau)
	end
	return s
end



