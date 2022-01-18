module ConstraintTests

using Test
using WeaklyHard

##############################
### Generate all sequences ###
##############################

const k_max = 5
const types = [Int8, Int16, Int32, Int64, BigInt]

generate_all_seq(k::T) where {T <: Integer} = (k <= 8*sizeof(T) - 1) ? [(T(1) << k) | i for i in T(0):T(2^k-1)] : error("Can't create that long sequences of $T")

const seqs = generate_all_seq(Int32(k_max))
@show length(seqs)

generate_all_valid(lambda::T) where {T <: Constraint} = Set{Int32}(filter(x -> is_satisfied(lambda, x), seqs))

################################################
### Aux functions for individual constraints ###
################################################

function trivial_rowhit(x, k)
    lambda = RowHitConstraint(x, k)

    # Parameter tests
    @test lambda.x == x
    @test lambda.k == k
    z = k - 2*x + 1

    # Function tests
    for T in types
        s = 8*sizeof(T)
        if k + 2*x < s
            # Trivial tests
            @test (x==0) ? is_satisfied(lambda, T(0)) : !is_satisfied(lambda, T(0))
            @test (2*x > k) ? !is_satisfied(lambda, consword(T(k)) << 1) : is_satisfied(lambda, consword(T(k)) << 1)
        end # if
    end # for
end # function

function trivial_rowmiss(x, k)
    lambda = RowMissConstraint(x, k)

    # Parameter tests
    @test lambda.x == x
    @test lambda.k == x+1

    # Function tests
    for T in types
        s = 8*sizeof(T)
        if k < s
            # Trivial tests
            if x == 0
                @test !is_satisfied(lambda, T(1) << 1)
            else
                @test is_satisfied(lambda, T(1) << lambda.x)
                @test !is_satisfied(lambda, T(1) << (lambda.x+1))
            end # if
        end # if
    end # for
end # function

function trivial_anymiss(x, k)
    lambda = AnyMissConstraint(x, k)

    # Parameter tests
    @test lambda.x == x
    @test lambda.k == k

    # Function tests
    for T in types
        s = 8*sizeof(T)
        if k < s
            # Trivial tests
            if x == 0
                @test !is_satisfied(lambda, T(1) << 1)
            elseif x == k
                @test is_satisfied(lambda, T(0))
            else
                @test is_satisfied(lambda, consword(T(lambda.k)) << lambda.x)
                @test !is_satisfied(lambda, consword(T(lambda.k)) << (lambda.x+1))
            end # if
        end #if 
    end # for
end # function

function trivial_anyhit(x, k)
    lambda = AnyHitConstraint(x, k)

    # Parameter tests
    @test lambda.x == x
    @test lambda.k == k

    # Function tests
    for T in types
        s = 8*sizeof(T)
        if k < s
            # Trivial tests
            if x == 0
                @test is_satisfied(lambda, T(0))
            elseif x == k
                @test !is_satisfied(lambda, T(1) << 1)
            else
                @test is_satisfied(lambda, consword(T(lambda.k)) << (lambda.k - lambda.x))
                @test !is_satisfied(lambda, consword(T(lambda.k)) << (lambda.k - lambda.x + 1))
            end # if
        end # if
    end # for
end # function

########################################
### Tests for individual constraints ###
########################################

@testset "Trivial Tests - RowHitConstraint" begin
    for k in 1:200
        for x in 0:k
            trivial_rowhit(x, k)
        end # for
    end # for
end # testset 

@testset "Trivial Tests - RowMissConstraint" begin
    for k in 1:200
        for x in 0:k
            trivial_rowmiss(x, k)
        end # for
    end # for
end # testset 

@testset "Trivial Tests - AnyMissConstraint" begin
    for k in 1:200
        for x in 0:k
            trivial_anymiss(x, k)
        end # for
    end # for
end # testset 

@testset "Trivial Tests - AnyHitConstraint" begin
    for k in 1:200
        for x in 0:k
            trivial_anyhit(x, k)
        end # for
    end # for
end # testset 

###############################
### Aux dominance functions ###
###############################

function rowmissrowmiss_tests(x1, x2)
    c1 = RowMissConstraint(x1)
    c2 = RowMissConstraint(x2)

    if x1 == x2
        @test is_dominant(c1, c2) && is_dominant(c2, c1)
    elseif x1 < x2
        @test is_dominant(c1, c2)
    else
        @test is_dominant(c2, c1)
    end
end # function

function rowhitrowhit_tests(x1, k1, x2, k2)
    c1 = RowHitConstraint(x1, k1)
    c2 = RowHitConstraint(x2, k2)

    if x2 == 0
        @test is_dominant(c1, c2)
    elseif x1 == 0
        @test !is_dominant(c1, c2)
    elseif k2 >= k1 
        @test (x2 <= x1) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
    else
        @test (x2 <= x1 - ceil( (k1-k2)/2 )) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
    end
end # function

