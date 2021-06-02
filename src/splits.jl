"""
	Split

`dat::Array{Int,1}`: indices of leaves in the split
"""
struct Split
	dat::Array{Int,1}
	function Split(dat)
		if !issorted(dat)
			@error("`split.dat` must be sorted")
		end

		return new(dat)
	end
end
Split(L::Integer) = Split(fill(typemax(Int), L))
Base.length(s::Split) = length(s.dat)
Base.iterate(s::Split) = iterate(s.dat)
Base.iterate(s::Split, i::Integer) = iterate(s.dat, i)
Base.getindex(s::Split, i::Integer) = s.dat[i]
Base.:(==)(s::Split, t::Split) = (s.dat == t.dat)
"""
	isequal(s::Split, t::Split, mask::Array{Bool,1})

Test for equality between splits restricted to `mask`.
"""
function Base.isequal(s::Split, t::Split, mask::Array{Bool,1})
	_in = max(length(s), length(t)) > 20 ? insorted : in
	for i in s
		if mask[i] && !_in(i, t.dat)
			return false
		end
	end
	for i in t
		if mask[i] && !_in(i, s.dat)
			return false
		end
	end

	return true
end

"""
	is_root_split(s::Split, mask::Array{Bool,1})

Check if `s` is the root split when restricted to `mask`.
"""
function is_root_split(s::Split, mask::Array{Bool,1})
	Lmask = sum(mask)
	Ls = 0
	for i in s
		if mask[i]
			Ls += 1
		end
	end

	return Ls == Lmask
end

"""
	is_leaf_split(s)
	is_leaf_split(s::Split, mask::Array{Bool,1})

Check if `s` is a leaf split.
"""
function is_leaf_split(s::Split, mask::Array{Bool,1})
	Ls = 0
	for i in s
		if mask[i]
			Ls += 1
		end
		if Ls > 1
			return false
		end
	end
	return true
end
is_leaf_split(s) = (length(s) == 1)

"""
	isempty(s::Split, mask::Array{Bool,1})
	isempty(s::Split)
"""
function Base.isempty(s::Split, mask::Array{Bool,1})
	Ls = 0
	for i in s
		if mask[i]
			return false
		end
	end
	return true
end
Base.isempty(s::Split) = isempty(s.dat)

"""
	joinsplits!(s::Split, t...)

Join `t` to `s`.
"""
function joinsplits!(s::Split, t::Vararg{Split})
	for x in t
		append!(s.dat, x.dat)
	end
	sort!(s.dat)
	unique!(s.dat)
	return nothing

end
# Same as above, but assume s is initialized with 0s, and start filling at index `i`.
function _joinsplits!(s::Split, t::Split, i::Integer)
	for j in 1:length(t)
		s.dat[j + i - 1] = t.dat[j]
	end
	return nothing
end
"""
	joinsplits(s::Split, t::Split)

Join `s` and `t`. Return resulting `Split`.
"""
function joinsplits(s::Split, t...)
	sc = Split(copy(s.dat))
	joinsplits!(sc, t...)
	return sc
end

"""
	is_sub_split(s::Split, t::Split)
	is_sub_split(s::Split, t::Split, mask)

Check if `s` is a subsplit of `t`.
"""
function is_sub_split(s::Split, t::Split)
	_in = maximum(length(t)) > 20 ? insorted : in
	for i in s
		if !_in(i,t.dat)
			return false
		end
	end

	return true
end
function is_sub_split(s::Split, t::Split, mask)
	_in = maximum(length(t)) > 20 ? insorted : in
	for i in s
		if mask[i] && !_in(i,t.dat)
			return false
		end
	end

	return true
end

"""
	are_disjoint(s::Split, t::Split)
	are_disjoint(s::Split, t::Split, mask)

Check if `s` and `t` share leaves.
"""
function are_disjoint(s::Split, t::Split)
	_in = maximum(length(t)) > 20 ? insorted : in
	for i in s
		if _in(i,t.dat)
			return false
		end
	end

	for i in t
		if _in(i,s.dat)
			return false
		end
	end

	return true
end

function are_disjoint(s::Split, t::Split, mask)
	_in = maximum(length(t)) > 20 ? insorted : in
	for i in s
		if mask[i] && _in(i,t.dat)
			return false
		end
	end

	for i in t
		if mask[i] && _in(i,s.dat)
			return false
		end
	end

	return true
end

