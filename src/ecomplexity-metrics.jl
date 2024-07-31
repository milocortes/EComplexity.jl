export RCA
export build_Mcp
export metrics_diversity_ubiquity
export proximity
export density
export distance
export calc_coi_cog
export calc_eci_pci
export complexity_metrics

using DataFrames
using DataFramesMeta
using StatsBase
using LinearAlgebra

"""
    RCA(df, value_col_name, activiy_col_name, place_col_name)

La función RCA calcula la métrica de Ventaja Comparativa Revelada (Revealed Comparative Advantage).

...
# Arguments
- `df::DataFrames.DataFrame`: Dataframe de los datos para realizar los cálculos
- `value_col_name::String`: Nombre de la columna numérica en el dataframe de datos 
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`: Nombre de la columna correspondiente al lugar en el dataframe de datos 
...

# Examples
```julia-repl
julia> RCA(complex_data, "export_value", "hs_product_code", "location_code")
21958×3 DataFrame
   Row │ location_code  hs_product_code  rca         
       │ String3        String15         Float64     
───────┼─────────────────────────────────────────────
     1 │ ABW            01                0.00970607
     2 │ AFG            01                0.12928
     3 │ AGO            01                0.0
   ⋮   │       ⋮               ⋮              ⋮
 21957 │ WSM            financial         0.112092
 21958 │ ZAF            financial         1.18583
                                   21920 rows omitted

```
"""
function RCA(df::DataFrames.DataFrame,
             value_col_name::String, 
             activiy_col_name::String,
             place_col_name::String)::DataFrames.DataFrame

    ## Suma total de la variable con valores numéricos
    suma_total_actividad = sum(df[:,value_col_name])

    ## Valor de las actividades
    value_vec = df[:,value_col_name]

    ## Calcula RCA 
    df_rca = @chain df begin
        # Agrupamos por tipo de actividad
        groupby(activiy_col_name)
        # Suma de la variable con valores numéricos agrupada tipo de actividad 
        transform(value_col_name => sum => :suma_por_actividad)
        # Agrupamos por lugar
        groupby(place_col_name)
        ## Suma de la variable con valores numéricos agrupada por lugar
        transform(value_col_name => sum => :suma_por_lugar)
        ## Calculamos el RCA
        @transform :rca = (value_vec./:suma_por_lugar)./(:suma_por_actividad/suma_total_actividad)
    end 

    ## Seleccionamos las columnas
    df_rca = df_rca[:,[place_col_name, activiy_col_name, "rca"]]
    
    ## Ordenamos el dataframe de acuerdo a place_col_name y activiy_col_name
    sort!(df_rca, [place_col_name, activiy_col_name])

    return df_rca
end

"""
    build_Mcp(df, activiy_col_name, place_col_name)

La función build_Mcp calcula la matriz de presencia-ausencia a partir del cálculo del RCA.

...
# Arguments
- `df::DataFrames.DataFrame`: Dataframe de los datos para realizar los cálculos
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`  : Nombre de la columna correspondiente al lugar en el dataframe de datos 
- `rca_threshold::Float32=1.0`  : Valor de umbral de RCA utilizado para etiquetar como 1 y 0 los valores.
...

# Examples
```julia-repl
julia> build_Mcp(complex_data, "hs_product_code", "location_code")
224×103 DataFrame
 Row │ location_code  01     02     03     04     05     06     07     08     09     10     11     12     13     14     15     16     17     18     19     20     21     22     23     24     25     26     27    ⋯
     │ String3        Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64  Int64 ⋯
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ ABW                0      0      0      0      0      0      0      0      0      1      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      1 ⋯
   2 │ AFG                0      0      0      0      0      0      0      1      0      0      0      1      1      1      0      0      1      0      0      0      0      0      0      0      0      0      0
   3 │ AGO                0      0      1      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      1
   4 │ AIA                0      1      0      0      0      0      0      1      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      0      1      0      0
 ⋮  │       ⋮          ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮      ⋮   ⋱
 222 │ ZAF                0      0      1      0      0      0      0      1      0      0      1      0      0      0      0      0      1      0      0      1      0      1      0      0      1      1      1
 223 │ ZMB                0      0      0      0      0      1      1      0      1      0      0      0      0      1      0      0      1      0      0      0      0      0      0      1      1      0      0 ⋯
 224 │ ZWE                1      1      0      1      0      1      1      1      1      1      1      1      1      0      0      1      1      0      0      0      0      0      1      1      1      0      0

```
"""
function build_Mcp(df::DataFrames.DataFrame,
                   activiy_col_name::String,
                   place_col_name::String,
                   rca_threshold=1.0)::DataFrames.DataFrame

    ## Hacemos un reshape(unstack) sobre el dataframe del RCA para obtener una arreglo 2D (ubicación, actividad)
    df_mcp = @chain df begin
        # Convertimos de formato wide a long con key = place_col_name, variable = activiy_col_name y value = rca
        unstack(place_col_name, activiy_col_name, "rca")
        # Ordenamos el dataframe de acuerdo al lugar
        sort(place_col_name)
    end 

    ## Guardamos temporalmente la columna de ubicación
    place_temp = df_mcp[:, place_col_name]

    ## Eliminamos la columna del dataframe
    select!(df_mcp, Not(place_col_name))

    ## Reemplazamos los valores mayores al umbral por 1 y por 0 aquellos por debajo del umbral
    df_mcp = coalesce.(df_mcp .>= rca_threshold, 0)

    ## Agregamos nuevamente la columna de lugar
    insertcols!(df_mcp, 1,  place_col_name => place_temp)

    return df_mcp
    
