# CSVReader

This is a very simple CSV reader that performs well for small/medium files.

Requires Julia 0.7/1.0.

## Installation

`] add https://github.com/tk3369/CSVReader.jl.git`

## Usage

```
julia> using CSVReader

shell> ls -l random_1000_1000.csv
-rw-r--r--  1 tomkwong  staff  19277409 Sep 15 09:42 random_1000_1000.csv

julia> @time CSVReader.read_csv("random_1000_1000.csv")
  1.391223 seconds (13.08 M allocations: 400.460 MiB, 18.24% gc time)
1000×1000 DataFrames.DataFrame. Omitted printing of 992 columns
│ Row  │ col1      │ col2      │ col3       │ col4      │ col5      │ col6      │ col7      │ col8      │
├──────┼───────────┼───────────┼────────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ 1    │ 0.486268  │ 0.591606  │ 0.364998   │ 0.122396  │ 0.790917  │ 0.974412  │ 0.58474   │ 0.800239  │
│ 2    │ 0.0198956 │ 0.861966  │ 0.18969    │ 0.921755  │ 0.595067  │ 0.027107  │ 0.854532  │ 0.821099  │
│ 3    │ 0.639843  │ 0.708882  │ 0.413558   │ 0.418951  │ 0.211808  │ 0.420397  │ 0.22368   │ 0.914673  │
│ 4    │ 0.494207  │ 0.0376842 │ 0.241157   │ 0.295637  │ 0.578396  │ 0.0690918 │ 0.225611  │ 0.906515  │
│ 5    │ 0.934932  │ 0.661001  │ 0.72414    │ 0.313701  │ 0.435173  │ 0.33001   │ 0.147221  │ 0.766403  │
│ 6    │ 0.204951  │ 0.71877   │ 0.793592   │ 0.204328  │ 0.664758  │ 0.0712346 │ 0.0694587 │ 0.118031  │
│ 7    │ 0.0934762 │ 0.267415  │ 0.415946   │ 0.50727   │ 0.420693  │ 0.399949  │ 0.142181  │ 0.442778  │
│ 8    │ 0.769402  │ 0.0785393 │ 0.998296   │ 0.436621  │ 0.0696104 │ 0.197658  │ 0.0878371 │ 0.644112  │
│ 9    │ 0.631217  │ 0.729514  │ 0.261147   │ 0.0290814 │ 0.78109   │ 0.509806  │ 0.622911  │ 0.166229  │
⋮
│ 991  │ 0.966723  │ 0.950735  │ 0.049578   │ 0.455498  │ 0.315763  │ 0.257209  │ 0.505465  │ 0.32344   │
│ 992  │ 0.91233   │ 0.980845  │ 0.951227   │ 0.702606  │ 0.349252  │ 0.0390388 │ 0.273172  │ 0.0339004 │
│ 993  │ 0.297311  │ 0.91343   │ 0.620121   │ 0.0513046 │ 0.24487   │ 0.988954  │ 0.921226  │ 0.93475   │
│ 994  │ 0.296768  │ 0.599559  │ 0.953788   │ 0.0432677 │ 0.234695  │ 0.840569  │ 0.962538  │ 0.570043  │
│ 995  │ 0.135429  │ 0.327027  │ 0.269419   │ 0.48755   │ 0.493117  │ 0.195611  │ 0.562147  │ 0.595037  │
│ 996  │ 0.51293   │ 0.761905  │ 0.252105   │ 0.83032   │ 0.449275  │ 0.821679  │ 0.57158   │ 0.189035  │
│ 997  │ 0.0610196 │ 0.451258  │ 0.822658   │ 0.995139  │ 0.376177  │ 0.446336  │ 0.625978  │ 0.345604  │
│ 998  │ 0.807506  │ 0.662694  │ 0.748511   │ 0.386424  │ 0.382528  │ 0.967563  │ 0.289772  │ 0.68869   │
│ 999  │ 0.766858  │ 0.188568  │ 0.00351197 │ 0.574412  │ 0.273609  │ 0.342067  │ 0.551695  │ 0.862752  │
│ 1000 │ 0.0415403 │ 0.803243  │ 0.760925   │ 0.833656  │ 0.327847  │ 0.811386  │ 0.484366  │ 0.632995  │
```