"""
	SplitList{T}

- `leaves::Array{T,1}`
- `splits::Array{Split,1}`
- `mask::Array{Bool,1}`: subset of leaves for which splits apply.
- `splitmap::Dict{T,Split}`: indicate the split corresponding to the branch above a node.
  Only used is built from a tree with labels on internal nodes.

# Constructors
	SplitList(leaves::Array{T,1}) where T

Empty `SplitList`.

	SplitList(t::Tree[, mask=ones(Bool, length(t.lleaves))])

List of splits in `t`.

	SplitList(r::TreeNode, leaves[, mask])

Compute the list of splits below `r`, including `r` itself.
  Assume that `r` is part of a tree with `leaves`.
`mask` defaults to the set of leaves that are descendents
  of `r`.
"""
struct SplitList{T}
	leaves::Array{T,1}
	splits::Array{Split,1}
	mask::Array{Bool,1}
	splitmap::Dict{T,Split} ## Maps each leaf to the split it is in.
	function SplitList{T}(leaves::Array{T,1}, splits, mask, splitmap) where T
		if issorted(leaves)
			return new(leaves, splits, mask, splitmap)
		else
			@error("Leaves must be sorted")
		end
	end
end
function SplitList(
	leaves::Array{T,1},
	splits::Array{Split,1},
	mask::Array{Bool,1},
	splitmap::Dict
) where T
	SplitList{T}(leaves, splits, mask, convert(Dict{T, Split}, splitmap))
end

function SplitList(leaves::Array{T,1}) where T
	SplitList{T}(
		leaves,
		Array{Split,1}(undef,0),
		ones(Bool, length(leaves)),
		Dict{T, Split}()
	)
end

Base.length(S::SplitList) = length(S.splits)
Base.iterate(S::SplitList) = iterate(S.splits)
Base.iterate(S::SplitList, i::Integer) = iterate(S.splits, i)
Base.getindex(S::SplitList, i::Integer) = getindex(S.splits, i)
Base.lastindex(S::SplitList) = lastindex(S.splits)
Base.eachindex(S::SplitList) = eachindex(S.splits)
Base.isempty(S::SplitList) = isempty(S.splits)
function Base.:(==)(S::SplitList, T::SplitList)
	S.leaves == T.leaves &&
	sort(S.splits, by=x->x.dat) == sort(T.splits, by=x->x.dat) &&
	S.mask == T.mask
end

function Base.cat(aS::Vararg{SplitList{T}}) where T
	if !mapreduce(S->S.leaves==aS[1].leaves && S.mask==aS[1].mask, *, aS, init=true)
		error("Split lists do not share leaves or masks")
	end
	catS = SplitList(aS[1].leaves, Array{Split,1}(undef,0), aS[1].mask, Dict{T, Split}())
	for S in aS
		append!(catS.splits, S.splits)
	end
	unique!(catS.splits)
	return catS
end

"""
	leaves(S::SplitList, i)

Return array of leaves in `S.splits[i]`, taking `S.mask` into account.
"""
function leaves(S::SplitList, i)
	idx = S[i].dat[findall(i -> S.mask[i], S[i].dat)]
	return S.leaves[idx]
end

function SplitList(t::Tree, mask=ones(Bool, length(t.lleaves)))
	leaves = sort(collect(keys(t.lleaves)))
	leafmap = Dict(leaf=>i for (i,leaf) in enumerate(leaves))
	return SplitList(t.root, leaves, mask, leafmap)
end
function SplitList(r::TreeNode, leaves)
	!issorted(leaves) ? leaves_srt = sort(leaves) : leaves_srt = leaves
	leafmap = Dict(leaf=>i for (i,leaf) in enumerate(leaves_srt))
	# Compute mask : leaves that are descendents or `r`
	mask = zeros(Bool, length(leaves_srt))
	for x in POTleaves(r)
		mask[leafmap[x.label]] = true
	end
	#
	S = SplitList(
		leaves_srt,
		Array{Split,1}(undef,0),
		mask,
		Dict{eltype(leaves), Split}(),
	)
	_splitlist!(S, r, leafmap)
	return S
end
function SplitList(
	r::TreeNode,
	leaves,
	mask,
	leafmap = Dict(leaf=>i for (i,leaf) in enumerate(sort(leaves)))
)
	!issorted(leaves) ? leaves_srt = sort(leaves) : leaves_srt = leaves
	S = SplitList(
		leaves_srt,
		Array{Split,1}(undef,0),
		mask,
		Dict{eltype(leaves_srt), Split}(),
	)
	_splitlist!(S, r, leafmap)
	return S
