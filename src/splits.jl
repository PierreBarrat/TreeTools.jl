#=====================#
######## Split ########
#=====================#

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

# Iteration
Base.iterate(s::Split) = iterate(s.dat)
Base.iterate(s::Split, i::Integer) = iterate(s.dat, i)
Base.IteratorSize(::Type{Split}) = HasLength()
Base.length(s::Split) = length(s.dat)
Base.size(s::Split) = length(s)
Base.IteratorEltype(::Type{Split}) = HasEltype()
Base.eltype(::Type{Split}) = Int
Base.eltype(::Split) = Int

# Indexing
Base.getindex(s::Split, i::Integer) = s.dat[i]

# Equality
Base.:(==)(s::Split, t::Split) = (s.dat == t.dat)
"""
	isequal(s::Split, t::Split[, mask::Array{Bool,1}])

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
Base.isequal(s::Split, t::Split) = (s.dat == t.dat)
Base.hash(s::Split, h::UInt) = hash(s.dat, h)

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
	isroot(s::Split, mask::Array{Bool,1})

Check if `s` is the root split when restricted to `mask`.
"""
isroot(s::Split, mask) = is_root_split(s, mask)

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
	isleaf(s::Split)
	isleaf(s::Split, mask::Array{Bool,1})

Check if `s` is a leaf split.
"""
isleaf(s::Split) = is_leaf_split(s)
isleaf(s::Split, mask) = is_leaf_split(s, mask)

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
	is_sub_split(s::Split, t::Split[, mask])

Check if `s` is a subsplit of `t`.
"""
function is_sub_split(s::Split, t::Split)
    _in = maximum(length(t)) > 20 ? insorted : in
    for i in s
        if !_in(i, t.dat)
            return false
        end
    end

    return true
end
function is_sub_split(s::Split, t::Split, mask)
    _in = maximum(length(t)) > 20 ? insorted : in
    for i in s
        if mask[i] && !_in(i, t.dat)
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
        if _in(i, t.dat)
            return false
        end
    end

    for i in t
        if _in(i, s.dat)
            return false
        end
    end

    return true
end

function are_disjoint(s::Split, t::Split, mask)
    _in = maximum(length(t)) > 20 ? insorted : in
    for i in s
        if mask[i] && _in(i, t.dat)
            return false
        end
    end

    for i in t
        if mask[i] && _in(i, s.dat)
            return false
        end
    end

    return true
end

#=================================#
############ SplitList ############
#=================================#

"""
	SplitList{T}

- `leaves::Array{T,1}`: labels of leaves
- `splits::Array{Split,1}`
- `mask::Array{Bool,1}`: subset of leaves for which splits apply.
- `splitmap::Dict{T,Split}`: indicate the split corresponding to the branch above a node.
  Only initialized if built from a tree with labels on internal nodes.

# Constructors
	SplitList(leaves::Array{T,1}) where T

Empty `SplitList`.

	SplitList(t::Tree[, mask])

List of splits in `t`. `mask` defaults to ones.

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
    function SplitList{T}(leaves::Array{T,1}, splits, mask, splitmap) where {T}
        if issorted(leaves) && allunique(leaves)
            return new(leaves, splits, mask, splitmap)
        else
            @error("Leaves must be sorted and unique")
        end
    end
end
function SplitList(
    leaves::Array{T,1}, splits::Array{Split,1}, mask::Array{Bool,1}, splitmap::Dict
) where {T}
    return SplitList{T}(leaves, splits, mask, convert(Dict{T,Split}, splitmap))
end

function SplitList(leaves::Array{T,1}) where {T}
    return SplitList{T}(
        leaves, Array{Split,1}(undef, 0), ones(Bool, length(leaves)), Dict{T,Split}()
    )
end

# Iteration
Base.iterate(S::SplitList) = iterate(S.splits)
Base.iterate(S::SplitList, i::Integer) = iterate(S.splits, i)
Base.IteratorSize(::Type{SplitList}) = HasLength()
Base.length(S::SplitList) = length(S.splits)
Base.IteratorEltype(::Type{SplitList}) = HasEltype()
Base.eltype(::Type{SplitList}) = TreeTools.Split
Base.eltype(::SplitList) = Split

# Indexing
Base.getindex(S::SplitList, i) = getindex(S.splits, i)
Base.setindex!(S::SplitList, s::Split, i) = setindex!(S.splits, s, i)
Base.firstindex(S::SplitList) = firstindex(S.splits)
Base.lastindex(S::SplitList) = lastindex(S.splits)
Base.eachindex(S::SplitList) = eachindex(S.splits)
Base.isempty(S::SplitList) = isempty(S.splits)
Base.keys(S::SplitList) = LinearIndices(S.splits)

# Equality
function Base.:(==)(S::SplitList, T::SplitList)
    return S.leaves == T.leaves &&
               sort(S.splits; by=x -> x.dat) == sort(T.splits; by=x -> x.dat) &&
               S.mask == T.mask
end
Base.hash(S::SplitList, h::UInt) = hash(S.splits, h)

"""
    cat(S1::SplitList, S...)
"""
function Base.cat(S1::SplitList{T}, Smore::Vararg{SplitList{T}}) where {T}
    @argcheck all(S -> S.leaves == S1.leaves && S.mask == S1.mask, Smore) """
    Input `SplitList`s must share the same leaves and mask.
    """

    S_cat = SplitList(S1.leaves, Array{Split,1}(undef, 0), S1.mask, Dict{T,Split}())
    for S in Smore
        append!(S_cat.splits, S.splits)
    end
    unique!(S_cat.splits)
    return S_cat
end

"""
	isroot(S::SplitList, i)