By default, the reader tries to infer column types by looking at the first row.  Of course, that's not
very accurate if you have any missing data or mixed number/string columns.  For now, it may be easier 
to just specify the column parsers.

There are few predefined parsers, represented as "f", "s", or "i".  
You can use the `parsers` literal string to create an array of parsers.
Optionally, the parser spec takes a number for each parser as in `parsers"f:10"`.
```
julia> parsers"f,s,i,f:2"
5-element Array{Any,1}:
 CSVReader.parse_float64
 CSVReader.parse_string 
 CSVReader.parse_int    
 CSVReader.parse_float64
 CSVReader.parse_float64    
```

How do you use it?
```
julia> df = CSVReader.read_csv("FL_insurance_sample.csv", parsers"i,s:2,f:11,s:2,i");

julia> describe(df)
18×8 DataFrame
│ Row │ variable           │ mean      │ min            │ median    │ max               │ nunique │ nmissing │ eltype  │
├─────┼────────────────────┼───────────┼────────────────┼───────────┼───────────────────┼─────────┼──────────┼─────────┤
│ 1   │ policyID           │ 5.48662e5 │ 100074         │ 548525.0  │ 999971            │         │ 0        │ Int64   │
│ 2   │ statecode          │           │ FL             │           │ FL                │ 1       │ 0        │ String  │
│ 3   │ county             │           │ ALACHUA COUNTY │           │ WASHINGTON COUNTY │ 67      │ 0        │ String  │
│ 4   │ eq_site_limit      │ 731478.0  │ 0.0            │ 0.0       │ 2.16e9            │         │ 0        │ Float64 │
│ 5   │ hu_site_limit      │ 2.07435e6 │ 0.0            │ 1.92691e5 │ 2.16e9            │         │ 0        │ Float64 │
│ 6   │ fl_site_limit      │ 6.64601e5 │ 0.0            │ 0.0       │ 2.16e9            │         │ 0        │ Float64 │
│ 7   │ fr_site_limit      │ 9.91172e5 │ 0.0            │ 0.0       │ 2.16e9            │         │ 0        │ Float64 │
│ 8   │ tiv_2011           │ 2.17288e6 │ 90.0           │ 2.02105e5 │ 2.16e9            │         │ 0        │ Float64 │
│ 9   │ tiv_2012           │ 2.571e6   │ 73.37          │ 241631.0  │ 1.701e9           │         │ 0        │ Float64 │
│ 10  │ eq_site_deductible │ 778.791   │ 0.0            │ 0.0       │ 6.27377e6         │         │ 0        │ Float64 │
│ 11  │ hu_site_deductible │ 7037.98   │ 0.0            │ 0.0       │ 7.38e6            │         │ 0        │ Float64 │
│ 12  │ fl_site_deductible │ 192.453   │ 0.0            │ 0.0       │ 450000.0          │         │ 0        │ Float64 │
│ 13  │ fr_site_deductible │ 26.4836   │ 0.0            │ 0.0       │ 900000.0          │         │ 0        │ Float64 │
│ 14  │ point_latitude     │ 28.0875   │ 24.5475        │ 28.0571   │ 30.9898           │         │ 0        │ Float64 │
│ 15  │ point_longitude    │ -81.9036  │ -87.4473       │ -81.5857  │ -80.0333          │         │ 0        │ Float64 │
│ 16  │ line               │           │ Commercial     │           │ Residential       │ 2       │ 0        │ String  │
│ 17  │ construction       │           │ Masonry        │           │ Wood              │ 5       │ 0        │ String  │
│ 18  │ point_granularity  │ 1.64091   │ 1              │ 1.0       │ 7                 │         │ 0        │ Int64   │
```

## To-Do

- [ ] Handle quoted numeric cells that contains comma separator

- [ ] Infer column types by reading more rows 

- [ ] Add unit tests