end
"""
	_splitlist!(S::SplitList, r::TreeNode, leafmap::Dict)

Compute the split defined by `r` and store it in S, by first calling `_splitlist!`
  on all children of `r` and joining resulting splits.
  Leaf-splits and root-split are not stored.
"""
function _splitlist!(S::SplitList, r::TreeNode, leafmap::Dict)
	if r.isleaf
		s = Split([leafmap[r.label]])
	else
		#s = Split(0)
		L = 0
		for c in r.child
			sc = _splitlist!(S, c, leafmap)
			L += length(sc)
		end
		s = Split(L)
		i = 1
		for c in r.child
			if c.isleaf
				s.dat[i] = leafmap[c.label]
				i += 1
			else
				sc = S.splitmap[c.label]
				_joinsplits!(s,sc,i)
				i += length(sc)
			end
		end
		sort!(s.dat)
		unique!(s.dat)
		push!(S.splits, s)
		S.splitmap[r.label] = s
	end
	return s
end

function Base.show(io::IO, S::SplitList)
	for (i,s) in enumerate(S)
		if i > 20
			println(io, "...")
			break
		end
		println(io, leaves(S,i))
	end
end
Base.show(S::SplitList) = show(stdout, S)


"""
	isequal(S::SplitList, i::Integer, j::Integer; mask=true)
"""
function Base.isequal(S::SplitList, i::Integer, j::Integer; mask=true)
	if mask
		return isequal(S.splits[i], S.splits[j], S.mask)
	else
		return S.splits[i] == S.splits[j]
	end
end

"""
	isequal(S::SplitList, A::AbstractArray)

Is `[leaves(S,i) for i in ...]` equal to `A`?
"""
function Base.isequal(S::SplitList, A::AbstractArray)
	sort([leaves(S,i) for i in eachindex(S.splits)]) == sort(A)
end
==(S::SplitList, A::AbstractArray) = isequal(S,A)

"""
	arecompatible(s::Split,t::Split)
	arecompatible(s::Split,t::Split, mask::Array{Bool})

Are splits `s` and `t` compatible **in the cluster sense**.
Three possible states: `(0,1), (1,0), (1,1)`. If all are seen, the splits are not compatible.

	arecompatible(s::SplitList, i::Integer, j::Integer; mask=true)

Are `s.splits[i]` and `s.splits[j]` compatible?
"""
function arecompatible(s::Split, t::Split)
	if is_sub_split(s, t) || is_sub_split(t, s)
		return true
	elseif are_disjoint(s,t)
		return true
	else
		return false
	end
end
function arecompatible(s::Split, t::Split, mask::Array{Bool})
	if is_sub_split(s, t, mask) || is_sub_split(t, s, mask)
		return true
	elseif are_disjoint(s, t, mask)
		return true
	else
		return false
	end
end
function arecompatible(s::SplitList, i::Integer, j::Integer; mask=true)
	if mask
		return arecompatible(s.splits[i], s.splits[j], s.mask)
	else
		return arecompatible(s.splits[i], s.splits[j])
	end
end

"""
	iscompatible(s::Split, S::SplitList, mask=S.mask; usemask=true)

Is `s` compatible with all splits in `S`.
"""
function iscompatible(s::Split, S::SplitList, mask=S.mask; usemask=true)
	for t in S
		if usemask && !arecompatible(s, t, mask)
			return false
		elseif !usemask && !arecompatible(s, t)
			return false
		end
	end
	return true
end


"""
	in(s, S::SplitList, mask=S.mask; usemask=true)

Is `s` in `S`?
"""
function Base.in(s::Split, S::SplitList, mask=S.mask; usemask=true)
	for t in S
		if (!usemask && s == t) || (usemask && isequal(s, t, mask))
			return true
		end
	end
	return false
end
#function Base.in(s::AbstractArray, S::SplitList, mask=S.mask; usemask=true) where T
#	ss = sort(s)
#	for i in eachindex(S.splits)
#		if (usemask && ss == leaves(S,i)) || (!usemask && ss == S.leaves[t.dat])
#			return true
#		end
#	end
#	return false
#end

