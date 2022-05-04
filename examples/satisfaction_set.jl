using WeaklyHard
"""
Example for generating satisfaction sets for weakly-hard constraints
"""

# Constraints
lambda1 = AnyHitConstraint(12, 15)
lambda2 = RowHitConstraint(15, 47)
lambda3 = RowMissConstraint(3)

# Generate automata
G1 = build_automaton(lambda1)
G2 = build_automaton(lambda2)
G3 = build_automaton(lambda3)

# Generate satisfaction set of length N
N = 20
S1 = all_sequences(G1, N)
S2 = all_sequences(G2, N)
S3 = all_sequences(G3, N)

# check that all sequences satisfy the constraint
for w in S1
    if !is_satisfied(lambda1, w)
        println("Sequence ($(bitstring(w)[end-N+1:end])) does not satisfy $lambda1")
    end # if 
end # for
for w in S2
    if !is_satisfied(lambda2, w)
        println("Sequence ($(bitstring(w)[end-N+1:end])) does not satisfy $lambda2")
    end # if 
end # for
for w in S3
    if !is_satisfied(lambda3, w)
        println("Sequence ($(bitstring(w)[end-N+1:end])) does not satisfy $lambda3")
    end # if 
end # for
