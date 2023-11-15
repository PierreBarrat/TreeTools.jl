const write_styles = (:newick)

"""
	write(io::IO, t::Tree; style=:newick, internal_labels=true, write_root=true)
	write(filename::AbstractString, t::Tree, mode="w"; kwargs...)

Write `t` to file or IO with format determined by `style`. If `internal_labels == false`,
do not write labels of internal nodes in the string.
"""
function write(io::IO, t::Tree; style=:newick, internal_labels=true, write_root=true)
	return if style in (:newick, :Newick, "newick", "Newick")
		write_newick(io, t; internal_labels, write_root)
	else
		@error "Unknown write style $style. Allowed: $(write_styles)."
		error()
	end
end
function write(
	filename::AbstractString, t::Tree, mode::AbstractString = "w"; kwargs...
)
	return open(filename, mode) do io
		write(io, t; kwargs...)
	end
end
"""
	write(filename, trees...; style=:newick, internal_labels=true)

Write each tree in `trees` in `filename`, separated by a newline '\n' character.
"""
function write(
	filename::AbstractString, trees::Vararg{Tree}; kwargs...
)
	return open(filename, "w") do io
		for (i,t) in enumerate(trees)
			write(io, t; kwargs...)
			i < length(trees) && write(io, '\n')
		end
	end
end


"""
	write_newick(io::IO, tree::Tree; kwargs...)
	write_newick(filename::AbstractString, tree::Tree, mode="w"; kwargs...)
	write_newick(tree::Tree; kwargs...)

Write Newick string corresponding to `tree` to `io` or `filename`. If output is not
provided, return the Newick string. If `internal_labels == false`, do not
write labels of internal nodes in the string.
"""
function write_newick(io::IO, tree::Tree; kwargs...)
	return write(io, newick(tree; kwargs...) * "\n")
end
function write_newick(
	filename::AbstractString, tree::Tree, mode::AbstractString = "w";
)
	return open(filename, mode) do io
		write_newick(io, tree; kwargs...)
	end
end

"""
	newick(tree::Tree; internal_labels=true, write_root=true)

Return the Newick string correpsonding to `tree`.
If `internal_labels == false`, do not write labels of internal nodes in the string.
If `!write_root`, do not write label and time for the root node (unrooted tree).
"""
write_newick(tree::Tree; kwargs...) = newick(tree; kwargs...)
write_newick(node::TreeNode) = newick(node)

newick(tree::Tree; kwargs...) = newick(tree.root; kwargs...)
function newick(root::TreeNode; internal_labels = true, write_root=true)
    return _newick!("", root, internal_labels, write_root)*";"
end

function _newick!(s::String, root::TreeNode, internal_labels=true, write_root=true)
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
	if isleaf(root) || (internal_labels && (!isroot(root) || write_root))
		s *= root.label
	end
	if !ismissing(root.tau) && !isroot(root)
		s *= ':'
		s *= string(root.tau)
	end
	if isroot(root) && write_root
		s *= ":0"
	end

	return s
end



