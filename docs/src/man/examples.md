# Examples

## Building Automata
Generates the automaton representations of the constraints `AnyHitConstraint(1, 3)` and `RowHitConstraint(2, 6)`.

```julia
# Constraints
lambda1 = AnyHitConstraint(1, 3)
lambda2 = RowHitConstraint(2, 6)

# Check dominance
is_dominant(lambda1, lambda2) # false
is_dominant(lambda2, lambda1) # false

# Generate automaton for lambda1
G1 = build_automaton(lambda1) 

# This generates the automaton:
# Automaton{Int64} with 3 vertices:
# {
#         WordVertex{Int64}(100 => ---, 001) # --- is an infeasible vertex
#         WordVertex{Int64}(010 => 100, 001)
#         WordVertex{Int64}(001 => 010, 001)
# } with head: WordVertex{Int64}(1 => 10, 1)

G2 = build_automaton(lambda2)

# This generates the automaton:
# Automaton{Int64} with 6 vertices:
# {
#         WordVertex{Int64}(01100 => 11000, 00001)
#         WordVertex{Int64}(11000 => -----, 00001)
#         WordVertex{Int64}(01101 => 11000, 00011)
#         WordVertex{Int64}(00011 => 00110, 00011)
#         WordVertex{Int64}(00110 => 01100, 01101)
#         WordVertex{Int64}(00001 => -----, 00011)
# } with head: WordVertex{Int64}(11 => 110, 11)
```

## Generating sequences satisfying constraints
Generates a random sequence satisfying the constraint `AnyHitConstraint(3, 5)`.

```julia
l = AnyHitConstraint(3, 5)
G = build_automaton(l)
N = 100_000
seq = random_sequence(G, N)

bitstring(seq)
```

if the bitstring has `M < N` characters, it implies that the first `N-M` characters are misses (since julia interpret zeros before the MSB in a bit string as non-existent)

## Generating satisfaction set
Generates all the sequences of length `N` that satisfy the constraint `AnyHitConstraint(2, 3)`.

```julia
l = AnyHitConstraint(2, 3)
G = build_automaton(l)
N = 10
S = all_sequences(G, N)

for s in S
    println(bitstring(s)[end-N+1:end])
end
```

`S` is here a `Set{<: Integer}`, meaning we have to get the bitstring representation of the sequences in order to represent it as a sequence of deadline hits and misses.
