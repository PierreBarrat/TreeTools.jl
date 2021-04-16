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
TreeTools.init_fitchstates!(t)
@testset "Fitch init" begin
	@test mich.data.dat[:fitchstate].state == [[DNA_G], [DNA_C], [DNA_C], [DNA_G], [DNA_Gap]]
end

TreeTools.fitch_up!(t)
@testset "Fitch up" begin
	@test mich.data.dat[:fitchstate].state == [[DNA_G], [DNA_C], [DNA_C], [DNA_G], [DNA_Gap]]
	@test n1.data.dat[:fitchstate].state == [[DNA_C, DNA_A], [DNA_C], [DNA_A, DNA_G], [DNA_G], [DNA_A, DNA_Gap]]
	@test n2.data.dat[:fitchstate].state == [[DNA_C, DNA_A], [DNA_C], [DNA_C, DNA_A], [DNA_G], [DNA_A, DNA_Gap]]
	@test mich.anc.data.dat[:fitchstate].state == [[DNA_G, DNA_C, DNA_A], [DNA_C], [DNA_C, DNA_A, DNA_G], [DNA_G], [DNA_Gap, DNA_A]]
	@test t.root.data.dat[:fitchstate].state == [[DNA_C, DNA_A], [DNA_C], [DNA_C, DNA_A], [DNA_G], [DNA_Gap, DNA_A]]
end

TreeTools.fitch_remove_gaps!(t)
@testset "Fitch remove gaps" begin
	@test n1.data.dat[:fitchstate].state == [[DNA_C, DNA_A], [DNA_C], [DNA_A, DNA_G], [DNA_G], [DNA_A]]
	@test t.root.data.dat[:fitchstate].state == [[DNA_C, DNA_A], [DNA_C], [DNA_C, DNA_A], [DNA_G], [DNA_A]]
	@test mich.data.dat[:fitchstate].state == [[DNA_G], [DNA_C], [DNA_C], [DNA_G], [DNA_Gap]]
end

TreeTools.fitch!(t, clear_fitch_states=false)
@testset "Fitch" begin
	@test (t.root.data.dat[:fitchstate].state[3] == [DNA_C] || t.root.data.dat[:fitchstate].state[3] == [DNA_A])
	@test (mich.anc.data.dat[:fitchstate].state[3] == [DNA_A] || mich.anc.data.dat[:fitchstate].state[3] == [DNA_C])
	@test (t.root.data.dat[:fitchstate].state[3] == [DNA_C] && n1.data.dat[:fitchstate].state[3] == [DNA_A, DNA_G, DNA_C]) || (t.root.data.dat[:fitchstate].state[3] == [DNA_A] && n1.data.dat[:fitchstate].state[3] == [DNA_A]) 
end

TreeTools.fitch!(t, (:cmseq, :otherseg), clear_fitch_states=true)
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
end
