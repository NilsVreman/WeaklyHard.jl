using WeaklyHard
"""
Example for comparing dominance and equivalence of WeaklyHard constraints
"""

# Constraints to test
lambda1 = AnyHitConstraint(48, 54)
lambda2 = AnyMissConstraint(12, 67)
lambda3 = AnyHitConstraint(12, 15)
lambda4 = RowMissConstraint(9)
lambda5 = RowHitConstraint(20, 47)
lambda6 = RowHitConstraint(5, 12)
lambda7 = RowMissConstraint(3)

lambdas = [lambda1, lambda2, lambda3, lambda4, lambda5, lambda6, lambda7]

# Compare individual constraints
for l1 in lambdas
    for l2 in lambdas
        if is_equivalent(l1, l2)
            println("$l1 \t===\t $l2")
        elseif is_dominant(l1, l2)
            println("$l1 \t<=\t $l2")
        else
            println("$l1 \t</=\t $l2")
        end # if
    end # for
    println(" ")
end # for
