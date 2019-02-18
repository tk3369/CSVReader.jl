using Test
using CSVReader
using DataFrames

const iris = "iris.csv"

function testresult(df)
    @test size(df) == (150, 6)
    @test names(df) == Symbol.(["id", "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species"])
    @test unique(df[:Species]) == ["setosa", "versicolor", "virginica"]
    @test [sum(df[i]) for i in 2:5] ≈ [876.5, 458.6, 563.7, 179.9]
end

@testset "CSVReader" begin

    # basic usage
    df = CSVReader.read_csv("iris.csv") 
	testresult(df)

    # specified parsers
    df = CSVReader.read_csv("iris.csv", parsers"i,f:4,s") 
	testresult(df)

    # without headers
	df = CSVReader.read_csv("iris2.csv"; headers = false) 
	names!(df, Symbol.(["id", "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species"]))
	testresult(df)
end
