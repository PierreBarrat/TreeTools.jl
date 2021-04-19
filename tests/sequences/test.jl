using Test
using TreeTools
using BioSequences

t = read_tree("tree.nwk")
alnfile = "aln.fasta"
incomplete_alnfile = "aln_incomplete.fasta"

@testset "Reading fasta alignment" begin
	println("Should display warning below:")
	@test !TreeTools.fasta2tree!(t, incomplete_alnfile)
	@test TreeTools.fasta2tree!(t, alnfile)
end

## Testing fitch

t = read_tree("tree.nwk")
mich = t.lnodes["A/Michigan/41/2015"]
sing = t.lnodes["A/Singapore/H2013721a/2013"]
penn = t.lnodes["A/Pennsylvania/28/2014"]
thai = t.lnodes["A/Thailand/CU-CB166/2014"]
flo = t.lnodes["A/Florida/62/2015"]

n1 = lca(flo, thai)
n2 = lca(sing, penn)
r = t.root

fasta2tree!(t, "aln.fasta")

i = rand(1:5)
TreeTools.init_fitchstates!(t,i)
@testset "Fitch init" begin
	@test mich.data.dat[:fitchstate].state == [Set(DNA_G), Set(DNA_C), Set(DNA_C), Set(DNA_G), Set(DNA_Gap)][i]
end

TreeTools.fitch_up!(t)
@testset "Fitch up" begin
	@test mich.data.dat[:fitchstate].state == [Set(DNA_G), Set(DNA_C), Set(DNA_C), Set(DNA_G), Set(DNA_Gap)][i]
	@test n1.data.dat[:fitchstate].state == [Set([DNA_C, DNA_A]), Set(DNA_C), Set([DNA_A, DNA_G]), Set(DNA_G), Set([DNA_A, DNA_Gap])][i]
	@test n2.data.dat[:fitchstate].state == [Set([DNA_C, DNA_A]), Set(DNA_C), Set([DNA_C, DNA_A]), Set(DNA_G), Set([DNA_A, DNA_Gap])][i]
	@test mich.anc.data.dat[:fitchstate].state == [Set([DNA_G, DNA_C, DNA_A]), Set(DNA_C), Set([DNA_C, DNA_A, DNA_G]), Set(DNA_G), Set([DNA_Gap, DNA_A])][i]
	@test t.root.data.dat[:fitchstate].state == [Set([DNA_C, DNA_A]), Set([DNA_C]), Set([DNA_C, DNA_A]), Set([DNA_G]), Set([DNA_Gap, DNA_A])][i]
end

TreeTools.fitch_remove_gaps!(t)
@testset "Fitch remove gaps" begin
	@test n1.data.dat[:fitchstate].state == [Set([DNA_C, DNA_A]), Set([DNA_C]), Set([DNA_A, DNA_G]), Set([DNA_G]), Set([DNA_A])][i]
	@test t.root.data.dat[:fitchstate].state == [Set([DNA_C, DNA_A]), Set([DNA_C]), Set([DNA_C, DNA_A]), Set([DNA_G]), Set([DNA_A])][i]
	@test mich.data.dat[:fitchstate].state == [Set([DNA_G]), Set([DNA_C]), Set([DNA_C]), Set([DNA_G]), Set([DNA_Gap])][i]
end

TreeTools.fitch!(t, clear_fitch_states=false, variable_positions = missing)
@testset "Fitch" begin
	@test in(t.root.data.dat[:seq], [dna"ACAGA", dna"ACCGA", dna"CCAGA", dna"CCCGA"])
	@test in(mich.anc.data.dat[:seq][1], [DNA_C, DNA_A])
	@test in(mich.anc.data.dat[:seq][3], [DNA_C, DNA_A])
end

TreeTools.fitch!(t, (:cmseq, :otherseg), clear_fitch_states=true, variable_positions = missing)
@testset "Nested keys" begin
	for n in values(t.lnodes)
		if !n.isleaf
			@test !haskey(n.data.dat, :fitchstate)
			@test haskey(n.data.dat, :cmseq)
			@test haskey(n.data.dat[:cmseq], :otherseg)
		else
			@test !haskey(n.data.dat, :fitchstate)
			@test !haskey(n.data.dat, :cmseq)
		end
	end
	@test in(t.root.data.dat[:cmseq][:otherseg], [dna"ACAGA", dna"ACCGA", dna"CCAGA", dna"CCCGA"])
end
