module AutomatonTests

using Test
using WeaklyHard
using WeaklyHard: nbits, shift, shift_rowhit, _childexists, consword

##########################
#### Common Variables ####
##########################

k_max           = 20
n_constraints   = 6
n_tests         = 1_000
types           = [Int8, Int16, Int32, Int64, BigInt]

#####################
#### Shift tests ####
#####################

function test_shift_correctness(w::T, c) where {T <: Integer}
    newWord = (w << 1) | T(c)
    if c == M
        return newWord == shift(w, c)
    else
        return newWord - T(2^(nbits(newWord)-1)) == shift(w, c)
    end # if
end # function

function test_shift_rowhit_correctness(w::T, c, n::T) where {T <: Integer}
    newWord = (w << 1) | T(c)
    if c == M
        return newWord == shift_rowhit(w, c, n)
    else
        return ((newWord & n == n) ? n : newWord) == shift_rowhit(w, c, n)
    end # if
end # function

@testset "Shift Tests" begin
    chars = [H, M]
    for T in types
        for _ in 1:n_tests
            @test test_shift_correctness(rand(T(1):T(8*sizeof(T)-1)), rand(chars))
        end # for
    end # for
end # testset

@testset "Shift_RowHit Tests" begin
    chars = [H, M]
    for T in types
        n = consword( rand( T(1) : max( T(sizeof(T) - 1), T(1) ) ) )
        for _ in 1:n_tests
            @test test_shift_rowhit_correctness(rand(T(1):T(8*sizeof(T)-1)), rand(chars), n)
        end # for
    end # for
end # testset

####################
### Vertex tests ###
####################

function test_vertex_correctness(Lambda::Set{T}) where {T <: Constraint}
    if length(Lambda) == 1
        L = pop!(Lambda)
    else
        L = dominant_set(Lambda)
    end
    automaton = build_automaton(L)

    seq = random_sequence(automaton, 5000)
    c = is_satisfied(L, seq)
    if !c
        return false
    end

    for n in vertices(automaton)
        if (!is_satisfied(L, Int64(n.w)) 
                || (_childexists(n, :miss) && !is_satisfied(L, Int64(n.miss.w))) 
                || !is_satisfied(L, Int64(n.hit.w)))
            return false
        end
    end

    true
end # function

@testset "Vertices Tests" begin
    constraint_names = ["RowMissConstraint", "RowHitConstraint", "AnyMissConstraint", "AnyHitConstraint"]

    tested = Set{Set{Constraint}}()
    for _ in 1:n_tests

        Lambda = Set{Constraint}()
        nbr_c  = rand(1:n_constraints)
        for _ in 1:nbr_c
            k = rand(1:k_max)
            x = rand(1:max(k-1, 1))
            lambda_type = rand(constraint_names)
            if lambda_type == "RowHitConstraint"
                x = x #floor(Int, x/2)
            end
            push!(Lambda, getfield(WeaklyHard, Symbol(lambda_type))(x, k))
        end # for

        L = dominant_set(Lambda)

        if !(L in tested)
            push!(tested, L)

            c = test_vertex_correctness(Lambda)
            @test c
            if !c

                @show "###############"
                @show "Lambda:"
                for l in Lambda
                    @show l
                end
                @show "---------------"
                @show "Lambda_star:"
                Lambda_star = dominant_set(Lambda)
                for l in Lambda_star
                    @show l
                end
                @show "###############"

                return
            end
        end
    end # for

    println(" ")
    println("Executed tests on $(length(tested)) different automata")
end # testset

############################
##### Transitions tests ####
############################

function test_transition_correctness(Lambda::Set{T}) where {T <: Constraint}

    if length(Lambda) == 1
        L = pop!(Lambda)
    else
        L = Lambda
    end

    automaton = build_automaton(L)
    trans     = transitions(automaton)

    for v in vertices(automaton)
        v1 = v.hit
        if !((v.w, v1.w, H) in trans)
            return false
        end

        if _childexists(v, :miss)
            v2 = v.miss
            if !((v.w, v2.w, M) in trans)
                return false
            end
        end
    end # for
    
    return true
