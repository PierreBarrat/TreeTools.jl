export fasta2tree!
export fitch!

"""
	fasta2tree!(tree, fastafile::String, key=:seq; warn=true)

Add sequences of `fastafile` to tips of `tree`. For a leaf `n`, sequence is added to `n.data.dat[key]`. 
"""
function fasta2tree!(tree, fastafile::String, key::Union{Symbol, AbstractString}=:seq; warn=true)
	reader = open(FASTA.Reader, fastafile)
	record = FASTA.Record()
	while !eof(reader)
	    read!(reader, record)
	    if haskey(tree.lnodes, identifier(record))
	    	tree.lnodes[identifier(record)].data.dat[key] = sequence(record)
	    end
	end
	#
	flag = true
	for (name, n) in tree.lleaves
		if !haskey(n.data.dat, key)
			n.data.dat[key] = missing
			flag = false
		end
	end
	warn && !flag && @warn "Not all leaves had a corresponding sequence in the alignment (file: $fastafile)."
	return flag
end

"""
	fasta2tree!(tree, fastafile::String, ks::Tuple; warn=true)

Add sequences of `fastafile` to tips of `tree`. For a leaf `n`, sequence is added to `n.data.dat[ks[1]][ks[2]]...`. 	
"""
function fasta2tree!(tree, fastafile::String, ks::Tuple; warn=true)
	# Setting dicts
	for n in values(tree.lleaves)
		recursive_key_init!(n.data.dat, ks[1:end-1]...)
	end
	key = ks[end]
	#
	reader = open(FASTA.Reader, fastafile)
	record = FASTA.Record()
	while !eof(reader)
	    read!(reader, record)
	    if haskey(tree.lnodes, identifier(record))
	    	recursive_set!(tree.lnodes[identifier(record)].data.dat, sequence(record), ks...)
	    end
	end
	#
	flag = true
	for (name, n) in tree.lleaves
		if !recursive_haskey(n.data.dat, ks...)
			recursive_set!(n.data.dat, missing, ks...)
			flag = false
		end
	end
	warn && !flag && @warn "Not all leaves had a corresponding sequence in the alignment (file: $fastafile)."
	return flag
end


_alphabet(s::LongSequence{T}) where T = BioSequences.symbols(T())
function get_variable_positions(t::Tree, seqkey)
	L = length(recursive_get(first(t.lleaves)[2].data.dat, seqkey))
	keep = _alphabet(recursive_get(first(t.lleaves)[2].data.dat, seqkey))
	#
	variable = Int64[]
	fixed = collect(1:L)
	state = Array{Any,1}(missing, L)
	# 
	for n in values(t.lleaves)
		seq = recursive_get(n.data.dat, seqkey)
	    todel = Int64[]
	    for i in fixed
	    	if ismissing(state[i]) && !isgap(seq[i]) && in(seq[i], keep) 
	    	# If state not initialized for i, initialize
	    		state[i] = seq[i]
	    	elseif !ismissing(state[i]) && seq[i] != state[i] && !isgap(seq[i]) &&in(seq[i], keep) 
	    	# If state was initialized and changed, this is a variable column
	    		push!(variable, i)
	    		push!(todel, i)
	    	end
	    end	
	    # Deleting variable positions from fixed
	    for i in todel
	    	deleteat!(fixed, findfirst(==(i), fixed))
	    end
	end
	return sort(variable)
end


struct FitchState{T}
	state::Set{T}
end
FitchState(::Val{T}) where T  = FitchState{T}(Set{T}())
FitchState(a::T) where T = FitchState{T}(Set(a))
isempty(fs::FitchState) = isempty(fs.state)
length(s::FitchState) = length(s.state)


"""
	fitch!(t::Tree, outkey=:ancestral_seq, seqkey=:seq; clear_fitch_states=true, variable_positions=missing)
"""
function fitch!(t::Tree, outkey=:seq, seqkey=:seq; clear_fitch_states=true, variable_positions=Int64[])
	fitchkey = :fitchstate
	# Initializing ancestral sequences
	seq = recursive_get(first(t.lleaves)[2].data.dat, seqkey)
	init_ancestral_sequences!(t, outkey, seq)

	#Getting variable positions
	if ismissing(variable_positions)
		variable_positions = 1:length(seq)
	elseif isempty(variable_positions)
		variable_positions = get_variable_positions(t, seqkey)
	end

	# Algorithm
	for i in 1:length(seq)
		if in(i, variable_positions)
			init_fitchstates!(t, i, seqkey, fitchkey)
			fitch_up!(t, fitchkey)
			fitch_remove_gaps!(t, fitchkey)
			fitch_root_state!(t, fitchkey)
			fitch_down!(t, fitchkey)
			fitch_remove_gaps!(t, fitchkey)
			fitch_sample!(t, outkey, fitchkey)
		else
			for n in values(t.lnodes)
				if !n.isleaf
					recursive_push!(n.data.dat, seq[i], outkey)
				end
			end
		end
	end
	# Clearing fitch states
	if clear_fitch_states
		for n in values(t.lnodes)
			delete!(n.data.dat, :fitchstate)
		end
	end
end

function init_ancestral_sequences!(t, outkey, seq)
	for n in values(t.lnodes)
		if !n.isleaf
			n.data.dat[outkey] = similar(seq, 0)
		end
	end
