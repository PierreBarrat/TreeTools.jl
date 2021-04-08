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