end


"""
    metrics_diversity_ubiquity(M_rca, activiy_col_name, place_col_name, metric)

La función metrics_diversity_ubiquity calcula las medidas de diversidad y ubicuidad 
    a partir de la matriz de presencia-ausencia.
...
# Arguments
- `M_rca::DataFrames.DataFrame`: Dataframe de los datos para realizar los cálculos
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`:  Nombre de la columna correspondiente al lugar en el dataframe de datos 
- `metric::String`  : Médida a calcular (diversity o ubiquity)
...

# Examples
```julia-repl
julia> metrics_diversity_ubiquity(M_rca, "hs_product_code", "location_code", "diversity")
224×2 DataFrame
 Row │ location_code  diversity 
     │ String3        Int64     
─────┼──────────────────────────
   1 │ ABW                    4
   2 │ AFG                   13
   3 │ AGO                    3
  ⋮  │       ⋮            ⋮
 222 │ ZAF                   25
 223 │ ZMB                   12
 224 │ ZWE                   33
                186 rows omitted
```
"""
function metrics_diversity_ubiquity(M_rca::DataFrames.DataFrame,
    activiy_col_name::String,
    place_col_name::String,
    metric::String)::DataFrames.DataFrame

    ## Creamos una copia de la matriz M
    M_mat = M_rca[:,:]

    ## Guardamos temporalmente la columna de ubicación
    place_vec_temp = M_mat[:, place_col_name]

    ## Eliminamos la columna del dataframe
    select!(M_mat, Not(place_col_name))

    ## Guardamos temporalmente los valores de actividades
    activiy_vec_tem = names(M_mat)

    if metric == "diversity"
        df_count_value = DataFrame(place_col_name => place_vec_temp, 
                                   "diversity" => vec(sum(Matrix(M_mat), dims=2)))
    elseif metric == "ubiquity"
        df_count_value = DataFrame(activiy_col_name => activiy_vec_tem, 
                                   "ubiquity" => vec(sum(Matrix(M_mat), dims=1)))
    end


    return df_count_value

end

