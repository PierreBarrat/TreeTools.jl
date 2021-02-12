export Split, SplitList
export arecompatible, iscompatible
export getindex, length, iterate, lastindex

"""
	Split

`dat::BitArray{1}`
"""
struct Split
	dat::BitArray{1}
end
Split(L::Int64) = Split(falses(L))
length(s::Split) = length(s.dat)
iterate(s::Split) = iterate(s.dat)
iterate(s::Split, i::Int64) = iterate(s.dat, i)
getindex(s::Split, i::Int64) = s.dat[i]
"""
	==(s::Split, t::Split)
"""
==(s::Split, t::Split) = (s.dat == t.dat)
"""
	isequal(s::Split, t::Split, mask::Array{Bool,1})
"""
function isequal(s::Split, t::Split, mask::Array{Bool,1})
	for (i,m) in enumerate(mask)
		if m && s.dat[i] != t.dat[i]
			return false
		end
	end
	return true
end

"""
	is_root_split(s::Split, mask::Array{Bool,1})
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
function isempty(s::Split, mask::Array{Bool,1})
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
	SplitList{T}

```
leaves::Array{T,1}
splits::Array{Split,1}
mask::Array{Bool,1}	
```
"""
struct SplitList{T}
	leaves::Array{T,1}
	splits::Array{Split,1}
	mask::Array{Bool,1}
	SplitList{T}(leaves::Array{T,1}, splits, mask) where T = issorted(leaves) ? new(leaves, splits, mask) : @error("Leaves must be sorted")
end
SplitList(leaves::Array{T,1}, splits::Array{Split,1}, mask::Array{Bool,1}) where T = SplitList{T}(leaves, splits, mask)

length(S::SplitList) = length(S.splits)
iterate(S::SplitList) = iterate(S.splits)
iterate(S::SplitList, i::Int64) = iterate(S.splits, i)
getindex(S::SplitList, i::Int64) = getindex(S.splits, i)
lastindex(S::SplitList) = lastindex(S.splits)
isempty(S::SplitList) = isempty(S.splits)
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

Compute the list of splits below `r`, including `r` itself.  The `mask` attribute of the result is determined by the set of leaves that are descendents of `r`. 
"""
function SplitList(r::TreeNode, leaves)
	!issorted(leaves) ? leaves_srt = sort(leaves) : leaves_srt = leaves
	leafmap = Dict(leaf=>i for (i,leaf) in enumerate(leaves_srt))
	# Compute mask : leaves that are descendents or `r`
	rleaves = node_leavesclade_labels(r)
	mask = zeros(Bool, length(leaves_srt))
	for l in rleaves
		mask[leafmap[l]] = true
	end
	#
	S = SplitList(leaves_srt, Array{Split,1}(undef,0), mask)
	_splitlist!(S, r, leafmap)
	sortleaves!(S)
	return S	
end
"""
	SplitList(r::TreeNode, leaves, mask)

Compute the list of splits below `r`, including `r` itself.  
"""
function SplitList(r::TreeNode, leaves, mask)
	!issorted(leaves) ? leaves_srt = sort(leaves) : leaves_srt = leaves
	leafmap = Dict(leaf=>i for (i,leaf) in enumerate(leaves_srt))
	S = SplitList(leaves_srt, Array{Split,1}(undef,0), mask)
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
	end
	return s
end

function show(io::IO, S::SplitList)
	for (i,s) in enumerate(S)
		println(io, S.leaves[s.dat .* S.mask])
		if i > 20
			println("...")
			break
		end
	end
end
show(S::SplitList) = show(stdout, S)


"""
	isequal(s::SplitList, i::Int64, j::Int64; mask=true) 
"""
function isequal(s::SplitList, i::Int64, j::Int64; mask=true) 
	if mask
		return isequal(s.splits[i], s.splits[j], s.mask)
	else
		return s.splits[i] == s.splits[j]
	end
end

"""
	arecompatible(s::Split,t::Split)
	arecompatible(s::Split,t::Split, mask::Array{Bool})

Four possible states: `(0,0), (0,1), (1,0), (1,1)`. If all four are seen, the splits are not compatible.  
"""
function arecompatible(s::Split,t::Split)
	flag = falses(4)
	for (x,y) in zip(s,t)
		if !flag[1] && !x && !y
			flag[1] = true
			if alltrue(flag) return false end
		elseif !flag[2] && !x && y
			flag[2] = true
			if alltrue(flag) return false end
		elseif !flag[3] && x && !y
			flag[3] = true
			if alltrue(flag) return false end
		elseif !flag[4] && x && y 
			flag[4] = true
			if alltrue(flag) return false end
		end
	end
	return true
end	
function arecompatible(s::Split,t::Split, mask::Array{Bool})
	flag = falses(4)
	for m in Iterators.filter(x->x, mask)
		for (x,y) in zip(s,t)
			if !flag[1] && !x && !y
				flag[1] = true
				if alltrue(flag) return false end
			elseif !flag[2] && !x && y
				flag[2] = true
				if alltrue(flag) return false end
			elseif !flag[3] && x && !y
				flag[3] = true
				if alltrue(flag) return false end
			elseif !flag[4] && x && y 
				flag[4] = true
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
	iscompatible(s::Split, S::SplitList, mask=true)

Is `s` compatible with splits in `S`. 
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
	in(s::Split, S::SplitList, mask=S.mask)

Is `s` in `S`? 
"""
function in(s::Split, S::SplitList, mask=S.mask)
	for t in S
		if isequal(s, t ,mask)
			return true
		end
	end
	return false
end

"""
Return array of splits in S that are not in T.

`mask` options: `:left`, `:right`, `:none`. 
"""
function setdiff(S::SplitList, T::SplitList, mask=:left)
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
	sd = Array{Split,1}(undef,0)
	for s in S
		if !in(s, T, m) && !is_root_split(s, m) && !is_leaf_split(s, m) && !isempty(s,m)
			push!(sd, s)
		end
	end
	return sd
end

"""
	clean!(S::SplitList)

Remove leaf and empty splits according to S.mask. Option to remove root.
"""
function clean!(S::SplitList, mask=S.mask; 
			clean_leaves=true, clean_root=false)
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


