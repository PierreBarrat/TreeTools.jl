# println("##### objects #####")

using TreeTools
using Test

@testset "Node relabel" begin
    nwk = "(A,(B,C));"
    tree = parse_newick_string(nwk)
    label!(tree, tree["A"], "D")
    @test check_tree(tree)
    @test !in("A", tree)
    @test in("D", tree)
    @test length(nodes(tree)) == 5
    labels = map(label, postorder_traversal(tree))
    @test !in("A", labels)
    @test in("D", labels)
    @test sort(labels) == sort(map(label, tree))

    @test_throws ArgumentError label!(tree, tree["D"], "B")
    @test_throws ArgumentError label!(tree, "D", "B")
end
