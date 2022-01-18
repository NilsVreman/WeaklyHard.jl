module DominantSetTests

using Test
using WeaklyHard

const n_tests   = 10_000
const k_max     = 200
@testset "2 Random Constraints" begin
    constraint_names = ["RowMissConstraint", "RowHitConstraint", "AnyMissConstraint", "AnyHitConstraint"]

    for _ in 1:n_tests

        k1 = rand(1:k_max)
        k2 = rand(1:k_max)
        x1 = rand(0:k1)
        x2 = rand(0:k2)

        l1_type = rand(constraint_names)
        l2_type = rand(constraint_names)
        if l1_type == "RowHitConstraint"
            x1 = floor(Int, x1/2)
        end
        if l2_type == "RowHitConstraint"
            x2 = floor(Int, x2/2)
        end
        lambda_1 = getfield(WeaklyHard, Symbol(l1_type))(x1, k1)
        lambda_2 = getfield(WeaklyHard, Symbol(l2_type))(x2, k2)

        Lambda = Set{Constraint}([lambda_1, lambda_2])
        Lambda_star = dominant_set(Lambda)

        if is_equivalent(lambda_1, lambda_2)
            @test length(Lambda_star) == 1
        elseif is_dominant(lambda_1, lambda_2)
            @test length(Lambda_star) == 1 && (lambda_1 in Lambda_star)
        elseif !is_dominant(lambda_2, lambda_1)
            @test length(Lambda_star) == 2 && (lambda_1 in Lambda_star) && (lambda_2 in Lambda_star)
        else
            @test length(Lambda_star) == 1 && (lambda_2 in Lambda_star)
        end #if
    end # for
end # testset

@testset "Arbitrary Random Constraints" begin
    constraint_names = ["RowMissConstraint", "RowHitConstraint", "AnyMissConstraint", "AnyHitConstraint"]
    n_constraints   = 30

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
        Lambda_comp = setdiff(Lambda, Lambda_star)

        test_res = true
        for lambda_c in Lambda_comp
            exist_dominant = false
            for lambda_s in Lambda_star
                if is_dominant(lambda_s, lambda_c)
                    exist_dominant = true
                    break
                end
            end
            if !exist_dominant
                @show Lambda
                test_res = false
                break
            end # if
        end # for
        @test test_res
    end # for
end # testset

end # module
