function parse_mutation(mut::AbstractString)
	oldstate = mut[1]
	newstate = mut[end]
	pos = parse(Int64, mut[2:end-1])
	return Mutation(pos, oldstate, newstate)
end
parse_mutation(mut::Mutation) = mut





