"""
	Split

`dat::BitArray{1}`
"""
struct Split
	dat::BitArray{1}
end
Split(L::Int64) = Split(falses(L))
Base.length(s::Split) = length(s.dat)
Base.iterate(s::Split) = iterate(s.dat)
Base.iterate(s::Split, i::Int64) = iterate(s.dat, i)
Base.getindex(s::Split, i::Int64) = s.dat[i]
Base.:(==)(s::Split, t::Split) = (s.dat == t.dat)
"""
	isequal(s::Split, t::Split, mask::Array{Bool,1})

Test for equality between splits restricted to `mask`.
"""
function Base.isequal(s::Split, t::Split, mask::Array{Bool,1})
	for (i,m) in enumerate(mask)
		if m && s.dat[i] != t.dat[i]
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
	for (x,m) in zip(s.dat, mask)
		if m && !x
			return false
		end
	end
	return true
end
"""
	is_leaf_split(s::Split, mask::Array{Bool,1})

Check if `s` is a leaf split when restricted to `mask`.
"""
function is_leaf_split(s::Split, mask::Array{Bool,1})
	c = 0
	for (x,m) in zip(s.dat, mask)
		if m && x
			c += 1
		end
		if c > 1
			return false
		end
	end
	return true
end


"""
	isempty(s::Split, mask::Array{Bool,1})
"""
function Base.isempty(s::Split, mask::Array{Bool,1})
	for (x,m) in zip(s.dat, mask)
		if m && x
			return false
		end
	end
	return true
end

"""
	joinsplits!(s::Split, t::Split)

Join `t` to `s`.
"""
function joinsplits!(s::Split, t::Split)
	for (i,v) in enumerate(t)
		if v && !s.dat[i]
			s.dat[i] = v
		end
	end
end

"""
	joinsplits(s::Split, t::Split)

Join `s` and `t`. Return resulting `Split`.
"""
function joinsplits(s::Split, t::Split)
	u = Split(similar(s.dat))
	for (i,(x,y)) in enumerate(zip(s,t))
		u.dat[i] = x | y
	end
	return u
end