function anymissanymiss_tests(x1, k1, x2, k2)
    c1 = AnyMissConstraint(x1, k1)
    c2 = AnyMissConstraint(x2, k2)
    n1 = k1 - x1
    n2 = k2 - x2

    @test (n2 <= max(n1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(n1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function anyhitanyhit_tests(x1, k1, x2, k2)
    c1 = AnyHitConstraint(x1, k1)
    c2 = AnyHitConstraint(x2, k2)

    @test (x2 <= max(x1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(x1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

#######################
### Dominance tests ###
#######################

@testset "RowMiss-RowMiss - Tests" begin
    for i in 1:10000
        x1 = rand(0:i)
        x2 = rand(0:i)
        rowmissrowmiss_tests(x1, x2)
    end # for
end # testset

@testset "RowHit-RowHit - Tests" begin
    for i in 2:10001
        k1 = rand(1:i)
        k2 = rand(1:i)
        x1 = rand(0:floor(Int, k1/2))
        x2 = rand(0:floor(Int, k2/2))
        rowhitrowhit_tests(x1, k1, x2, k2)
    end # for
end # testset

@testset "AnyMiss-AnyMiss - Tests" begin
    for i in 1:10000
        k1 = rand(1:i)
        k2 = rand(1:i)
        x1 = rand(0:k1)
        x2 = rand(0:k2)
        anymissanymiss_tests(x1, k1, x2, k2)
    end # for
end # testset

@testset "AnyHit-AnyHit - Tests" begin
    for i in 1:10000
        k1 = rand(1:i)
        k2 = rand(1:i)
        x1 = rand(0:k1)
        x2 = rand(0:k2)
        anyhitanyhit_tests(x1, k1, x2, k2)
    end # for
end # testset

#################################
### Aux cross-dominance tests ###
#################################

### RowMiss-X ###
function rowmissrowhit_tests(x1, k1, x2, k2)
    c1 = RowMissConstraint(x1)
    c2 = RowHitConstraint(x2, k2)

    x1 = 1
    k1 = c1.x+1
    z1 = k1-x1

    @test (x2 <= min(floor(k2/(z1+1)), max(floor(k1/(z1+1)), ceil(x1/z1)))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function rowmissanymiss_tests(x1, k1, x2, k2)
    c1 = RowMissConstraint(x1)
    c2 = AnyMissConstraint(x2, k2)

    x1 = 1
    k1 = c1.x+1
    x2 = k2 - x2

    @test (x2 <= max(x1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(x1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function rowmissanyhit_tests(x1, k1, x2, k2)
    c1 = RowMissConstraint(x1)
    c2 = AnyHitConstraint(x2, k2)

    x1 = 1
    k1 = c1.x+1
    x2 = x2

    @test (x2 <= max(x1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(x1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

### RowHit-X ###
function rowhitrowmiss_tests(x1, k1, x2, k2)
    c1 = RowHitConstraint(x1, k1)
    c2 = RowMissConstraint(x2)

    z1 = k1-2x1+1
    x2 = 1
    k2 = c2.x+1

    @test (x2 <= max(x1*floor(k2/(z1+x1)), k2 - floor(k2/(z1+x1))*z1 - z1)) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function rowhitanymiss_tests(x1, k1, x2, k2)
    c1 = RowHitConstraint(x1, k1)
    c2 = AnyMissConstraint(x2, k2)

    z1 = k1-2x1+1
    x2 = k2-x2

    @test (x2 <= max(x1*floor(k2/(z1+x1)), k2 - floor(k2/(z1+x1))*z1 - z1)) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function rowhitanyhit_tests(x1, k1, x2, k2)
    c1 = RowHitConstraint(x1, k1)
    c2 = AnyHitConstraint(x2, k2)

    z1 = k1-2x1+1

    return x2 <= max(x1*floor(k2/(z1+x1)), k2 - floor(k2/(z1+x1))*z1 - z1)
end # function

### AnyMiss-X ###
function anymissrowmiss_tests(x1, k1, x2, k2)
    c1 = AnyMissConstraint(x1, k1)
    c2 = RowMissConstraint(x2)

    x1 = k1 - x1
    x2 = 1
    k2 = c2.x+1

    @test (x2 <= max(x1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(x1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function anymissrowhit_tests(x1, k1, x2, k2)
    c1 = AnyMissConstraint(x1, k1)
    c2 = RowHitConstraint(x2, k2)

    z1 = x1
    x1 = k1-x1

    @test (x2 <= min(floor(k2/(z1+1)), max(floor(k1/(z1+1)), ceil(x1/z1)))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function anymissanyhit_tests(x1, k1, x2, k2)
    c1 = AnyMissConstraint(x1, k1)
    c2 = AnyHitConstraint(x2, k2)

    x1 = k1 - x1

    @test (x2 <= max(x1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(x1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

### AnyHit-X ###
function anyhitrowmiss_tests(x1, k1, x2, k2)
    c1 = AnyHitConstraint(x1, k1)
    c2 = RowMissConstraint(x2)

    x2 = 1
    k2 = c2.x+1

    @test (x2 <= max(x1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(x1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function anyhitrowhit_tests(x1, k1, x2, k2)
    c1 = AnyHitConstraint(x1, k1)
    c2 = RowHitConstraint(x2, k2)

    z1 = k1-x1

    @test (x2 <= min(floor(k2/(z1+1)), max(floor(k1/(z1+1)), ceil(x1/z1)))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

function anyhitanymiss_tests(x1, k1, x2, k2)
    c1 = AnyHitConstraint(x1, k1)
    c2 = AnyMissConstraint(x2, k2)

    x2 = k2-x2

    @test (x2 <= max(x1*floor(Int, k2/k1), k2+ceil(Int, k2/k1)*(x1-k1))) ? is_dominant(c1, c2) : !is_dominant(c1, c2)
end # function

#############################
### Cross-dominance tests ###
#############################

@testset "RowMiss-X - Analytic Tests" begin
    for i in 1:10000
        k = rand(1:i, 4)
        x = [rand(0:j) for j in k]

        rowmissrowhit_tests(x[1], x[1]+1, floor(Int, x[2]/2), k[2])
        rowmissanymiss_tests(x[1], x[1]+1, x[3], k[3])
        rowmissanyhit_tests(x[1], x[1]+1, x[4], k[4])
    end # for
end # testset

@testset "RowHit-X - Analytic Tests" begin
    for i in 1:10000
        k = rand(1:i, 4)
        x = [rand(0:j) for j in k]

        rowhitrowmiss_tests(floor(Int, x[2]/2), k[2], x[1], x[1]+1)
        rowhitanymiss_tests(floor(Int, x[2]/2), k[2], x[3], k[3])
        rowhitanyhit_tests(floor(Int, x[2]/2), k[2], x[4], k[4])
    end # for
end # testset

@testset "AnyMiss-X - Analytic Tests" begin
    for i in 1:10000
        k = rand(1:i, 4)
        x = [rand(0:j) for j in k]

        anymissrowmiss_tests(x[3], k[3], x[1], x[1]+1)
        anymissrowhit_tests(x[3], k[3], floor(Int, x[2]/2), k[2])
        anymissanyhit_tests(x[3], k[3], x[4], k[4])
    end # for
end # testset

@testset "AnyHit-X - Analytic Tests" begin
    for i in 1:10000
        k = rand(1:i, 4)
        x = [rand(0:j) for j in k]

        anyhitrowmiss_tests(x[4], k[4], x[1], x[1]+1)
        anyhitrowhit_tests(x[4], k[4], floor(Int, x[2]/2), k[2])
        anyhitanymiss_tests(x[4], k[4], x[3], k[3])
    end # for
end # testset

#######################
### satisfied tests ###
#######################

Threads.@threads for k1 = 1:k_max-1
    for x1 in 0:k1
        l1 = RowMissConstraint(x1)
        S1 = generate_all_valid(l1)

        @testset "BruteForce Tests" begin
            for k2 = 1:k_max
                for x2 = 0:k2
                    l2 = RowHitConstraint(x2, k2)
                    S2 = generate_all_valid(l2)

                    @test is_dominant(l1, l2) ? isempty(setdiff(S1, S2)) : !isempty(setdiff(S1, S2))

                    @test is_dominant(l2, l1) ? isempty(setdiff(S2, S1)) : !isempty(setdiff(S2, S1))

                    for k3 = 1:k_max
                        for x3 = 0:k3
                            l3 = AnyMissConstraint(x3, k3)
                            S3 = generate_all_valid(l3)

                            @test is_dominant(l1, l3) ? isempty(setdiff(S1, S3)) : !isempty(setdiff(S1, S3))

                            @test is_dominant(l2, l3) ? isempty(setdiff(S2, S3)) : !isempty(setdiff(S2, S3))

                            @test is_dominant(l3, l1) ? isempty(setdiff(S3, S1)) : !isempty(setdiff(S3, S1))
                            @test is_dominant(l3, l2) ? isempty(setdiff(S3, S2)) : !isempty(setdiff(S3, S2))

                            for k4 = 1:k_max
                                for x4 = 0:k4
                                    l4 = AnyHitConstraint(x4, k4)
                                    S4 = generate_all_valid(l4)

                                    @test is_dominant(l1, l4) ? isempty(setdiff(S1, S4)) : !isempty(setdiff(S1, S4))

                                    @test is_dominant(l2, l4) ? isempty(setdiff(S2, S4)) : !isempty(setdiff(S2, S4))

                                    @test is_dominant(l3, l4) ? isempty(setdiff(S3, S4)) : !isempty(setdiff(S3, S4))

                                    @test is_dominant(l4, l1) ? isempty(setdiff(S4, S1)) : !isempty(setdiff(S4, S1))
                                    @test is_dominant(l4, l2) ? isempty(setdiff(S4, S2)) : !isempty(setdiff(S4, S2))
                                    @test is_dominant(l4, l3) ? isempty(setdiff(S4, S3)) : !isempty(setdiff(S4, S3))
                                end # for
                            end # for
                        end # for
                    end # for
                end # for
            end # for
        end # testset
    end # for
end # for

end # module
