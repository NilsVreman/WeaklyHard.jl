using WeaklyHard
"""
Example for generating automata for (sets of) weakly-hard constraints
"""

# Constraints
lambda1 = AnyHitConstraint(12, 15)
lambda2 = RowHitConstraint(15, 47)
lambda3 = RowMissConstraint(3)
lambda4 = AnyMissConstraint(2, 3)
lambda5 = RowHitConstraint(2, 6)

# Generate automata
G1 = build_automaton(lambda1)
G2 = build_automaton(lambda2)
G3 = build_automaton(lambda3)

# set construction
Lambda_star = dominant_set(Set([lambda4, lambda5]))
G = build_automaton(Lambda_star)
minimize_automaton!(G)