"""
    proximity(Mcp, activiy_col_name, place_col_name)

La función proximity calcula las medidas de proximidad entre actividades 
    a partir de la matriz de presencia-ausencia.
...
# Arguments
- `Mcp::DataFrames.DataFrame`: Matriz de presencia-ausencia
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`:  Nombre de la columna correspondiente al lugar en el dataframe de datos 
...

# Examples
```julia-repl
julia> proximity(M_rca, "hs_product_code", "location_code")
102×102 DataFrame
 Row │ 01         02         03         04         05         06         07         08        09         10         11         12         13         14         15        16         17         18         19     ⋯
     │ Float64    Float64    Float64    Float64    Float64    Float64    Float64    Float64   Float64    Float64    Float64    Float64    Float64    Float64    Float64   Float64    Float64    Float64    Float6 ⋯
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 1.0        0.354167   0.207921   0.354167   0.292308   0.145833   0.362319   0.2375    0.151515   0.3125     0.4375     0.37931    0.285714   0.259259   0.3125    0.316667   0.344828   0.3125     0.2708 ⋯
   2 │ 0.354167   1.0        0.128713   0.419355   0.246154   0.21875    0.188406   0.1625    0.106061   0.342105   0.333333   0.258621   0.142857   0.166667   0.275     0.283333   0.258621   0.270833   0.3870
   3 │ 0.207921   0.128713   1.0        0.158416   0.415842   0.168317   0.366337   0.425743  0.386139   0.178218   0.207921   0.287129   0.207921   0.217822   0.217822  0.39604    0.306931   0.257426   0.1485
   4 │ 0.354167   0.419355   0.158416   1.0        0.184615   0.25       0.275362   0.1875    0.0757576  0.315789   0.333333   0.189655   0.142857   0.0925926  0.225     0.283333   0.275862   0.291667   0.5161
   5 │ 0.292308   0.246154   0.415842   0.184615   1.0        0.2        0.42029    0.3125    0.363636   0.2        0.184615   0.4        0.276923   0.369231   0.307692  0.492308   0.338462   0.215385   0.2153 ⋯
   6 │ 0.145833   0.21875    0.168317   0.25       0.2        1.0        0.26087    0.2625    0.318182   0.0789474  0.238095   0.155172   0.183673   0.12963    0.15      0.2        0.275862   0.229167   0.2812
   7 │ 0.362319   0.188406   0.366337   0.275362   0.42029    0.26087    1.0        0.5375    0.42029    0.246377   0.289855   0.42029    0.289855   0.376812   0.26087   0.391304   0.478261   0.289855   0.2608
   8 │ 0.2375     0.1625     0.425743   0.1875     0.3125     0.2625     0.5375     1.0       0.475      0.1625     0.275      0.325      0.2625     0.275      0.2625    0.3375     0.4375     0.2875     0.2125
   9 │ 0.151515   0.106061   0.386139   0.0757576  0.363636   0.318182   0.42029    0.475     1.0        0.0909091  0.166667   0.363636   0.287879   0.348485   0.19697   0.287879   0.409091   0.348485   0.0909 ⋯
  10 │ 0.3125     0.342105   0.178218   0.315789   0.2        0.0789474  0.246377   0.1625    0.0909091  1.0        0.452381   0.275862   0.102041   0.240741   0.225     0.15       0.258621   0.104167   0.2631
  11 │ 0.4375     0.333333   0.207921   0.333333   0.184615   0.238095   0.289855   0.275     0.166667   0.452381   1.0        0.344828   0.204082   0.277778   0.261905  0.25       0.362069   0.291667   0.3095
  12 │ 0.37931    0.258621   0.287129   0.189655   0.4        0.155172   0.42029    0.325     0.363636   0.275862   0.344828   1.0        0.293103   0.396552   0.275862  0.316667   0.37931    0.224138   0.1551
  13 │ 0.285714   0.142857   0.207921   0.142857   0.276923   0.183673   0.289855   0.2625    0.287879   0.102041   0.204082   0.293103   1.0        0.388889   0.22449   0.316667   0.310345   0.306122   0.1428 ⋯
  14 │ 0.259259   0.166667   0.217822   0.0925926  0.369231   0.12963    0.376812   0.275     0.348485   0.240741   0.277778   0.396552   0.388889   1.0        0.259259  0.366667   0.327586   0.277778   0.1296
  15 │ 0.3125     0.275      0.217822   0.225      0.307692   0.15       0.26087    0.2625    0.19697    0.225      0.261905   0.275862   0.22449    0.259259   1.0       0.333333   0.310345   0.3125     0.25
  16 │ 0.316667   0.283333   0.39604    0.283333   0.492308   0.2        0.391304   0.3375    0.287879   0.15       0.25       0.316667   0.316667   0.366667   0.333333  1.0        0.45       0.366667   0.2333
  17 │ 0.344828   0.258621   0.306931   0.275862   0.338462   0.275862   0.478261   0.4375    0.409091   0.258621   0.362069   0.37931    0.310345   0.327586   0.310345  0.45       1.0        0.344828   0.3103 ⋯
  18 │ 0.3125     0.270833   0.257426   0.291667   0.215385   0.229167   0.289855   0.2875    0.348485   0.104167   0.291667   0.224138   0.306122   0.277778   0.3125    0.366667   0.344828   1.0        0.2916
  19 │ 0.270833   0.387097   0.148515   0.516129   0.215385   0.28125    0.26087    0.2125    0.0909091  0.263158   0.309524   0.155172   0.142857   0.12963    0.25      0.233333   0.310345   0.291667   1.0
  ⋮  │     ⋮          ⋮          ⋮          ⋮          ⋮          ⋮          ⋮         ⋮          ⋮          ⋮          ⋮          ⋮          ⋮          ⋮         ⋮          ⋮          ⋮          ⋮          ⋮  ⋱
  84 │ 0.104167   0.111111   0.0792079  0.0322581  0.107692   0.03125    0.0724638  0.025     0.0454545  0.0789474  0.047619   0.0862069  0.0612245  0.148148   0.1       0.116667   0.0689655  0.0625     0.0967
  85 │ 0.208333   0.148148   0.108911   0.290323   0.0923077  0.0        0.0869565  0.0625    0.0454545  0.184211   0.166667   0.12069    0.0612245  0.0740741  0.05      0.1        0.12069    0.208333   0.1612 ⋯
  86 │ 0.145833   0.0740741  0.029703   0.0967742  0.0        0.03125    0.0724638  0.025     0.030303   0.0526316  0.119048   0.0172414  0.0408163  0.0185185  0.05      0.05       0.0689655  0.0833333  0.0967
  87 │ 0.0833333  0.111111   0.029703   0.0967742  0.0        0.0625     0.0434783  0.0625    0.0151515  0.105263   0.047619   0.0689655  0.0408163  0.037037   0.075     0.0        0.0344828  0.0625     0.0967
  88 │ 0.145833   0.0810811  0.178218   0.162162   0.153846   0.135135   0.101449   0.175     0.106061   0.157895   0.214286   0.0689655  0.0612245  0.0555556  0.15      0.2        0.137931   0.125      0.1621
  89 │ 0.104167   0.185185   0.049505   0.16129    0.0923077  0.09375    0.057971   0.0875    0.0454545  0.0526316  0.047619   0.0689655  0.0612245  0.0555556  0.025     0.0833333  0.0689655  0.145833   0.1935 ⋯
  90 │ 0.0833333  0.111111   0.0594059  0.0322581  0.0923077  0.03125    0.057971   0.05      0.0606061  0.0526316  0.0952381  0.0689655  0.0612245  0.0925926  0.075     0.0833333  0.103448   0.0416667  0.0645
  91 │ 0.125      0.037037   0.0990099  0.0967742  0.107692   0.09375    0.101449   0.075     0.0757576  0.0263158  0.047619   0.0862069  0.122449   0.148148   0.025     0.116667   0.0344828  0.0416667  0.0645
  92 │ 0.0833333  0.222222   0.029703   0.193548   0.0615385  0.125      0.101449   0.1       0.0454545  0.157895   0.119048   0.12069    0.102041   0.0740741  0.125     0.116667   0.103448   0.0833333  0.1290
  93 │ 0.354167   0.205128   0.158416   0.333333   0.2        0.153846   0.26087    0.2       0.136364   0.25641    0.333333   0.241379   0.244898   0.240741   0.3       0.333333   0.258621   0.333333   0.2564 ⋯
  94 │ 0.0416667  0.037037   0.0990099  0.0        0.107692   0.0625     0.0434783  0.0375    0.0757576  0.0526316  0.0238095  0.0344828  0.0204082  0.111111   0.0       0.05       0.0344828  0.0416667  0.0322
  95 │ 0.166667   0.147059   0.188119   0.147059   0.215385   0.176471   0.173913   0.175     0.19697    0.105263   0.119048   0.137931   0.142857   0.166667   0.125     0.15       0.172414   0.270833   0.2647
  96 │ 0.166667   0.1        0.128713   0.225      0.2        0.175      0.15942    0.1625    0.19697    0.175      0.190476   0.206897   0.183673   0.185185   0.1       0.183333   0.155172   0.208333   0.15
  97 │ 0.1875     0.139535   0.247525   0.209302   0.230769   0.162791   0.15942    0.1625    0.151515   0.209302   0.255814   0.12069    0.183673   0.203704   0.139535  0.15       0.137931   0.125      0.1395 ⋯
  98 │ 0.1875     0.166667   0.0792079  0.16129    0.0923077  0.03125    0.130435   0.15      0.0757576  0.131579   0.166667   0.137931   0.204082   0.12963    0.175     0.133333   0.258621   0.166667   0.3225
  99 │ 0.268293   0.134146   0.346535   0.109756   0.243902   0.158537   0.426829   0.365854  0.317073   0.182927   0.219512   0.304878   0.268293   0.292683   0.146341  0.231707   0.317073   0.256098   0.1829
 100 │ 0.325581   0.162791   0.356436   0.162791   0.302326   0.116279   0.395349   0.348837  0.267442   0.209302   0.22093    0.27907    0.290698   0.313953   0.197674  0.360465   0.360465   0.232558   0.1627
 101 │ 0.255814   0.162791   0.39604    0.127907   0.313953   0.116279   0.406977   0.383721  0.267442   0.232558   0.255814   0.302326   0.22093    0.27907    0.209302  0.302326   0.313953   0.22093    0.1976 ⋯
 102 │ 0.0208333  0.0        0.019802   0.0        0.0153846  0.0        0.0        0.0       0.0151515  0.0        0.0        0.0        0.0        0.0        0.025     0.0166667  0.0        0.0208333  0.0
         
```
"""
function proximity(M_rca::DataFrames.DataFrame,
    activiy_col_name::String,
    place_col_name::String)::DataFrames.DataFrame

    ## Creamos una copia de la matriz M
    M_mat = M_rca[:,:]

    ## Eliminamos la columna del dataframe
    select!(M_mat, Not(place_col_name))

    ## Guardamos temporalmente los valores de actividades
    activiy_vec_tem = names(M_mat)

    ## Usamos la función pairwise para ejecutar la multiplicación de columnas para 
    ## la colección de columnas del dataframe
    mat_proximity = pairwise((x,y) -> sum(x.*y)./ max(sum(x),sum(y)), eachcol(M_mat))

    ## Creamos el dataframe a partir de la matriz de proximidad
    df_proximity = DataFrame(mat_proximity,activiy_vec_tem)

    return df_proximity

