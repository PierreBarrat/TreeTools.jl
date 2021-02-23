"""
	resolve!(t::Tree, S::SplitList; conflict=:ignore, usemask=false, tau=0.)

Add splits in `S` to `t` by introducing internal nodes. 
If `conflict != :ignore`, will fail if a split `s` in `S` is not compatible with `t`. 
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
			elseif conflict
				@error "Conflicting splits"
			end
		end
	end
	node2tree!(t, t.root)
end