end
function init_ancestral_sequences!(t, outkey::Tuple, seq)
	for n in values(t.lnodes)
		if !n.isleaf
			recursive_key_init!(n.data.dat, outkey[1:end-1]...)
			recursive_set!(n.data.dat, similar(seq, 0), outkey...)
		end
	end
end

"""
	init_fitchstates!(t::Tree, i::Int64, seqkey = :seq, fitchkey=:fitchstate)
"""
function init_fitchstates!(t::Tree, i::Int64, seqkey::Union{Symbol, AbstractString}=:seq, fitchkey=:fitchstate)
	for n in values(t.lleaves)
		n.data.dat[fitchkey] = FitchState(n.data.dat[seqkey][i])
	end
end
function init_fitchstates!(t::Tree, i::Int64, seqkey::Tuple, fitchkey=:fitchstate)
	for n in values(t.lleaves)
		n.data.dat[fitchkey] = FitchState(recursive_get(n.data.dat, seqkey...)[i])
	end
end

"""
	ancestral_state(fstates::Vararg{FitchState{T}}) where T
"""
function ancestral_state(fs::FitchState{T}, fstates::Vararg{FitchState{T}}) where T
	aFs = FitchState(Val(T))
	union!(aFs, fs)
	for s in fstates
		intersect!(aFs, s)
	end
	if isempty(aFs) || (length(aFs.state) == 1 && isgap(first(aFs.state)))
		union!(aFs, fs)
		for s in fstates
			union!(aFs, s)
		end
	end
	return aFs
end
_in(x) = y -> in(y, x)
function intersect!(aFs::FitchState, fstates::Vararg{FitchState})
	for fs in fstates
		filter!(_in(fs.state), aFs.state)
	end
end
function union!(aFs::FitchState, fs::FitchState)
	for a in Iterators.filter(!_in(aFs.state), fs.state)
		push!(aFs.state,a)
	end
end
"""
	get_downstream_state!(an::TreeNode, fitchkey=:fitchstate)
"""
function get_downstream_state!(an::TreeNode, fitchkey=:fitchstate)
	an.data.dat[fitchkey] = ancestral_state((n.data.dat[fitchkey] for n in an.child)...)
	nothing
end

"""
"""
function fitch_up!(r::TreeNode, fitchkey)
	for c in r.child
		!c.isleaf && fitch_up!(c, fitchkey)
	end
	get_downstream_state!(r, fitchkey)
end
fitch_up!(t::Tree, fitchkey=:fitchstate) = fitch_up!(t.root, fitchkey)

"""
"""
function fitch_root_state!(t::Tree, fitchkey=:fitchstate)
	fs = t.root.data.dat[fitchkey]
	L = Dict{Any,Float64}()
	# Compute likelihood of each possible state 
	for (k,a) in enumerate(fs.state) 
		for c in t.root.child
			if !ismissing(c.data.tau)
				!haskey(L,a) && (L[a] = 0.)
				if isempty(intersect([a], c.data.dat[fitchkey].state))
					# Mutation needed
					L[a] += 1 - exp(-c.data.tau)
				else
					L[a] += exp(-c.data.tau)
				end
			end
		end
	end
	amax = isempty(L) ? rand(fs.state) : findmax(L)[2]
	filter!(==(amax), fs.state)
end


"""
"""
function get_upstream_state!(n::TreeNode, fitchkey=:fitchstate)
	n.data.dat[fitchkey] = ancestral_state(n.data.dat[fitchkey], n.anc.data.dat[fitchkey])
end
function fitch_down!(r::TreeNode, fitchkey)
	!r.isroot && get_upstream_state!(r, fitchkey)
	for c in r.child
		!c.isleaf && fitch_down!(c, fitchkey)
	end
end
fitch_down!(t::Tree, fitchkey=:fitchstate) = fitch_down!(t.root, fitchkey)

"""
"""
function fitch_remove_gaps!(t, fitchkey=:fitchstate)
	for n in values(t.lnodes)
		if !n.isleaf && length(n.data.dat[fitchkey]) > 1
			filter!(!isgap, n.data.dat[fitchkey].state)
		end
	end
end

"""
"""
function fitch_sample!(t::Tree, outkey::Tuple, fitchkey=:fitchstate)
	for n in values(t.lnodes)
		if !n.isleaf
			recursive_push!(n.data.dat, rand(n.data.dat[fitchkey].state), outkey...)
		end
	end
end
function fitch_sample!(t::Tree, outkey::Union{Symbol, AbstractString}, fitchkey=:fitchstate)
	for n in values(t.lnodes)
		if !n.isleaf
			push!(n.data.dat[outkey], rand(n.data.dat[fitchkey].state))
		end
	end
end
fitch_sample(fs::FitchState{DNA}) = LongDNASeq([rand(s) for s in fs.state])
fitch_sample(fs::FitchState{RNA}) = LongRNASeq([rand(s) for s in fs.state])
fitch_sample(fs::FitchState{AminoAcid}) = LongAminoAcidSeq([rand(s) for s in fs.state])
fitch_sample(fs::FitchState{Char}) = LongCharSeq([rand(s) for s in fs.state])