"""
	is_sub_split(s::Split, t::Split)

Check if `s` is a subsplit of `t`.
"""
function is_sub_split(s::Split, t::Split)
	for i in eachindex(s.dat)
		if s.dat[i] & !(t.dat[i])
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
- `splitmap::Dict{T,Split}`: indicate the split corresponding to the branch above a node. Only used is built from a tree with labels on internal nodes.
```
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
	splitmap::Dict{T,Split}
) where T
	SplitList{T}(leaves, splits, mask, splitmap)
end
"""
	SplitList(leaves::Array{T,1}) where T
"""
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
Base.iterate(S::SplitList, i::Int64) = iterate(S.splits, i)
Base.getindex(S::SplitList, i::Int64) = getindex(S.splits, i)
Base.lastindex(S::SplitList) = lastindex(S.splits)
Base.isempty(S::SplitList) = isempty(S.splits)
function Base.:(==)(S::SplitList, T::SplitList)
	S.leaves == T.leaves && sort(S.splits, by=x->x.dat) == sort(T.splits, by=x->x.dat) && S.mask == T.mask
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
	SplitList(t::Tree, mask=ones(Bool, length(t.lleaves)))

Compute the list of splits in tree `t`.
"""
function SplitList(t::Tree, mask=ones(Bool, length(t.lleaves)))
	leaves = collect(keys(t.lleaves))
	return SplitList(t.root, leaves, mask)
end
"""
	SplitList(r::TreeNode, leaves)

Compute the list of splits below `r`, including `r` itself.
The `mask` attribute of the result is determined by the set of leaves that are descendents of `r`.
"""
function SplitList(r::TreeNode, leaves)
	!issorted(leaves) ? leaves_srt = sort(leaves) : leaves_srt = leaves
	leafmap = Dict(leaf=>i for (i,leaf) in enumerate(leaves_srt))
	# Compute mask : leaves that are descendents or `r`
	mask = zeros(Bool, length(leaves_srt))
	for x in POTleaves(r)
		mask[leafmap[x.label]] = true
	end
	#
	S = SplitList(leaves_srt, Array{Split,1}(undef,0), mask, Dict{eltype(leaves), Split}())
	_splitlist!(S, r, leafmap)
	return S
end
"""
	SplitList(r::TreeNode, leaves, mask)

Compute the list of splits below `r`, including `r` itself.
"""
function SplitList(r::TreeNode, leaves, mask)
	!issorted(leaves) ? leaves_srt = sort(leaves) : leaves_srt = leaves
	leafmap = Dict(leaf=>i for (i,leaf) in enumerate(leaves_srt))
	S = SplitList(leaves_srt, Array{Split,1}(undef,0), mask, Dict{eltype(leaves_srt), Split}())
	_splitlist!(S, r, leafmap)
	return S
end
"""
	_splitlist!(S::SplitList, r::TreeNode, leafmap::Dict)

Compute the split defined by `r` and store it in S, by first calling `_splitlist!` on all children of `r` and joining resulting splits. Leaf-splits and root-split are not stored.
"""
function _splitlist!(S::SplitList, r::TreeNode, leafmap::Dict)
	s = Split(length(leafmap))
	if r.isleaf
		s.dat[leafmap[r.label]] = true
	else
		for c in r.child
			sc = _splitlist!(S, c, leafmap)
			joinsplits!(s,sc)
		end
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
		println(io, S.leaves[s.dat .* S.mask])
	end
end
Base.show(S::SplitList) = show(stdout, S)


"""
	isequal(s::SplitList, i::Int64, j::Int64; mask=true)
"""
function Base.isequal(s::SplitList, i::Int64, j::Int64; mask=true)
	if mask
		return isequal(s.splits[i], s.splits[j], s.mask)
	else
		return s.splits[i] == s.splits[j]
	end
end

"""
	isequal(S::SplitList, A::Array{<:Array{<:AbstractString,1}})
"""
function Base.isequal(S::SplitList, A::Array{<:Array{<:AbstractString,1}})
	sort([S.leaves[s.dat .* S.mask] for s in S]) == sort(A)
end
==(S::SplitList, A::Array{<:Array{<:AbstractString,1}}) = isequal(S,A)

"""
	arecompatible(s::Split,t::Split)
	arecompatible(s::Split,t::Split, mask::Array{Bool})

Are splits `s` and `t` compatible **in the cluster sense**.
Three possible states: `(0,1), (1,0), (1,1)`. If all are seen, the splits are not compatible.
"""
function arecompatible(s::Split,t::Split)
	f1 = false; f2 = false; f3 = false;
	@inbounds for i in eachindex(s.dat)
		if s.dat[i] || t.dat[i]
			if !f1 && !s.dat[i] && t.dat[i]
				f1 = true
			elseif !f2 && s.dat[i] && !t.dat[i]
				f2 = true
			elseif !f3 && s.dat[i] && t.dat[i]
				f3 = true
			end
		end
		if f1 && f2 && f3
			return false
		end
	end
	return true
end
function arecompatible(s::Split,t::Split, mask::Array{Bool})
	flag = falses(3)
	for m in Iterators.filter(x->x, mask)
		for (x,y) in zip(s,t)
			if !flag[1] && !x && y
				flag[1] = true
				if alltrue(flag) return false end
			elseif !flag[2] && x && !y
				flag[2] = true
				if alltrue(flag) return false end
			elseif !flag[3] && x && y
				flag[3] = true
				if alltrue(flag) return false end
			end
		end
	end
	return true
end
function alltrue(X)
	for x in X
		if !x
			return false
		end
	end
	return true
end
"""
	arecompatible(s::SplitList, i::Int64, j::Int64; mask=true)

Are `s.splits[i]` and `s.splits[j]` compatible?
"""
function arecompatible(s::SplitList, i::Int64, j::Int64; mask=true)
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
		elseif !usemask && !arecompatible(s,t)
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
function Base.in(s::AbstractArray, S::SplitList, mask=S.mask; usemask=true) where T
	ss = sort(s)
	for t in S
		if (usemask && ss == S.leaves[t.dat .* S.mask]) || (!usemask && ss == S.leaves[t.dat])
			return true
		end
	end
	return false
end

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
	# sd = Array{Split,1}(undef,0)
	U = SplitList(S.leaves)
	for s in S
		if !in(s, T, m; usemask) && !is_root_split(s, m) && !is_leaf_split(s, m) && !isempty(s,m)
			# push!(sd, s)
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
	hashes = Dict{BitArray{1}, Bool}()
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
	out = SplitList(sort(collect(keys(t.lleaves))), Array{Split,1}(undef,0), ones(Bool, length(t.lleaves)), Dict{T, Split}())
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
- restrain them to `S.mask`
- find the corresponding internal node that should be introduced in `t`
- compute the split defined by this internal node.
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
function _map_split_to_tree(S::SplitList, i::Int64, t::Tree, treesplits::SplitList)
	roots = TreeTools.blca([t.lleaves[x] for x in S.leaves[S[i].dat .* S.mask]]...)
	ms = Split(length(S.leaves))
	for r in roots
		if r.isleaf # `treesplits.splitmap` (probably) does not contain leaf-splits
			ms.dat[findfirst(==(r.label), S.leaves)] = true
		else
			TreeTools.joinsplits!(ms, treesplits.splitmap[r.label])
		end
	end
	return ms
end
