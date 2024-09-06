# R integration with [JuliaCall](https://cran.r-project.org/web/packages/JuliaCall/readme/README.html)

Package [JuliaCall](https://cran.r-project.org/web/packages/JuliaCall/readme/README.html) is an R interface to Julia. 

## Usage
The next block of code shows the basic usage of JuliaCall and EComplexity.jl:

```R
### Install JuliaCall
install.packages("JuliaCall")

### Load JuliaCall package
library(JuliaCall)

### Set the actual Julia binary path in your computer
options(JULIA_HOME="/home/milo/julia_bins/julia-1.9.3/bin/")

### Install EComplexity.jl
julia_command('using Pkg ; Pkg.add(url = "https://github.com/milocortes/EComplexity.jl.git")')

### Verify the installation
julia_installed_package("EComplexity")

### Load dataset
df <- read.csv("https://raw.githubusercontent.com/milocortes/InvESt_complexity/main/datos/data_test_EComplexity_package/complex_data.csv")

### Load EComplexity.jl
julia_library("EComplexity")

### Execute the function that calculates the complexity measures
cdata <- julia_eval("complexity_metrics")(df, "export_value", "hs_product_code", "location_code")
```

