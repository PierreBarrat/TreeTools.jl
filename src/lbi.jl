export lbi!, set_live_nodes!


let state::Float64 = 0.
	global lbi_newstate(x) = (state=x)
	global lbi_getstate() = (state)
	global lbi_resetstate() = lbi_newstate(0)
end

"""
	lbi!(r::TreeNode{LBIData}, τ)
	lbi!(t::Tree{LBIData}, τ)
"""
function lbi!(r::TreeNode{LBIData}, τ::Float64 ; normalize=true)
	# set_to_zero!(r::TreeNode{LBIData})
	get_message_up!(r::TreeNode{LBIData}, τ)
	send_message_down!(r::TreeNode{LBIData}, τ)
	compute_lbi!(r::TreeNode{LBIData})
	if normalize
		normalize_lbi!(r)
	end
	return nothing
end
lbi!(r::TreeNode{LBIData}, τ; normalize=true) = lbi!(r, convert(Float64, τ), normalize=true)
function lbi!(t::Tree{LBIData}, τ; normalize=true) 
	if length(findall(x->x.data.alive, t.lleaves)) < 1
		@warn "Cannot compute LBI for tree with dead leaves."
		return true
	end
	lbi!(t.root, τ, normalize=normalize)
	return false
end
lbi!(t::Tree{EvoData}, τ; normalize=true) = error("Cannot compute LBI for type Tree{EvoData}. Read the tree with keyword `LBIData`.")

"""
	set_to_zero!(n::TreeNode{LBIData})
"""
function set_to_zero!(n::TreeNode{LBIData})
	n.data.lbi = 0.
	for c in n.child
		set_to_zero!(c)
	end
end

"""
	compute_lbi!(n::TreeNode{LBIData})
"""
function compute_lbi!(n::TreeNode{LBIData})
	if n.data.alive
		n.data.lbi = n.data.message_down
		for c in n.child
			compute_lbi!(c)
			n.data.lbi += c.data.message_up
		end
	else
		n.data.lbi = 0.
		for c in n.child
			set_to_zero!(c)
		end
	end
end

"""
	get_message_up!(n::TreeNode{LBIData}, τ)

Get message going up from node `n`. Ask for up messages `m_c` for all children `c` of `n`. Return `exp(-t/τ) * sum(m_c) + τ * (1 - exp(-t/τ)` where `t=n.data.tau`. Field `message_up` in `n`'s data is modified. 
"""
function get_message_up!(n::TreeNode{LBIData}, τ::Float64)
	n.data.message_up = 0.
	n.data.message_down = 0.
	for c in n.child
		n.data.message_up += get_message_up!(c, τ)
	end
	n.data.message_up *= exp(-n.data.tau/τ)
	if n.data.alive
		(n.data.message_up += τ*(1 - exp(-n.data.tau/τ)))
	end
	return n.data.message_up
end

"""
	send_message_down!(n::TreeNode{LBIData}, τ)

Send message going down from node `n`. Field `c.message_down` is modified for all children `c` of `n`. No return value. 

## Note
It's a bit easier to think of this function as operating on `c.anc` where `c` is a child of `n`. Maybe I should code it like this.
"""
function send_message_down!(n::TreeNode{LBIData}, τ::Float64)
	for c1 in n.child
		c1.data.message_down = n.data.message_down
		for c2 in n.child
			if c1 != c2
				c1.data.message_down += c2.data.message_up
			end
		end
		c1.data.message_down *= exp(-c1.data.tau/τ) 
		if c1.data.alive 
			c1.data.message_down += τ*(1 - exp(-c1.data.tau/τ))
		end
		send_message_down!(c1,τ)
	end
	return nothing
end

"""
	normalize_lbi!(r::TreeNode{LBIData})
	normalize_lbi!(t::Tree)
"""
function normalize_lbi!(r::TreeNode{LBIData})
	max_lbi = get_max_lbi(r::TreeNode{LBIData})
	normalize_lbi!(r::TreeNode{LBIData}, max_lbi)
end
normalize_lbi!(t::Tree) = normalize_lbi!(t.root)
function normalize_lbi!(n::TreeNode{LBIData}, max_lbi::Float64)
	if max_lbi == 0.
		@error "Maximum LBI is 0, cannot normalize."
	end
	for c in n.child
		normalize_lbi!(c, max_lbi)
	end
	n.data.lbi /= max_lbi
end

"""
	get_max_lbi(r::TreeNode{LBIData})

Return maximal LBI value of the subtree below `r`.
"""
function get_max_lbi(r::TreeNode{LBIData})
	lbi_resetstate()
	_get_max_lbi(r)
	return lbi_getstate()
end
function _get_max_lbi(n::TreeNode{LBIData})
	for c in n.child
		_get_max_lbi(c)
	end
	if n.data.lbi > lbi_getstate()
		lbi_newstate(n.data.lbi)
	end	
end


"""
	set_live_nodes!(n::TreeNode{LBIData}; datemin=missing, datemax=missing)
	set_live_nodes!(t::Tree; datemin=missing, datemax=missing)

Recursively sets the `.data.alive` field of tree nodes. 
- If `n` is a leaf node, `n.data.date` must strictly be between `datemin` and `datemax` (if not missing).
- If `n` is a non-terminal node, at least one of its children must be alive.
"""
function set_live_nodes!(n::TreeNode{LBIData}; datemin=missing, datemax=missing, set_leaves=true)
	for c in n.child
		set_live_nodes!(c, datemin=datemin, datemax=datemax, set_leaves=set_leaves)
	end
	if set_leaves && n.isleaf 
		n.data.alive = (ismissing(datemin) || n.data.date > datemin) && (ismissing(datemax) || n.data.date < datemax)
	elseif !n.isleaf
		n.data.alive = mapreduce(x->x.data.alive, |, n.child, init=false)
	end
	return nothing
end
set_live_nodes!(t::Tree; datemin=missing, datemax=missing, set_leaves=true) = set_live_nodes!(t.root, datemin=datemin, datemax=datemax, set_leaves=set_leaves)