Is `S[i]` the root?
"""
isroot(S::SplitList, i) = isroot(S[i], S.mask)

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
    leafmap = Dict(leaf => i for (i, leaf) in enumerate(leaves))
    return SplitList(t.root, leaves, mask, leafmap)
end
function SplitList(r::TreeNode, leaves)
    leaves_srt = !issorted(leaves) ? sort(leaves) : leaves
    leafmap = Dict(leaf => i for (i, leaf) in enumerate(leaves_srt))
    # Compute mask : leaves that are descendents or `r`
    mask = zeros(Bool, length(leaves_srt))
    set_mask(n) =
        if n.isleaf
            mask[leafmap[n.label]] = true
        end
    map!(set_mask, r)
    #
    S = SplitList(leaves_srt, Array{Split,1}(undef, 0), mask, Dict{eltype(leaves),Split}())
    _splitlist!(S, r, leafmap)
    return S
end
function SplitList(
    r::TreeNode,
    leaves,
    mask,
    leafmap=Dict(leaf => i for (i, leaf) in enumerate(sort(leaves))),
)
    !issorted(leaves) ? leaves_srt = sort(leaves) : leaves_srt = leaves
    S = SplitList(
        leaves_srt, Array{Split,1}(undef, 0), mask, Dict{eltype(leaves_srt),Split}()
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
                _joinsplits!(s, sc, i)
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
    println(io, "SplitList of $(length(S)) splits")
    max_i = 20
    for (i, s) in enumerate(S)
        if i > max_i
            println(io, "... ($(length(S)-max_i) more)")
            break
        end
        println(io, leaves(S, i))
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
    return sort([leaves(S, i) for i in eachindex(S.splits)]) == sort(A)
end
==(S::SplitList, A::AbstractArray) = isequal(S, A)

"""
	arecompatible(s::Split, t::Split[, mask::Array{Bool}])

Are splits `s` and `t` compatible **in the cluster sense**.

	arecompatible(s::SplitList, i::Integer, j::Integer; mask=true)

Are `s.splits[i]` and `s.splits[j]` compatible **in the cluster sense**?
"""
function arecompatible(s::Split, t::Split)
    if is_sub_split(s, t) || is_sub_split(t, s)
        return true
    elseif are_disjoint(s, t)
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

Is `s` compatible with all splits in `S`?
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
        if (!in(s, T, m; usemask) && !isroot(s, m) && !isleaf(s, m) && !isempty(s, m))
            push!(U.splits, s)
        end
    end
    return U
end

"""
	union(S::SplitList, T::SplitList, mask=:none)
	union!(S::SplitList, T::SplitList, mask=:none)

Build a union of `Split`s. Ignore potential incompatibilities. Possible values of
  `mask` are `:none, :left, :right`.
"""
union, union!

function Base.union!(S::SplitList, T::SplitList; mask=:none)
    if mask == :none
        m = ones(Bool, length(S.leaves))
    elseif mask == :left
        m = S.mask
    elseif mask == :right
        m = T.mask
    else
        @error "Unrecognized `mask` kw-arg."
    end

    for t in T
        if !in(t, S, m)
            push!(S.splits, t)
        end
    end

    return S
end
function Base.union!(S::SplitList, T...; mask=:none)
    for t in T
        union!(S, t)
    end
    return S
end

function Base.union(S::SplitList, T...; mask=:none)
    if mask == :none
        m = ones(Bool, length(S.leaves))
    elseif mask == :left
        m = S.mask
    elseif mask == :right
        m = T.mask
    else
        @error "Unrecognized `mask` kw-arg."
    end

    U = SplitList(copy(S.leaves))
    union!(U, S, T...; mask)

    return U
end

"""
	intersect(S::SplitList, T::SplitList, mask=:none)

Build an intersection of `Split`s. Possible values of `mask` are `:none, :left, :right`.
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
	unique(S::SplitList; usemask=true)
	unique!(S::SplitList; usemask=true)
"""
unique, unique!

function Base.unique!(S::SplitList; usemask=true)
    todel = Int64[]
    hashes = Dict{Array{Int,1},Bool}()
    for (i, s) in enumerate(S)
        if haskey(hashes, s.dat)
            push!(todel, i)
        end
        hashes[s.dat] = true
    end
    return deleteat!(S.splits, todel)
end

function Base.unique(S::SplitList; usemask=true)
    Sc = deepcopy(S)
    unique!(Sc; usemask=usemask)
    return Sc
end

"""
	clean!(S::SplitList, mask=S.mask;
		clean_leaves=true, clean_root=false
	)

Remove leaf and empty splits according to S.mask. Option to remove root.
"""
function clean!(S::SplitList, mask=S.mask; clean_leaves=true, clean_root=false)
    idx = Int64[]
    for (i, s) in enumerate(S)
        if clean_leaves && isleaf(s, mask)
            push!(idx, i)
        elseif clean_root && isroot(s, mask)
            push!(idx, i)
        elseif isempty(s, mask)
            push!(idx, i)
        end
    end
    return deleteat!(S.splits, idx)
end

#############################################################
####################### Indexing Tree #######################
#############################################################

function Base.getindex(tree::Tree, S::SplitList, i::Int)
    return lca(tree, leaves(S, i)...)
end