end


"""
    density(Mcp, proximity_mat, activiy_col_name, place_col_name)

La función density calcula las medidas de densidad a partir de las matrices 
    de presencia-ausencia y proximidad. 
...
# Arguments
- `Mcp::DataFrames.DataFrame`: Matriz de presencia-ausencia
- `proximity_mat::DataFrames.DataFrame` : Matriz de proximidad
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`:  Nombre de la columna correspondiente al lugar en el dataframe de datos 
...

# Examples
```julia-repl
julia> density(M_rca, proximity_mat, "hs_product_code", "location_code")
22848×3 DataFrame
   Row │ location_code  hs_product_code  density   
       │ String3        String           Float64   
───────┼───────────────────────────────────────────
     1 │ ABW            01               0.0434101
     2 │ ABW            02               0.0398994
     3 │ ABW            03               0.048414
     4 │ ABW            04               0.0359468
   ⋮   │       ⋮               ⋮             ⋮
 22846 │ ZWE            transport        0.408231
 22847 │ ZWE            travel           0.400228
 22848 │ ZWE            unspecified      0.0989126
                                 22810 rows omitted
```
"""
function density(M_rca::DataFrames.DataFrame,
    proximity_mat::DataFrames.DataFrame,
    activiy_col_name::String,
    place_col_name::String)::DataFrames.DataFrame

    ## Creamos una copia de la matriz M
    M_mat = M_rca[:,:]

    ## Guardamos temporalmente la columna de ubicación
    place_vec_temp = M_mat[:, place_col_name]

    ## Eliminamos la columna del dataframe
    select!(M_mat, Not(place_col_name))

    ## Guardamos temporalmente los valores de actividades
    activiy_vec_tem = names(M_mat)

    ## Calculamos la densidad como multiplicación de matrices
    density_matrix = *(Matrix(M_mat), Matrix(proximity_mat))./vec(sum(Matrix(proximity_mat), dims=2))'

    ## Creamos el dataframe a partir de la matriz de densidad
    df_densidad = DataFrame(density_matrix,activiy_vec_tem)

    ## Agregamos nuevamente la columna de lugar
    insertcols!(df_densidad, 1,  place_col_name => place_vec_temp)

    ## Hacemos un reshape(stack) sobre el dataframe df_densidad para convertirlo de wide a long
    df_densidad_long = stack(df_densidad, activiy_vec_tem)

    ## Renombramos el dataframe
    rename_dict = Dict("variable" => activiy_col_name, "value" => "density")
    rename!(df_densidad_long, rename_dict)

    ## Ordenamos el dataframe de acuerdo a place_col_name y activiy_col_name
    sort!(df_densidad_long, [place_col_name, activiy_col_name])

    return df_densidad_long