end # function

@testset "Transitions Tests" begin
    constraint_names = ["RowMissConstraint", "RowHitConstraint", "AnyMissConstraint", "AnyHitConstraint"]

    tested = Set{Set{Constraint}}()
    for _ in 1:n_tests

        Lambda = Set{Constraint}()
        nbr_c  = rand(1:n_constraints)
        for _ in 1:nbr_c
            k = rand(1:k_max)
            x = rand(1:max(k-1, 1))
            lambda_type = rand(constraint_names)
            if lambda_type == "RowHitConstraint"
                x = x #floor(Int, x/2)
            end
            push!(Lambda, getfield(WeaklyHard, Symbol(lambda_type))(x, k))
        end # for

        L = dominant_set(Lambda)

        if !(L in tested)
            push!(tested, L)

            c = test_transition_correctness(Lambda)
            @test c
            if !c

                @show "###############"
                @show "Lambda:"
                @show Lambda
                @show "---------------"
                @show "Lambda_star:"
                Lambda_star = dominant_set(Lambda)
                @show Lambda_star
                @show "###############"

                return
            end
        end
    end # for

    println(" ")
    println("Executed tests on $(length(tested)) different automata")
end # testset

############################
##### Automata tests #######
############################

@testset "Set-construction Tests" begin
    constraint_names = ["RowMissConstraint", "RowHitConstraint", "AnyMissConstraint", "AnyHitConstraint"]
    n_constraints    = 3
    k_max            = 15
    n_tests          = 1_000

    for _ in 1:n_tests
        Lambda = Set{Constraint}()
        n = rand(1:n_constraints)
        for _ in 1:n
            k = rand(1:k_max)
            x = rand(0:k)
            lambda_type = rand(constraint_names)
            if lambda_type == "RowHitConstraint"
                x = floor(Int, x/2)
            end
            push!(Lambda, getfield(WeaklyHard, Symbol(lambda_type))(x, k))
        end # for

        Lambda_star = dominant_set(Lambda)

        G = build_automaton(Lambda_star)
        minimize_automaton!(G)
        all_seq = all_sequences(G, k_max+1) # +1 to account for RowMissConstraints
        for seq in all_seq
            if !is_satisfied(Lambda_star, seq)
                @show Lambda
                @show Lambda_star
                @show seq
                @show bitstring(seq)
            end
            @test is_satisfied(Lambda_star, seq)
        end # for
    end # for
end # testset


function equivalence_test_min(g_min::Automaton, g::Automaton)
    ks_min = keys(g_min.data)
    ks     = keys(g.data)
    for k_min in ks_min
        if !(k_min in ks)
            return false # if the vertex doesn't exist in both automata
        elseif WeaklyHard._childexists(g.data[k_min], :miss)
            if g_min.data[k_min].miss.w != g.data[k_min].miss.w || g_min.data[k_min].hit.w != g.data[k_min].hit.w
                return false # if the vertices children differ in the different automata
            end # if
        else
            if g_min.data[k_min].hit.w != g.data[k_min].hit.w
                return false # if the vertices children differ in the different automata
            end # if
        end # if
    end # for
    return true
end # function
@testset "Minimizing single-constraint automata" begin
    constraint_names = ["RowMissConstraint", "RowHitConstraint", "AnyMissConstraint", "AnyHitConstraint"]
    k_max            = 15
    n_tests          = 1_000

    for _ in 1:n_tests
        k = rand(1:k_max)
        x = rand(0:k)
        lambda_type = rand(constraint_names)
        if lambda_type == "RowHitConstraint"
            x = floor(Int, x/2)
        end
        l = getfield(WeaklyHard, Symbol(lambda_type))(x, k)

        g_min = build_automaton(l)
        g     = build_automaton(l)
        minimize_automaton!(g_min)

        @test equivalence_test_min(g_min, g)
    end # for
end # testset


end # module
