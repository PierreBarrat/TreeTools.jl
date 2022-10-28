const write_styles = (:newick)

"""
	write(io::IO, t::Tree; style=:newick, internal_labels=true)
	write(filename::AbstractString, t::Tree, mode="w"; style=:newick, internal_labels=true)

Write `t` to file or IO with format determined by `style`. If `internal_labels == false`,
do not write labels of internal nodes in the string.
"""
function write(io::IO, t::Tree; style=:newick, internal_labels=true)
	return if style in (:newick, :Newick, "newick", "Newick")
		write_newick(io, t; internal_labels)
	else
		@error "Unknown write style $style. Allowed: $(write_styles)."
		error()
	end
end
function write(
	filename::AbstractString, t::Tree, mode="w";
	style=:newick, internal_labels=true
)
	return open(filename, mode) do io
		write(io, t; style, internal_labels)
	end
end

"""
	write_newick(io::IO, tree::Tree; internal_labels=true)
	write_newick(filename::AbstractString, tree::Tree, mode="w"; internal_labels=true)
	write_newick(tree::Tree; internal_labels=true)

Write Newick string corresponding to `tree` to `io` or `filename`. If output is not
provided, return the Newick string. If `internal_labels == false`, do not
write labels of internal nodes in the string.
"""
function write_newick(io::IO, tree::Tree; internal_labels=true)
	return write(io, newick(tree; internal_labels))
end
function write_newick(filename::AbstractString, tree::Tree, mode="w"; internal_labels=true)
	return open(filename, mode) do io
		write_newick(io, tree; internal_labels)
	end
end

"""
	newick(tree::Tree; internal_labels=true)

Return the Newick string correpsonding to `tree`. If `internal_labels == false`, do not
write labels of internal nodes in the string.
"""
newick(tree::Tree; internal_labels=true) = newick(tree.root; internal_labels)
write_newick(tree::Tree; internal_labels=true) = newick(tree; internal_labels)


newick(root::TreeNode; internal_labels = true) = _newick!("", root, internal_labels)*";"
function _newick!(s::String, root::TreeNode, internal_labels)
	if !isempty(root.child)
		s *= '('
		# temp = sort(root.child, by=x->length(POTleaves(x)))
		for c in root.child
			s = _newick!(s, c, internal_labels)
			s *= ','
		end
		s = s[1:end-1] # Removing trailing ','
		s *= ')'
	end
	if isleaf(root) || internal_labels
		s *= root.label
	end
	if !ismissing(root.tau)
		s *= ':'
		s *= string(root.tau)
	end
	if root.isroot && ismissing(root.tau)
		s *= ":0"
	end

	return s
end



