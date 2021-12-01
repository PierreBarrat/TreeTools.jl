using TreeTools
using BioSequences
using Profile

t = read_tree("tree.nwk")
alnfile = "aln.fasta"

fasta2tree!(t, "aln.fasta")
TreeTools.fitch!(t, (:cmseq, :otherseg), clear_fitch_states=true)
Profile.clear_malloc_data()
TreeTools.fitch!(t, (:cmseq, :otherseg), clear_fitch_states=true)