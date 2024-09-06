using Documenter
#using EComplexity

makedocs(
    sitename = "EComplexity.jl",
    format = Documenter.HTML(),
    #modules = [Ecomplexity],
    clean     = true,
    pages = Any[
      "Introduction" => "index.md",    
         "User Guide" => Any[
          "getting_started.md",
          "r_integration.md"
        ],
        "Economic Complexity Theory" => Any[
            "economic_complexity_theory.md"
          ]      
])


# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/milocortes/EComplexity.jl.git"
)
