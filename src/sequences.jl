export fasta2tree!
export fitch!

"""
	fasta2tree!(tree, fastafile::String, key=:seq; warn=true)
"""
function fasta2tree!(tree, fastafile::String, key=:seq; warn=true)
	reader = open(FASTA.Reader, fastafile)
	record = FASTA.Record()
	while !eof(reader)
	    read!(reader, record)
	    if haskey(tree.lnodes, identifier(record))
	    	tree.lnodes[identifier(record)].data.dat[:seq] = sequence(record)
	    end
	end
	#
	flag = true
	for (name, n) in tree.lleaves
		if !haskey(n.data.dat, :seq)
			n.data.dat[:seq] = missing
			flag = false
		end
	end
	warn && !flag && @warn "Not all leaves had a corresponding sequence in the alignment (file: $fastafile)."
	return flag
end


struct FitchState{T}
	state::Array{Array{T,1},1}
end
function FitchState(L::Int64, ::Val{T}) where T  
	state = Array{Array{T,1}, 1}(undef, L)
	for i in 1:L
		state[i] = Array{T,1}(undef,0)
	end
	return FitchState{T}(state)
end
function FitchState(s::BioSequences.LongSequence, ::Val{T}) where T
	L = length(s)
	fs = FitchState(L, Val(T))
	for (i,a) in enumerate(s)
		push!(fs.state[i], a)
	end
	return fs
end
FitchState(s::BioSequences.LongSequence) = FitchState(s, Val(eltype(s)))

length(s::FitchState) = length(s.state)


"""
"""
function fitch!(t::Tree, outkey=:ancestral_seq, seqkey=:seq)
	fitchkey = :fitchstate
	@time init_fitchstates!(t, fitchkey, seqkey)
	@time fitch_up!(t, fitchkey)
	@time fitch_remove_gaps!(t, fitchkey)
	@time fitch_root_state!(t, fitchkey)
	@time fitch_down!(t, fitchkey)
	@time fitch_remove_gaps!(t, fitchkey)
	@time fitch_sample!(t, outkey, fitchkey)
end

"""
	init_fitchstates!(t::Tree, fitchkey=:fitchstate, seqkey = :seq)
"""
function init_fitchstates!(t::Tree, fitchkey=:fitchstate, seqkey = :seq)
	for n in values(t.lleaves)
		n.data.dat[fitchkey] = FitchState(n.data.dat[seqkey])
	end
end

"""
	ancestral_state(fstates::Vararg{FitchState{T}}) where T
"""
function ancestral_state(fs::FitchState{T}, fstates::Vararg{FitchState{T}}) where T
	aFs = deepcopy(fs)
	for i in 1:length(aFs.state)
		intersect!(aFs, i, fstates...)
		if isempty(aFs.state[i]) || (length(aFs.state[i]) == 1 && isgap(first(aFs.state[i])))
			aFs.state[i] = union(fs.state[i], (s.state[i] for s in fstates)...)
			unique!(aFs.state[i])
		end
	end
	return aFs
end
_in(x) = y -> in(y, x)
function intersect!(aFs::FitchState{T}, i, fstates::Vararg{FitchState{T}}) where T
	for fs in fstates
		filter!(_in(fs.state[i]), aFs.state[i])
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
	for (i,fs) in enumerate(t.root.data.dat[fitchkey].state)
		L = Dict{Any,Float64}()
		# Compute likelihood of each possible state at position i
		for (k,a) in enumerate(fs) 
			for c in t.root.child
				if !ismissing(c.data.tau)
					!haskey(L,a) && (L[a] = 0.)
					if isempty(intersect([a], c.data.dat[fitchkey].state[i]))
						# Mutation needed
						L[a] += 1 - exp(-c.data.tau)
					else
						L[a] += exp(-c.data.tau)
					end
				end
			end
		end
		amax = isempty(L) ? rand(fs) : findmax(L)[2]
		t.root.data.dat[fitchkey].state[i] = [amax]
	end
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
fitch_down!(t::Tree, fitchkey) = fitch_down!(t.root, fitchkey)

"""
"""
function fitch_remove_gaps!(t, fitchkey=:fitchstate)
	for n in values(t.lnodes)
		if !n.isleaf
			for (i,fs) in enumerate(n.data.dat[fitchkey].state)
				if length(fs) > 1
					for (k,a) in enumerate(fs)
						if isgap(a)
							deleteat!(fs, k)
							break
						end
					end
				end
			end
		end
	end
end

"""
"""
function fitch_sample!(t::Tree, outkey, fitchkey=:fitchstate)
	for n in values(t.lnodes)
		if !n.isleaf
			n.data.dat[outkey] = fitch_sample(n.data.dat[fitchkey])
		end
	end
end
fitch_sample(fs::FitchState{DNA}) = LongDNASeq([rand(s) for s in fs.state])
fitch_sample(fs::FitchState{RNA}) = LongRNASeq([rand(s) for s in fs.state])
fitch_sample(fs::FitchState{AminoAcid}) = LongAminoAcidSeq([rand(s) for s in fs.state])
fitch_sample(fs::FitchState{Char}) = LongCharSeq([rand(s) for s in fs.state])