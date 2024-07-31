# EComplexity : Economic Complexity in Julia

EComplexity is a package to calculate economic complexity indices in Julia. The package is inspired by others implementations as [py-ecomplexity](https://github.com/cid-harvard/py-ecomplexity/tree/master).

The EComplexity package is developed by the [Laboratorio de Desarrollo Regional](https://egobiernoytp.tec.mx/es/investigacion/laboratorio-desarrollo-regional) team of the [Escuela de Gobierno y Transformación Pública](https://egobiernoytp.tec.mx/es) 

## GitHub installation
To install EComplexity from GitHub, you must first have a working Julia installation on your computer. 

Once Julia is set up, start a Julia session and add the `EComplexity` package:

```julia
julia> ]

pkg> add https://github.com/milocortes/EComplexity.jl.git
```

## Usage

```julia
# Import packages
using EComplexity
using CSV
using DataFrames

using ZipFile
import Downloads

### Import trade data from CID Atlas
data_url = "https://intl-atlas-downloads.s3.amazonaws.com/"
file_name = "country_hsproduct2digit_year.csv.zip"

# Downloads the file in the current working directory
Downloads.download(data_url*file_name, file_name)

# Extracts data from a ZIP file
trade_data_CID_atlas_archive = ZipFile.Reader(file_name)

# Load data from the descompressed zip file
data = CSV.read(read(trade_data_CID_atlas_archive.files[1]), DataFrame)

# Select specific columns of the dataframe
data = data[:,[:year,:location_code,:hs_product_code,:export_value]]

# Subset rows 
complex_data = data[data.year .==2010,:]

# Define column names for location, product and value
value_col_name = "export_value"
activiy_col_name = "hs_product_code"
place_col_name = "location_code"

# Calculate complexity metrics
cdata = complexity_metrics(complex_data, value_col_name, activiy_col_name, place_col_name)

## Calculate proximity matrix
# Compute RCA
paises_RCA = RCA(complex_data, value_col_name, activiy_col_name, place_col_name)

# Compute M matrix
M_rca = build_Mcp(paises_RCA, activiy_col_name, place_col_name, 1.0)

# Compute proximity
proximity_mat = proximity(M_rca, activiy_col_name, place_col_name)

```