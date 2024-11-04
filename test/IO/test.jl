# println("##### reading #####")

using Test
using TreeTools

# Reading

@testset "Basic" begin
    @test typeof(read_tree("$(dirname(pathof(TreeTools)))/../test/IO/trees.nwk")) <:
        Vector{<:Tree}
    @test typeof(read_tree("$(dirname(pathof(TreeTools)))/../test/IO/tree.nwk")) <: Tree
    @test isa(
        read_tree(
            "$(dirname(pathof(TreeTools)))/../test/IO/tree.nwk"; node_data_type=MiscData
        ),
        Tree{MiscData},
    )

    @test read_tree(
        "$(dirname(pathof(TreeTools)))/../test/IO/tree.nwk"; label="test_tree"
    ).label == "test_tree"
end

# Writing

@testset "Writing to file" begin
    tmp_file_name, tmp_file_io = mktemp()
    t1 = parse_newick_string("((D,A,B),C);")
    @test try
        write_newick(tmp_file_name, t1, "w")
        true
    catch err
        false
    end
    @test try
        write_newick(tmp_file_io, t1)
        true
    catch err
        false
    end

    @test try
        write(tmp_file_name, t1)
        true
    catch err
        false
    end
    @test try
        write(tmp_file_io, t1)
        true
    catch err
        false
    end
end