"""
	setdiff(S::SplitList, T::SplitList, mask=:left)

Return array of splits in S that are not in T.

`mask` options: `:left`, `:right`, `:none`.
"""
function Base.setdiff(S::SplitList, T::SplitList, mask=:left)
	if mask == :none
		m = ones(Bool, length(S.leaves))
		usemask = false
	elseif mask == :left
		m = S.mask
		usemask = true
	elseif mask == :right
		m = T.mask
		usemask = true
	else
		@error "Unrecognized `mask` kw-arg."
	end
	#
	U = SplitList(S.leaves)
	for s in S
		if (!in(s, T, m; usemask) &&
			!is_root_split(s, m) &&
			!is_leaf_split(s, m) &&
			!isempty(s,m)
		)
			push!(U.splits, s)
		end
	end
	return U
end

"""
	intersect(S::SplitList, T::SplitList, mask=:none)
"""
function Base.intersect(S::SplitList, T::SplitList, mask=:none)
	if mask == :none
		m = ones(Bool, length(S.leaves))
	elseif mask == :left
		m = S.mask
	elseif mask == :right
		m = T.mask
	else
		@error "Unrecognized `mask` kw-arg."
	end
	#
	U = SplitList(S.leaves)
	for s in S
		if in(s, T, m)
			push!(U.splits, s)
		end
	end
	return U
end

"""
	unique!(S::SplitList; usemask=true)
"""
function Base.unique!(S::SplitList; usemask=true)
	todel = Int64[]
	hashes = Dict{Array{Int,1}, Bool}()
	for (i,s) in enumerate(S)
		if haskey(hashes, s.dat)
			push!(todel, i)
		end
		hashes[s.dat] = true
	end
	deleteat!(S.splits, todel)
end

"""
	unique(S::SplitList; usemask=true)
"""
function Base.unique(S::SplitList; usemask=true)
	Sc = deepcopy(S)
	unique!(Sc, usemask=usemask)
	return Sc
end

"""
	clean!(S::SplitList, mask=S.mask;
		clean_leaves=true, clean_root=false
	)

Remove leaf and empty splits according to S.mask. Option to remove root.
"""
function clean!(S::SplitList, mask=S.mask;
	clean_leaves=true, clean_root=false
)
	idx = Int64[]
	for (i,s) in enumerate(S)
		if clean_leaves && is_leaf_split(s, mask)
			push!(idx, i)
		elseif clean_root &&  is_root_split(s, mask)
			push!(idx, i)
		elseif isempty(s, mask)
			push!(idx, i)
		end
	end
	deleteat!(S.splits, idx)
end




"""
	map_splits_to_tree(S::Array{<:SplitList,1}, t::Tree)

Call `map_splits_to_tree(S::SplitList, t::Tree)` for all elements of `S`.
Return a single `SplitList`.
"""
function map_splits_to_tree(S::Array{SplitList{T},1}, t::Tree) where T
	out = SplitList(
		sort(collect(keys(t.lleaves))),
		Array{Split,1}(undef,0),
		ones(Bool, length(t.lleaves)), Dict{T, Split}(),
	)
	treesplits = SplitList(t)
	for tmp in S
		mS = TreeTools.map_splits_to_tree(tmp, t, treesplits)
		for s in mS
			push!(out.splits, s)
		end
	end
	return out
end
"""
	map_splits_to_tree(S::SplitList, t::Tree)

Map splits `S` from another tree to `t`:
- restrain each split of `S` to `S.mask`
- find the corresponding internal node in `t`
- compute the split in `t` defined by this internal node.

Useful for resolving a tree with splits of another.
"""
function map_splits_to_tree(S::SplitList, t::Tree)
	treesplits = SplitList(t)
	return map_splits_to_tree(S, t, treesplits)
end
function map_splits_to_tree(S::SplitList, tree::Tree, treesplits::SplitList)
	mS = SplitList(
		S.leaves,
		Array{Split,1}(undef,0),
		ones(Bool, length(treesplits.leaves)),
		Dict{eltype(S.leaves), Split}()
	)
	for i in 1:length(S)
		ms = _map_split_to_tree(S, i, tree, treesplits)
		push!(mS.splits, ms)
	end
	return mS
end


#=
Map split `S[i]` to `t`.
=#
function _map_split_to_tree(S::SplitList, i::Integer, t::Tree, treesplits::SplitList)
	# Not lca in case lca(t, leaves(S,i)) contains extra leaves not in S[i]
	roots = TreeTools.blca([t.lleaves[x] for x in leaves(S,i)]...)
	ms = Split(0)
	for r in roots
		if r.isleaf # `treesplits.splitmap` (probably) does not contain leaf-splits
			joinsplits!(ms, Split([findfirst(==(r.label), S.leaves)]))
		else
			joinsplits!(ms, treesplits.splitmap[r.label])
		end
	end
	return ms
end