end


"""
    distance(Mcp, proximity_mat, activiy_col_name, place_col_name)

La función distance calcula las medidas de distancia a partir de las matrices 
    de presencia-ausencia y proximidad. 
...
# Arguments
- `Mcp::DataFrames.DataFrame`: Matriz de presencia-ausencia
- `proximity_mat::DataFrames.DataFrame` : Matriz de proximidad
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`:  Nombre de la columna correspondiente al lugar en el dataframe de datos 
...

# Examples
```julia-repl
julia> distance(Mcp, proximity_mat, "hs_product_code", "location_code")
22848×3 DataFrame
   Row │ location_code  hs_product_code  distance 
       │ String3        String           Float64  
───────┼──────────────────────────────────────────
     1 │ ABW            01               0.95659
     2 │ ABW            02               0.960101
     3 │ ABW            03               0.951586
     4 │ ABW            04               0.964053
   ⋮   │       ⋮               ⋮            ⋮
 22847 │ ZWE            travel           0.599772
 22848 │ ZWE            unspecified      0.901087
                                22810 rows omitted
```
"""
function distance(M_rca::DataFrames.DataFrame,
    proximity_mat::DataFrames.DataFrame,
    activiy_col_name::String,
    place_col_name::String)::DataFrames.DataFrame

    ## Creamos una copia de la matriz M
    M_mat = M_rca[:,:]

    ## Guardamos temporalmente la columna de ubicación
    place_vec_temp = M_mat[:, place_col_name]

    ## Eliminamos la columna del dataframe
    select!(M_mat, Not(place_col_name))

    ## Guardamos temporalmente los valores de actividades
    activiy_vec_tem = names(M_mat)

    ## Calculamos la densidad como multiplicación de matrices
    distance_matrix = *(1 .- Matrix(M_mat), Matrix(proximity_mat))./vec(sum(Matrix(proximity_mat), dims=2))'

    ## Creamos el dataframe a partir de la matriz de densidad
    df_distance = DataFrame(distance_matrix,activiy_vec_tem)

    ## Agregamos nuevamente la columna de lugar
    insertcols!(df_distance, 1,  place_col_name => place_vec_temp)

    ## Hacemos un reshape(stack) sobre el dataframe df_distance para convertirlo de wide a long
    df_distance_long = stack(df_distance, activiy_vec_tem)

    ## Renombramos el dataframe
    rename_dict = Dict("variable" => activiy_col_name, "value" => "distance")
    rename!(df_distance_long, rename_dict)

    ## Ordenamos el dataframe de acuerdo a place_col_name y activiy_col_name
    sort!(df_distance_long, [place_col_name, activiy_col_name])

    return df_distance_long

end


