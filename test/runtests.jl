module RunTests

println(" ")
println("###############")
println("### Testing ###")
println("###############")

println(" ")
println("########################")
println("### Constraint Tests ###")
println("########################")
println(" ")

include("constraint_tests.jl")

println(" ")
println("########################")
println("### Domination Tests ###")
println("########################")
println(" ")

include("dominant_set_tests.jl")

println(" ")
println("#######################")
println("### Automaton Tests ###")
println("#######################")
println(" ")

include("automaton_tests.jl")

println(" ")
println("######################")
println("### Sequence Tests ###")
println("######################")
println(" ")

include("sequence_tests.jl")

end # module
