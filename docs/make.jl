using Documenter
using TreeTools

using BenchmarkTools

makedocs(;
    sitename="TreeTools",
    format=Documenter.HTML(),
    modules=[TreeTools],
    pages=[
        "Home" => "index.md",
        "Basic concepts" => "basic_concepts.md",
        "Reading and writing" => "IO.md",
        "Iteration" => "Iteration.md",
        "Useful functions" => "useful_functions.md",
        "Modifying the tree" => "modifying_the_tree.md",
    ],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
deploydocs(; repo="github.com/PierreBarrat/TreeTools.jl.git")
