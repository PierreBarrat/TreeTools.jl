export resolve! 


"""
	resolve!(t::Tree, S::SplitList; conflict=:ignore, usemask=false, tau=0.)

Add splits in `S` to `t` by introducing internal nodes. New nodes are assigned a time `tau` (`0` by default). 
If `conflict != :ignore`, will fail if a split `s` in `S` is not compatible with `t`. Otherwise, silently skip the conflicting splits. 
"""
function resolve!(t::Tree{T}, S::SplitList; conflict=:ignore, usemask=false, tau=0.) where T
	# Label for created nodes
	label_i = parse(Int64, create_label(t, "RESOLVED")[10:end])
	#
	tsplits = SplitList(t)
	for (i,s) in enumerate(S)
		if !in(s, tsplits)
			if iscompatible(s, tsplits, usemask=usemask)
				if usemask
					roots = blca([t.lleaves[x] for x in S.leaves[S[i].dat .* S.mask]]...)
				else
					roots = blca([t.lleaves[x] for x in S.leaves[S[i].dat]]...)
				end
				R = lca(roots)
				# Creating a new node with `roots` as children and `r` as ancestor. 
				nr = TreeNode(T(), label="RESOLVED_$(label_i)")
				label_i += 1
				for r in roots
					prunenode!(r)
					graftnode!(nr,r)
				end
				graftnode!(R, nr, tau=tau)
				push!(tsplits.splits, s)
			elseif conflict != :ignore
				@error "Conflicting splits"
			end
		end
	end
	node2tree!(t, t.root)
end

"""
	resolve(trees::Dict{T, <:Tree}, splits::Dict{T, <:SplitList}; kwargs...) where T

Resolve `trees[s]` with splits in `splits[s]` by calling `TreeTools.resolve!`. `trees` and `splits` must share keys. This is meant to be used for dictionaries of trees/splits indexed by flu segments.
"""
function resolve(trees::Dict{T, <:Tree}, splits::Dict{T, <:SplitList}; kwargs...) where T
	resolved_trees = deepcopy(trees)
	for (s,S) in splits
		TreeTools.resolve!(resolved_trees[s], S; kwargs...)
	end
	return resolved_trees
end

"""
	resolve_ref!(Sref::SplitList, S::Vararg{SplitList}, usemask=false)

Add new and compatible splits of `S` to `Sref`. If `usemask`, masks are used to determine compatibility. Return the number of added splits. 
**Note**: the order of `S` matters if its elements contain incompatible splits! 
"""
function resolve_ref!(Sref::SplitList, S::Vararg{SplitList}; usemask=false)
	c = 0
	for s in S
		for x in s
			if !in(x, Sref) && iscompatible(x, Sref, usemask=usemask)
				push!(Sref.splits, x)
				c += 1
			end
		end
	end
	return c
end

"""
	resolve!(S::Vararg{SplitList})

Resolve each element of `S` using other elements by calling `resolve!(S[i],S)` for all `i` until no new split can be added. If `usemask`, masks are used to determine compatibility. 
"""
function resolve!(S::Vararg{SplitList}; usemask=false)
	nit = 0
	nitmax = 20
	flag = true
	while flag && nit < nitmax
		flag = false
		for s in S
			c = resolve_ref!(s, S..., usemask=usemask)
			if c != 0 
				flag = true
			end
		end
		nit += 1
	end
	if nit == nitmax 
		@warn "Maximum number of iterations reached"
	end
	nothing
end

"""
	resolve!(t1::Tree, t2::Tree; tau=0.)

Resolve `t1` using `t2` and inversely. Return new splits in each tree. 
"""
function resolve!(t1::Tree, t2::Tree; tau=0.)
	S = [SplitList(t) for t in (t1,t2)]
	tsplits_a = deepcopy(S)
	resolve!(S...; usemask=false)
	for (t,s) in zip((t1,t2), S)
		resolve!(t, s, conflict=:fail, usemask=true, tau=tau)
	end
	return [SplitList(S[i].leaves, setdiff(S[i], tsplits_a[i]), S[i].mask, S[i].splitmap) for i in 1:length(S)]
end
