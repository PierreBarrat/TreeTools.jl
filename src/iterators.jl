nodes(t) = values(t.lnodes)
leaves(t) = values(t.lleaves)
internals(t) = Iterators.filter(x->!x.isleaf, values(t.lnodes))

nodes(f::Function, t) = filter(f, values(t.lnodes))


#=
Post order traversal iterators
=#
abstract type POTIterator end

Base.IteratorSize(::Type{POTIterator}) = Iterators.HasLength()
Base.IteratorEltype(::Type{POTIterator}) = HasEltype()
function Base.length(iter::POTIterator)
	l = 0
	for n in iter
		l += 1
	end
	return l
end
Base.iterate(itr::POTIterator) = firststate(itr, itr.root)

"""
	struct POT{T<:TreeNodeData} <: POTIterator
		root::TreeNode{T}
	end
"""
struct POT{T<:TreeNodeData} <: POTIterator
	root::TreeNode{T}
end
Base.eltype(::Type{POT{T}}) where T = TreeNode{T}
POT(t::Tree) = POT(t.root)

"""
	struct POTleaves{T<:TreeNodeData} <: POTIterator
		root::TreeNode{T}
	end
"""
struct POTleaves{T<:TreeNodeData} <: POTIterator
	root::TreeNode{T}
end
Base.eltype(::Type{POTleaves{T}}) where T = TreeNode{T}
POTleaves(t::Tree) = POTleaves(t.root)


struct POTState{T<:TreeNodeData}
	n::TreeNode{T}
	i::Int # Position of n in list of siblings -- `n.anc.child[i]==n`
	direction::Symbol
end


"""
- `state.n.isleaf`: go to sibling and down or ancestor and up (stop if root)
- Otherwise: go to deepest child and up.
"""
function Base.iterate(itr::POTIterator, state::POTState)
	if state.direction == :down
		return go_down(itr, state)
	elseif state.direction == :up
		return go_up(itr, state)
	elseif state.direction == :stop
		return nothing
	end
end


function go_down(itr::POTIterator, state::POTState{T}) where T
	if state.n.isleaf # Go back to ancestor or sibling anyway
		if state.n.isroot || state.n == itr.root
			return (state.n, POTState{T}(n, 0, :stop))
		elseif state.i < length(state.n.anc.child) # Go to sibling
			return (state.n, POTState{T}(state.n.anc.child[state.i+1], state.i+1, :down))
		else # Go back to ancestor
			return (state.n, POTState{T}(state.n.anc, get_sibling_number(state.n.anc), :up))
		end
	end
	return firststate(itr, state.n) # Go to deepest child of `n`
end
function go_up(itr::POT{T}, state::POTState{T}) where T
	if state.n.isroot || state.n == itr.root
		return (state.n, POTState{T}(state.n, 0, :stop))
	elseif state.i < length(state.n.anc.child) # Go to sibling
		return (state.n, POTState{T}(state.n.anc.child[state.i+1], state.i+1, :down))
	else # Go back to ancestor
		return (state.n, POTState{T}(state.n.anc, get_sibling_number(state.n.anc), :up))
	end
end
function go_up(itr::POTleaves{T}, state::POTState{T}) where T
	if state.n.isleaf
		if state.n.isroot || state.n == itr.root
			return (state.n, POTState{T}(state.n, 0, :stop))
		elseif state.i < length(state.n.anc.child) # Go to sibling
			return (state.n, POTState{T}(state.n.anc.child[state.i+1], state.i+1, :down))
		else # Go back to ancestor
			return (state.n, POTState{T}(state.n.anc, get_sibling_number(state.n.anc), :up))
		end
	else
		if state.n.isroot || state.n == itr.root
			return nothing
		elseif state.i < length(state.n.anc.child) # Go to sibling
			iterate(itr, POTState(state.n.anc.child[state.i+1], state.i+1, :down))
		else # Go back to ancestor
			iterate(itr, POTState(state.n.anc, get_sibling_number(state.n.anc), :up))
		end
	end
end


"""
Go to deepest child of `a`.
"""
function firststate(itr::POTIterator, a::TreeNode{T}) where T
	if a.isleaf
		return iterate(itr, POTState{T}(a, 1, :up))
	end
	firststate(itr, a.child[1])
end

function get_sibling_number(n::TreeNode)
	if n.isroot
		return 0
	end
	for (i,c) in enumerate(n.anc.child)
		if n == c
			return i
		end
	end
	@error "Could not find $(n.label) in children of $(n.anc.label)."
end
