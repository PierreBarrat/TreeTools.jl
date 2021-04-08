using Test
using TreeTools

t = read_tree("tree.nwk")
alnfile = "aln.fasta"
incomplete_alnfile = "aln_incomplete.fasta"

@testset "Reading fasta alignment" begin
	@test !TreeTools.fasta2tree!(t, incomplete_alnfile)
	@test TreeTools.fasta2tree!(t, alnfile)
end