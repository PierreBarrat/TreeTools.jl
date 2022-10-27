const write_styles = (:newick)

"""
	write(io::IO, t::Tree; style=:newick)
	write(filename::AbstractString, t::Tree, mode="w"; style=:newick)

Write `t` to file or IO with format determined by `style`.
"""
function write(io::IO, t::Tree; style=:newick)
	return if style in (:newick, :Newick, "newick", "Newick")
		write_newick(io, t)
	else
		@error "Unknown write style $style. Allowed: $(write_styles)."
		error()
	end
end
function write(filename::AbstractString, t::Tree, mode="w"; style=:newick)
	return open(filename, mode) do io
		write(io, t; style)
	end
end

"""
	write_newick(io::IO, tree::Tree)
	write_newick(filename::AbstractString, tree::Tree, mode="w")
	write_newick(tree::Tree)

Write Newick string corresponding to `tree` to `io` or `filename`. If output is not
provided, return the Newick string.
"""
write_newick(io::IO, tree::Tree) = write(io, newick(tree))
function write_newick(filename::AbstractString, tree::Tree, mode="w")
	return open(filename, mode) do io
		write_newick(io, tree)
	end
end

"""
	newick(tree::Tree)

Return the Newick string correpsonding to `tree`.
"""
newick(tree::Tree) = newick(tree.root)
write_newick(tree::Tree) = newick(tree)


newick(root::TreeNode) = _newick!("", root)*";"
function _newick!(s::String, root::TreeNode)
	if !isempty(root.child)
		s *= '('
		# temp = sort(root.child, by=x->length(POTleaves(x)))
		for c in root.child
			s = _newick!(s, c)
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
	if root.isroot && ismissing(root.tau)
		s *= ":0"
	end

	return s
end



