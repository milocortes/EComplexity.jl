using Documenter
using EComplexity

makedocs(
    sitename = "EComplexity.jl",
    format = Documenter.HTML(),
    modules = [Ecomplexity],
    clean     = true,
    pages = Any[
        "Economic Complexity" => "index.md",
        "Modelo" => Any[
           "modelo/dsolg.md"
         ],        
         "Datos" => Any[
          "datos/dsolg_data.md"
        ],
        "Calibración" => Any[
            "calib/dsolg_calib.md"
          ]      
])

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/milocortes/EComplexity.jl.git"
)
