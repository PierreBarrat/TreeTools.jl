using Test
using TreeTools

# println("##### iterators #####")

@testset "POT traversal" begin
	nwk = "(((A1:1,A2:1,B:1,C:1)i_2:0.5,(D1:0,D2:0)i_3:1.5)i_1:1,(E:1.5,(F:1.0,(G:0.,H:0.)i_6:0.5)i_5:1)i_4:1)i_r;"
	tree = parse_newick_string(nwk);
	node_list = sort(["A1", "A2", "B", "C", "i_2", "D1", "D2", "i_3", "i_1", "E", "F", "G", "H", "i_6", "i_5", "i_4", "i_r"])
	leaves_list = sort(["A1", "A2", "B", "C", "D1", "D2", "E", "F", "G", "H"])
    internals_list = sort(setdiff(node_list, leaves_list))
    internals_noroot_list = sort(filter(!=("i_r"), internals_list))

	@testset "Core function _POT" begin
        R = root(tree)
		@test sort([x.label for x in TreeTools._POT(R)]) == node_list
		@test sort([x.label for x in TreeTools._POT(isleaf, R)]) == leaves_list
        @test sort([x.label for x in TreeTools._POT(isinternal, R)]) == internals_list
	end

    @testset "postorder_traversal: basics" begin
        @test sort([x.label for x in postorder_traversal(root(tree))]) == node_list
        @test sort([x.label for x in postorder_traversal(tree; leaves=false)]) == internals_list
        @test sort([x.label for x in postorder_traversal(tree; root=false, leaves=false)]) == internals_noroot_list
        @test isempty(sort([x.label for x in postorder_traversal(tree, leaves=false, internals=false)]))
        iter = postorder_traversal(tree; internals=false) do node
            label(node) != "A1"
        end
        @test sort([x.label for x in iter]) == leaves_list[2:end]

        X = [x.label for x in postorder_traversal(isinternal, tree)]
        Y = [x.label for x in postorder_traversal(tree; leaves=false)]
        @test X == Y
    end

    @testset "postorder_traversal: node order" begin
        function all_labels(node, holder = [])
            for c in children(node)
                all_labels(c, holder)
            end
            push!(holder, label(node))
        end
        @test [x.label for x in postorder_traversal(tree)] == all_labels(root(tree))
        @test map(label, postorder_traversal(tree["i_2"])) == all_labels(tree["i_2"])
    end

    @testset "map - based on postorder" begin
        function all_labels(node, holder = [])
            for c in children(node)
                all_labels(c, holder)
            end
            push!(holder, label(node))
        end
        @test map(label, tree) == all_labels(root(tree))
        @test map(label, tree["i_2"]) == all_labels(tree["i_2"])
    end
end


@testset "Other" begin
    nwk = "(((A1:1,A2:1,B:1,C:1)i_2:0.5,(D1:0,D2:0)i_3:1.5)i_1:1,(E:1.5,(F:1.0,(G:0.,H:0.)i_6:0.5)i_5:1)i_4:1)i_r;"
    tree = parse_newick_string(nwk)
    node_list = sort(["A1", "A2", "B", "C", "i_2", "D1", "D2", "i_3", "i_1", "E", "F", "G", "H", "i_6", "i_5", "i_4", "i_r"])
    leaves_list = sort(["A1", "A2", "B", "C", "D1", "D2", "E", "F", "G", "H"])
    internals_list = sort(setdiff(node_list, leaves_list))
    internals_noroot_list = sort(filter(!=("i_r"), internals_list))

    @testset "in" begin
        for n in nodes(tree)
            @test in(n, tree)
            @test in(n.label, tree)
            if !n.isleaf
                @test !in(n, tree; exclude_internals=true)
            end
        end
    end

    @testset "indexing in tree" begin
        for n in nodes(tree)
            @test tree[n.label] == tree.lnodes[n.label]
        end
        @test_throws KeyError tree["some_random_string"]
    end
end
