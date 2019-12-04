export parse_newick!, nw_parse_children, nw_parse_name, read_newick, read_tree
export fasta2tree!, seq2num

using FastaIO

let n::Int64=0
	global increment_n() = (n+=1)
	global reset_n() = (n=0)
end

"""
	read_tree(nw_file::String; NodeDataType=EvoData)

Read Newick file `nw_file` and create a `Tree{NodeDataType}` object from it.    
`NodeDataType` must be a subtype of `TreeNodeData`, and must have a *callable default outer constructor*. In other words, the call `NodeDataType()` must exist and return a valid instance of `NodeDataType`. This defaults to `EvoData`.
"""
function read_tree(nw_file::String; NodeDataType=EvoData)
	# println("Checking Tree")
	@time tree = node2tree(read_newick(nw_file; NodeDataType=NodeDataType))
	check_tree(tree)
	return tree
end

"""
	read_newick(nw_file::String; NodeDataType=EvoData)

Read Newick file `nw_file` and create a graph of `TreeNode{NodeDataType}` objects in the process. Return the root of said graph. `node2tree` or `read_tree` must be called to obtain a `Tree{NodeDataType}` object.   
`NodeDataType` must be a subtype of `TreeNodeData`, and must have a *callable default outer constructor*. In other words, the call `NodeDataType()` must exist and return a valid instance of `NodeDataType`. This defaults to `EvoData`.   
"""
function read_newick(nw_file::String; NodeDataType=EvoData)
	@assert NodeDataType <: TreeNodeData
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

	reset_n()
	root = TreeNode(NodeDataType())
	parse_newick!(nw, root, NodeDataType)
	root.isroot = true # Rooting the tree with outer-most node of the newick string
	close(f)

	return root
end

"""
	parse_newick!(nw::String, root::TreeNode)

Parse the tree contained in Newick string `nw`, rooting it at `root`. 
"""
function parse_newick!(nw::String, root::TreeNode, NodeDataType)

	# Setting isroot to false. Special case of the root is handled in main calling function
	root.isroot = false
	# Getting label of the node, after last parenthesis
	parts = map(x->String(x), split(nw, ")")) 
	lab, tau = nw_parse_name(String(parts[end]))
	if lab == ""
		lab = "NODE_$(increment_n())"
	end
	root.label, root.data.tau = (NodeDataType == LBIData && ismissing(tau) ? (lab,0.) : (lab,tau))

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
			nc = TreeNode(NodeDataType())
			parse_newick!(sc, nc, NodeDataType) # Will set everything right for subtree corresponding to nc
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
	cstart = 1
	cend = 1
	for (i,c) in enumerate("$(s),")
		if c == ',' && parcount == 0
			cend = i-1
			push!(l_children, s[cstart:cend])
			cstart = i+1
		else
			if c == '('
				parcount +=1
			elseif c == ')'
				parcount -=1
			end
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
	fasta2tree!(tree::Tree{EvoData}, fastafile::String ; seqtype=:nucleotide)

Read `fastafile` and stores sequences in nodes of `tree` with corresponding label.  
Implemented sequence types are `:nucleotide` and `:binary`.
"""
function fasta2tree!(tree::Tree{EvoData}, fastafile::String ; seqtype=:nucleotide)
	for (name,seq) in FastaReader(fastafile)
		if haskey(tree.lnodes, name)
			# storeseq!(tree.lnodes[name], seq, seqtype)
			tree.lnodes[name].data.sequence = [c for c in seq]
		end
	end		
end


"""
	storeseq!(node::TreeNode{EvoData}, seq, seqtype)

Store sequence `seq` at node `node`. 
"""
function storeseq!(node::TreeNode{EvoData}, seq, seqtype)
	if seqtype==:nucleotide
		numseq = seq2num(seq, seqtype)
		node.data.sequence = numseq
		node.data.q = 5
	elseif seqtype==:binary
		if isa(seq, String)
			node.data.sequence = map(x->parse(Int64, x), collect(seq))
		elseif isa(seq, Array{Int64})
			node.data.sequence = seq
		else
			error("Unrecognized format for sequence `seq`.")
		end
		node.data.q = 2
	else
		println("Accepted sequence types are `:binary` and `:nucleotide`.")
		error("Unknown seq-type.")
	end
end

"""
"""
function seq2num(seq::String, seqtype)
	if seqtype == :nucleotide
		mapping = "ACGT-NWSMKRYBDHV"
		numseq = zeros(Int64, length(seq))
		for (i,c) in enumerate(seq)
			num = findall(x->x==c, mapping)
			if isempty(num)
				@warn "String $seq could not be matched to nucleotides -- position ($i, $c)"
			else
				numseq[i] = findall(x->x==c, mapping)[1]
				# numseq[i] = findall(x->x==c, mapping)[1]<5 ? findall(x->x==c, mapping)[1] : 5
			end
		end
	end
	return numseq
end	

"""
"""
function seq2num(c::Char, seqtype)
	if seqtype == :nucleotide
		mapping = "ACGT-NWSMKRYBDHV"
		num = findall(x->x==c, mapping)
		if isempty(num)
			@warn "String $seq could not be matched to nucleotides -- position ($i, $c)"
		else
			numseq = findall(x->x==c, mapping)[1]
		end
	end
	return numseq
end	




