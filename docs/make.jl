using Documenter
using TreeTools

makedocs(
    sitename = "TreeTools",
    format = Documenter.HTML(),
    modules = [TreeTools],
    pages = [
    	"Index" => "index.md",
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
deploydocs(
    repo = "github.com/PierreBarrat/TreeTools.jl.git",
)
