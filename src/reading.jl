let n::Int64=0
	global increment_n() = (n+=1)
	global reset_n() = (n=0)
end

let file::String = ""
	global get_nwk_file() = file
	global set_nwk_file(s) = (file=s)
end

"""
	read_tree(
		nwk_filename::AbstractString;
		node_data_type=DEFAULT_NODE_DATATYPE, force_new_labels=false
	)
	read_tree(
		io::IO;
		node_data_type=DEFAULT_NODE_DATATYPE, force_new_labels=false
	)

Read Newick file and create a `Tree{node_data_type}` object from it. The input file can \
contain multiple Newick strings on different lines. The output will then be an array of \
`Tree` objects.

`node_data_type` must be a subtype of `TreeNodeData`, and must have a *callable default outer
constructor*: the call `node_data_type()` must exist and return a valid instance of
`node_data_type`. See `?TreeNodeData` for implemented types.

Use `force_new_labels=true` to force the renaming of all internal nodes.

If you have a variable containing a Newick string and want to build a tree from it,
use `parse_newick_string` instead.

## Note on labels
The `Tree` type identifies nodes by their labels. This means that labels have to be unique.
For this reason, the following is done when reading a tree:
- if an internal node does not have a label, a unique one will be created of the form \
	`"NODE_i"`
- if a node has a label that was already found before in the tree, a random identifier \
	will be appended to it to make it unique. Note that the identifier is created using \
	`randstring(8)`, unicity is technically not guaranteed.
- if `force_new_labels` is used, a unique identifier is appended to node labels
- if node labels in the Newick file are identified as confidence/bootstrap values, a random \
	identifier is appended to them, even if they're unique in the tree. See \
	`?TreeTools.isbootstrap` to see which labels are identified as confidence values.
"""
function read_tree(
	io::IO;
	node_data_type=DEFAULT_NODE_DATATYPE, force_new_labels=false
)
	trees = map(eachline(io)) do line
		t = parse_newick_string(line; node_data_type, force_new_labels)
		check_tree(t)
		t
	end
	return length(trees) == 1 ? trees[1] : trees
end
function read_tree(
	nwk_filename::AbstractString;
	node_data_type=DEFAULT_NODE_DATATYPE, force_new_labels=false
)
	return open(nwk_filename, "r") do io
		read_tree(io; node_data_type, force_new_labels)
	end
end
"""
	parse_newick_string(
		nw::AbstractString;
		node_data_type=DEFAULT_NODE_DATATYPE, force_new_labels=false
	)

Parse newick string into a tree. See `read_tree` for more informations.
"""
function parse_newick_string(
	nw::AbstractString;
	node_data_type=DEFAULT_NODE_DATATYPE, force_new_labels=false,
)
	@assert nw[end] == ';' "Newick string does not end with ';'"

	reset_n()
	root = TreeNode(node_data_type())
	parse_newick!(nw[1:end-1], root, node_data_type)
	root.isroot = true
	tree = node2tree(root; force_new_labels)
	check_tree(tree)
	return tree
end

"""
	read_newick(nwk_filename::AbstractString)

Read Newick file `nwk_filename` and create a graph of `TreeNode` objects in the process.
  Return the root of said graph.
  `node2tree` or `read_tree` must be called to obtain a `Tree` object.
"""
function read_newick(nwk_filename::AbstractString; node_data_type=DEFAULT_NODE_DATATYPE)
	@assert node_data_type <: TreeNodeData
	set_nwk_file(nwk_filename)

	f = open(nwk_filename)
	nw = readlines(f)
	close(f)
	if length(nw) > 1
		error("File $nwk_filename has more than one line.")
	elseif length(nw) == 0
		error("File $nwk_filename is empty")
	end
	nw = nw[1]
	if nw[end] != ';'
		error("File $nwk_filename does not end with ';'")
	end
	nw = nw[1:end-1]

	reset_n()
	root = parse_newick(nw; node_data_type)
	return root
end

"""
	parse_newick(nw::AbstractString; node_data_type=DEFAULT_NODE_DATATYPE)

Parse newick string into a `TreeNode`.
"""
function parse_newick(nw::AbstractString; node_data_type=DEFAULT_NODE_DATATYPE)
	if isempty(nw)
		error("Cannot parse empty Newick string.")
	end
	reset_n()
	root = TreeNode(node_data_type())
	parse_newick!(nw, root, node_data_type)
	root.isroot = true # Rooting the tree with outer-most node of the newick string
	root.tau = missing
	return root
end

"""
	parse_newick!(nw::AbstractString, root::TreeNode)

Parse the tree contained in Newick string `nw`, rooting it at `root`.
"""
function parse_newick!(nw::AbstractString, root::TreeNode, node_data_type)

	# Setting isroot to false. Special case of the root is handled in main calling function
	root.isroot = false
	# Getting label of the node, after last parenthesis
	parts = map(x->String(x), split(nw, ")"))
	lab, tau = nw_parse_name(String(parts[end]))
	if lab == ""
		lab = "NODE_$(increment_n())"
	elseif length(lab) > 1 && lab[1:2] == "[&" # Deal with extended newick annotations
		lab = "NODE_$(increment_n())" * lab
	end

	root.label, root.tau = (lab,tau)

	if length(parts) == 1 # Is a leaf. Subtree is empty
		root.isleaf = true
	else # Has children
		root.isleaf = false
		if parts[1][1] != '('
			println(parts[1][1])
			@error "Parenthesis mismatch around $(parts[1]). This may be caused by spaces in the newick string."
			error("$(get_nwk_file()): incorrect Newick format.")
		else
			parts[1] = parts[1][2:end] # Removing first bracket
		end
		children = join(parts[1:end-1], ")") # String containing children, now delimited with ','
		l_children = nw_parse_children(children) # List of children (array of strings)

		for sc in l_children
			nc = TreeNode(node_data_type())
			parse_newick!(sc, nc, node_data_type) # Will set everything right for subtree corresponding to nc
			nc.anc = root
			push!(root.child, nc)
		end
	end

end

"""
	nw_parse_children(s::AbstractString)

Idea from http://stackoverflow.com/a/26809037
Split a string of children in newick format to an array of strings.

## Example
`"A,(B,C),D"` --> `["A","(B,C)","D"]`
"""
function nw_parse_children(s::AbstractString)
	parcount = 0
	annotation = false # For reading extended newick grammar, with [&key=val] after label
	l_children = []
	current = ""
	cstart = 1
	cend = 1
	for (i,c) in enumerate("$(s),")
		if c == '['
			annotation = true
		elseif c == ']'
			annotation = false
		elseif c == ',' && parcount == 0 && annotation == false
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
	nw_parse_name(s::AbstractString)

Parse Newick string of child into name and time to ancestor. Default value for missing time is `missing`.
"""
function nw_parse_name(s::AbstractString)
	temp = split(s, ":")
	if occursin(':', s) # Node has a time
		if length(temp) == 2 # Node also has a name, return both
			tau = (tau = tryparse(Float64,temp[2]); isnothing(tau) ? missing : tau) # Dealing with unparsable times
			return string(temp[1]), tau
		else # Return empty name
			tau = (tau = tryparse(Float64,temp[1]); isnothing(tau) ? missing : tau) # Dealing with unparsable times
			return "", tau
		end
	else # Node does not have a time, return string as name
		return s, missing
	end
end





