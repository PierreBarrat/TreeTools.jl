using Test
using TreeTools
using BioSequences

t = read_tree("sequences/tree.nwk", NodeDataType=TreeTools.MiscData)
alnfile = "sequences/aln.fasta"
incomplete_alnfile = "sequences/aln_incomplete.fasta"

@testset "Reading fasta alignment" begin
	println("Should display warning below:")
	@test !TreeTools.fasta2tree!(t, incomplete_alnfile)
	@test TreeTools.fasta2tree!(t, alnfile)
end