"""
    calc_coi_cog(Mcp, proximity_mat, activiy_col_name, place_col_name)

La función calc_coi_cog calcula las medidas de COI (Complexity Outlook Index) y COG (Complexity Opportunity Gain)
a partir de las matrices de presencia-ausencia y proximidad. 
...
# Arguments
- `Mcp::DataFrames.DataFrame`: Matriz de presencia-ausencia
- `proximity_mat::DataFrames.DataFrame` : Matriz de proximidad
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`:  Nombre de la columna correspondiente al lugar en el dataframe de datos 
...

# Examples
```julia-repl
julia> calc_coi_cog(M_rca, proximity_mat, "hs_product_code", "location_code")
23664×4 DataFrame
   Row │ location_code  hs_product_code  coi        cog         
       │ String3        String           Float64    Float64     
───────┼────────────────────────────────────────────────────────
     1 │ ABW            01               0.0207321   0.0131482
     2 │ ABW            02               0.0207321   0.0312618
   ⋮   │       ⋮               ⋮             ⋮           ⋮
 23663 │ ZWE            travel           0.487938    0.0113775
 23664 │ ZWE            unspecified      0.487938   -0.0767666
                                 22810 rows omitted
```
"""
function calc_coi_cog(M_rca::DataFrames.DataFrame,
    proximity_mat::DataFrames.DataFrame,
    activiy_col_name::String,
    place_col_name::String)::DataFrames.DataFrame


    ## Creamos una copia de la matriz M
    M_mat = M_rca[:,:]

    ## Guardamos temporalmente la columna de ubicación
    place_vec_temp = M_mat[:, place_col_name]

    ## Eliminamos la columna del dataframe
    select!(M_mat, Not(place_col_name))

    ## Guardamos temporalmente los valores de actividades
    activiy_vec_tem = names(M_mat)

    ## Calculamos la matriz de densidad
    density_df = density(M_rca, proximity_mat, activiy_col_name, place_col_name)

    ## Hacemos un reshape(unstack) sobre el dataframe de la densidad para obtener un dataframe (ubicación, actividad)
    density_df = unstack(density_df, place_col_name, activiy_col_name, "density")

    ## Eliminamos la columna de ubicación
    select!(density_df, Not(place_col_name))

    ## Convertimos el dataframe density_df a matriz
    density_mat = Matrix(density_df)

    ######################################
    ## Obtenemos el pci

    ## Calculamos los vectores de ubiquity y diversity
    diversity_vec = vec(sum(Matrix(M_mat), dims=2))
    ubiquity_vec = vec(sum(Matrix(M_mat), dims=1))
    
    ## Calculamos la matriz Mcc
    Mcc = inv(Diagonal(diversity_vec))*Matrix(M_mat)*inv(Diagonal(ubiquity_vec))*Matrix(M_mat)'

    ## Obtenemos el eigenvector de la matriz Mcc asociado al segundo eigenvector más grande
    kc = real.(eigvecs(Mcc)[:,sortperm(real.(eigvals(Mcc)))[end-1] ])

    ## Calculamos el eigenvector de la matriz Mpp asociado al segundo eigenvector más grande
    kp = pinv(Matrix(M_mat))*Diagonal(diversity_vec)*kc

    ## Adjust sign of ECI and PCI so it makes sense, as per book
    s1 = sign(cor(diversity_vec,kc))

    ## Calculamos ECI y PCI
    eci = s1 .* (kc .- mean(kc))./std(kc)
    #pci = s1 .* (kp .- mean(kp))./std(kp)
    pci = s1 .* (kp .- mean(eci))./std(eci)

    # Normalize variables as per STATA package
    # Normalization using ECI mean and std. dev. preserves the property that 
    # ECI = (mean of PCI of products for which MCP=1)

    #pci = (pci .- mean(eci)) ./ std(eci)
    #eci = (eci .- mean(eci)) ./ std(eci)

    ######################################
    ## Calculamos COI (Complexity Outlook Index)
    coi = (density_mat .* (1 .- Matrix(M_mat)) ) * pci

    ## Calculamos COG (Complexity Opportunity Gain)
    #cog = (1 .- Matrix(M_mat)).*((1 .- Matrix(M_mat)) *vec(Matrix(proximity_mat) * (pci ./ sum(Matrix(proximity_mat), dims=2))))
    cog =  (((1 .- Matrix(M_mat)) .* pci') ./vec(sum(Matrix(proximity_mat), dims=2))') * Matrix(proximity_mat)

    ## Creamos el dataframe de COI
    df_eci = DataFrame(place_col_name => place_vec_temp, "coi" => coi)

    ## Creamos el dataframe de COG
    df_cog = DataFrame(activiy_col_name => activiy_vec_tem)
    
    ## Reune dataframes
    df_coi_cog = crossjoin(df_eci, df_cog)[:, [place_col_name, activiy_col_name, "coi"]]

    ## Agrega COG
    df_coi_cog[:, "cog"] = vcat(cog'...)

    ## Ordenamos el dataframe de acuerdo a place_col_name y activiy_col_name
    sort!(df_coi_cog, [place_col_name, activiy_col_name])

    return df_coi_cog
    
end


"""
    calc_eci_pci(Mcp, activiy_col_name, place_col_name)

La función calc_eci_pci calcula las medidas de ECI (Economic Complexity Index) y  PCI (Product Complexity Index)
a partir de la matriz de presencia-ausencia. 
...
# Arguments
- `Mcp::DataFrames.DataFrame`: Matriz de presencia-ausencia
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`:  Nombre de la columna correspondiente al lugar en el dataframe de datos 
...

# Examples
```julia-repl
julia> calc_eci_pci(M_rca, "hs_product_code", "location_code")
23664×4 DataFrame
   Row │ location_code  hs_product_code  eci        pci          
       │ String3        String           Float64    Float64      
───────┼─────────────────────────────────────────────────────────
     1 │ ABW            01               -0.775062  -0.0294049
     2 │ ABW            02               -0.775062  -0.00750686
     3 │ ABW            03               -0.775062  -0.0842069
     4 │ ABW            04               -0.775062   0.0270437
     5 │ ABW            05               -0.775062  -0.0655918
   ⋮   │       ⋮               ⋮             ⋮           ⋮
 23663 │ ZWE            travel           -0.425068  -0.0904706
 23664 │ ZWE            unspecified      -0.425068  -0.278911
                                               23626 rows omitted
```
"""
function calc_eci_pci(M_rca::DataFrames.DataFrame,
    activiy_col_name::String,
    place_col_name::String)::DataFrames.DataFrame


    ## Creamos una copia de la matriz M
    M_mat = M_rca[:,:]

    ## Guardamos temporalmente la columna de ubicación
    place_vec_temp = M_mat[:, place_col_name]

    ## Eliminamos la columna del dataframe
    select!(M_mat, Not(place_col_name))

    ## Guardamos temporalmente los valores de actividades
    activiy_vec_tem = names(M_mat)

    ## Calculamos los vectores de ubiquity y diversity
    diversity_vec = vec(sum(Matrix(M_mat), dims=2))
    ubiquity_vec = vec(sum(Matrix(M_mat), dims=1))
    
    ## Calculamos la matriz Mcc
    Mcc = inv(Diagonal(diversity_vec))*Matrix(M_mat)*inv(Diagonal(ubiquity_vec))*Matrix(M_mat)'
    Mcc_py = (Matrix(M_mat) ./ diversity_vec) * (Matrix(M_mat) ./ ubiquity_vec')'

    ## Calculamos la matriz Mcc
    Mpp = inv(Diagonal(ubiquity_vec))*Matrix(M_mat)'*inv(Diagonal(diversity_vec))*Matrix(M_mat)
    Mpp_py = (Matrix(M_mat) ./ ubiquity_vec')' * (Matrix(M_mat) ./ diversity_vec) 

    ## Obtenemos el eigenvector de la matriz Mcc asociado al segundo eigenvector más grande
    kc = real.(eigvecs(Mcc)[:,sortperm(real.(eigvals(Mcc)))[end-1] ])

    ## Calculamos el eigenvector de la matriz Mpp asociado al segundo eigenvector más grande
    kp = pinv(Matrix(M_mat))*Diagonal(diversity_vec)*kc
    #kp_py = real.(eigvecs(Mpp_py)[:,sortperm(real.(eigvals(Mpp_py)))[end-1] ])

    ## Adjust sign of ECI and PCI so it makes sense, as per book
    s1 = sign(cor(diversity_vec,kc))

    ## Calculamos ECI y PCI
    eci = s1 .* (kc .- mean(kc))./std(kc)
    #pci = s1 .* (kp .- mean(kp))./std(kp)
    pci = s1 .* (kp .- mean(eci))./std(eci)
    #pci_py = s1 .* (kp_py .- mean(kp_py))./std(kp_py)

    # Normalize variables as per STATA package
    # Normalization using ECI mean and std. dev. preserves the property that 
    # ECI = (mean of PCI of products for which MCP=1)

    pci = (pci .- mean(eci)) ./ std(eci)
    eci = (eci .- mean(eci)) ./ std(eci)

    ## Creamos el dataframe de ECI
    df_eci = DataFrame(place_col_name => place_vec_temp, "eci" => eci)

    ## Creamos el dataframe de PCI
    df_pci = DataFrame(activiy_col_name => activiy_vec_tem, "pci" => pci)
    
    ## Reune dataframes
    df_eci_pci = crossjoin(df_eci, df_pci)[:, [place_col_name, activiy_col_name, "eci", "pci"]]

    ## Ordenamos el dataframe de acuerdo a place_col_name y activiy_col_name
    sort!(df_eci_pci, [place_col_name, activiy_col_name])

    return df_eci_pci
    
end

"""
    complexity_metrics(complex_data, value_col_name, activiy_col_name, place_col_name, rca_threshold)

La función complexity_metrics calcula las métrica de complejidad:
    * diversity
    * ubiquity
    * rca: Balassa's RCA
    * mcp: Matriz de presencia-ausencia
    * eci: Economic complexity index
    * pci: Product complexity index
    * density: Density of the network around each product
    * distance: Distance of the network around each product
    * coi: Complexity Outlook Index
    * cog: Complexity Outlook Gain
...
# Arguments
- `complex_data::DataFrames.DataFrame`: Dataframe de los datos para realizar los cálculos
- `value_col_name::String`: Nombre de la columna numérica en el dataframe de datos 
- `activiy_col_name::String`: Nombre de la columna correspondiente a la actividad en el dataframe de datos 
- `place_col_name::String`: Nombre de la columna correspondiente al lugar en el dataframe de datos 
- `rca_threshold::Float32=1.0`  : Valor de umbral de RCA utilizado para etiquetar como 1 y 0 los valores de la matriz de presencia-ausencia.
...

# Examples
```julia-repl
julia> complexity_metrics(complex_data, "export_value", "hs_product_code", "location_code")
23414×14 DataFrame
   Row │ year   location_code  hs_product_code  export_value    rca          mcp   diversity  ubiquity  density    distance  eci        pci           coi        cog         
       │ Int64  String3        String15         Float64         Float64?     Int8  Int64?     Int64?    Float64?   Float64?  Float64?   Float64?      Float64?   Float64?    
───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
     1 │  2010  ABW            01                 2513.0        0.00135394      0          5        49  0.0697614  0.930239  -0.775062  -0.0294049    0.0207321   0.0131482
     2 │  2010  ABW            02                    0.0        0.0             0          5        34  0.0513502  0.94865   -0.775062  -0.00750686   0.0207321   0.0312618
     3 │  2010  ABW            03                    0.0        0.0             0          5        95  0.0805845  0.919416  -0.775062  -0.0842069    0.0207321  -0.00510557
     4 │  2010  ABW            04               341889.0        0.0497294       0          5        51  0.0630155  0.936985  -0.775062   0.0270437    0.0207321   0.0305285
     5 │  2010  ABW            05                 5700.0        0.00773444      0          5        48  0.0577453  0.942255  -0.775062  -0.0655918    0.0207321   0.00932437
     6 │  2010  ABW            06                 1539.0        0.000863378     0          5        29  0.0527778  0.947222  -0.775062  -0.00948958   0.0207321   0.0237161
     7 │  2010  ABW            07                80122.0        0.014219        0          5        68  0.0763443  0.923656  -0.775062  -0.0467832    0.0207321   0.00411452
     8 │  2010  ABW            08                28693.0        0.00350939      0          5        84  0.0830361  0.916964  -0.775062  -0.06119      0.0207321  -0.00290524
     9 │  2010  ABW            09                26115.0        0.00712855      0          5        58  0.0763489  0.923651  -0.775062  -0.0957408    0.0207321  -0.00945741
   ⋮   │   ⋮          ⋮               ⋮               ⋮              ⋮        ⋮        ⋮         ⋮          ⋮         ⋮          ⋮           ⋮            ⋮           ⋮
 23413 │  2010  ZWE            travel                1.23545e8  1.18725         1         23       112  0.354682   0.645318  -0.425068  -0.0904706    0.487938    0.0113775
 23414 │  2010  ZWE            unspecified           0.0        0.0             0         23         4  0.128651   0.871349  -0.425068  -0.278911     0.487938   -0.0767666
                                                                                                                                                           23376 rows omitted
```
"""
function complexity_metrics(complex_data::DataFrames.DataFrame,
    value_col_name::String, 
    activiy_col_name::String,
    place_col_name::String,
    rca_threshold = 1.0)::DataFrames.DataFrame

    ### Calculamos RCA
    df_rca = RCA(complex_data, value_col_name, activiy_col_name, place_col_name)
    
    ### Calculamos matriz M
    M_rca = build_Mcp(df_rca, activiy_col_name, place_col_name, rca_threshold)

    ### Calculamos proximidad
    proximity_mat = proximity(M_rca, activiy_col_name, place_col_name)

    ### Calculamos densidad
    df_densidad = density(M_rca, proximity_mat, activiy_col_name, place_col_name)

    ### Calculamos distancia
    df_distancia = distance(M_rca, proximity_mat, activiy_col_name, place_col_name)

    ### Calculamos ECI y PCI
    df_eci_pci = calc_eci_pci(M_rca, activiy_col_name, place_col_name)

    ### Calculamos COI y COI
    df_coi_cog = calc_coi_cog(M_rca, proximity_mat, activiy_col_name, place_col_name)

    ### Reunimos los dataframes
    ec_measures = leftjoin(complex_data, df_rca; on=[activiy_col_name, place_col_name])

    ### Agregamos la matriz M
    ec_measures.mcp = Int8.(ec_measures.rca .>= rca_threshold)

    ### Agregamos diversity y ubiquity
    diversity_m = metrics_diversity_ubiquity(M_rca, activiy_col_name, place_col_name, "diversity")
    ubiquity_m = metrics_diversity_ubiquity(M_rca, activiy_col_name, place_col_name, "ubiquity")

    leftjoin!(ec_measures, diversity_m; on = place_col_name)
    leftjoin!(ec_measures, ubiquity_m; on = activiy_col_name)
    
    ### Agregamos densidad 
    leftjoin!(ec_measures, df_densidad; on=[activiy_col_name, place_col_name])

    ### Agregamos distancia
    leftjoin!(ec_measures, df_distancia; on=[activiy_col_name, place_col_name])

    ### Agregamos ECI y PCI
    leftjoin!(ec_measures, df_eci_pci; on=[activiy_col_name, place_col_name])

    ### Agregamos COI y COG
    leftjoin!(ec_measures, df_coi_cog; on=[activiy_col_name, place_col_name])



    return ec_measures
end
