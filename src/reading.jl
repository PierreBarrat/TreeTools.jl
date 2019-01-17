export parse_newick!, nw_parse_children, nw_parse_name, read_newick
export fasta2tree!, seq2num

using FastaIO

"""
"""
function read_newick(nw_file::String)
	f = open(nw_file)
	nw = readlines(f)
	close(f)
	if length(nw) > 1
		error("File $nw_file has more than one line.")
	elseif length(nw) == 0 
		error("File $nw_file is empty")
	end 
	nw = nw[1]
	if nw[end] != ';'
		error("File $nw_file does not end with ';'")
	end
	nw = nw[1:end-1]

	root = TreeNode()
	parse_newick!(nw, root)
	root.isroot = true # Rooting the tree with outer-most node of the newick string

	return root
end

"""
	parse_newick!(nw::String, root::TreeNode)

Parse the tree contained in Newick string `nw`, rooting it at `root`. 
"""
function parse_newick!(nw::String, root::TreeNode)

	# Setting isroot to false. Special case of the root is handled in main calling function
	root.isroot = false
	# Getting label of the node, after last parenthesis
	parts = map(x->String(x), split(nw, ")")) 
	root.label, root.data.tau = nw_parse_name(String(parts[end]))

	if length(parts) == 1 # Is a leaf. Subtree is empty
		root.isleaf = true
	else # Has children
		root.isleaf = false
		if parts[1][1] != '('
			println(parts[1][1])
			error("Parenthesis mismatch.")
		else
			parts[1] = parts[1][2:end] # Removing first bracket
		end
		children = join(parts[1:end-1], ")") # String containing children, now delimited with ','
		l_children = nw_parse_children(children) # List of children (array of strings)

		for sc in l_children
			nc = TreeNode()
			parse_newick!(sc, nc) # Will set everything right for subtree corresponding to nc
			nc.anc = root
			push!(root.child, nc)
		end
	end

end

"""
	nw_parse_children(s::String)

Idea from http://stackoverflow.com/a/26809037  
Split a string of children in newick format to an array of strings. 

## Example
`"A,(B,C),D"` --> `["A","(B,C)","D"]` 
"""
function nw_parse_children(s::String)
	parcount = 0
	l_children = []
	current = ""
	for c in "$(s),"
		if c == ',' && parcount == 0
			push!(l_children, current)
			current = ""
		else
			if c == '('
				parcount +=1
			elseif c == ')'
				parcount -=1
			end
			current = string(current, c)
		end
	end
	return l_children
end

"""
	nw_parse_name(s::String)

Parse Newick string of child into name and time to ancestor. Default value for missing time is `missing`. 
"""
function nw_parse_name(s::String)
	temp = split(s, ":")
	if occursin(':', s) # Node has a time 	
		if length(temp) == 2 # Node also has a name, return both
			tau = (tau = tryparse(Float64,temp[2]); typeof(tau)==Nothing ? missing : tau) # Dealing with unparsable times
			return string(temp[1]), tau
		else # Return empty name
			tau = (tau = tryparse(Float64,temp[1]); typeof(tau)==Nothing ? missing : tau) # Dealing with unparsable times
			return "", tau
		end
	else # Node does not have a time, return string as name
		return s, missing
	end
end




"""
"""
function fasta2tree!(tree::Tree, fastafile::String ; seqtype="nucleotide")
	for (name,seq) in FastaReader(fastafile)
		key, flag = tree_findlabel(name, tree)
		if !flag
			@warn "Sequence labeled $name could not be found in tree."
		else
			numseq = seq2num(seq, seqtype)
			tree.nodes[key].data.sequence = numseq
			if seqtype == "nucleotide"
				tree.nodes[key].data.q = 5
			elseif seqtype == "AA"
				tree.nodes[key].data.q = 21
			end
		end
	end		
end

"""
"""
function seq2num(seq::String, seqtype)
	if seqtype == "nucleotide"
		mapping = "ACGT-NWSMKRY"
		numseq = zeros(Int64, length(seq))
		for (i,c) in enumerate(seq)
			num = findall(x->x==c, mapping)
			if isempty(num)
				@warn "String $seq could not be matched to nucleotides -- position ($i, $c)"
			else
				numseq[i] = findall(x->x==c, mapping)[1]<5 ? findall(x->x==c, mapping)[1] : 5
			end
		end
	end
	return numseq
end	
