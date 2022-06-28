# WeaklyHard.jl

[![Build Status](https://github.com/NilsVreman/WeaklyHard.jl/workflows/CI/badge.svg)](https://github.com/NilsVreman/WeaklyHard.jl/actions)
[![Coverage](https://codecov.io/gh/NilsVreman/WeaklyHard.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/NilsVreman/WeaklyHard.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://NilsVreman.github.io/WeaklyHard.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://NilsVreman.github.io/WeaklyHard.jl/dev)

A toolbox for analysing weakly-hard constraints in Julia.

## Installation

To install, in the Julia REPL:

```julia
using Pkg; Pkg.add("WeaklyHard")
```

## Documentation

All functions have docstrings which can be viewed from the REPL, using for example `?build_automaton`.

## Usage

We provide a number of weakly-hard constraint structs, used as input to different analysis functions.

* `AnyHitConstraint(x, k)`: For _any_ window of `k` consecutive job activations, _at least_ `x` jobs hit their corresponding deadline;
* `AnyMissConstraint(x, k)`: For _any_ window of `k` consecutive job activations, _at most_ `x` jobs miss their corresponding deadline;
* `RowHitConstraint(x, k)`: For _any_ window of `k` consecutive job activations, _at least_ `x` consecutive jobs hit their corresponding deadline;
* `RowMissConstraint(x)`: For _any_ window of `k` consecutive job activations, _at most_ `x` consecutive jobs miss their corresponding deadline.

An automaton representation of a weakly-hard constraint is a struct consisting of a record containing `X` amount of integers as:

```julia
Automaton{Int} with X vertices:
{
        WordVertex{Int}(x => y, z)
        ...
} with head: WordVertex{Int}(x => y, z)
```

Here, `WordVertex{Int}(x => y, z)` indicates a vertex represented by an `Integer` type, where `x` is the word the vertex is representating and `y`, `z` are the direct successors corresponding to respectively a deadline miss and a deadline hit.

## Example
```julia
using WeaklyHard

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

# Generate a random sequence of length N satisfying the constraint represented by G2
N = 100_000
seq = random_sequence(G2, N)
bitstring(seq)
# The bit representation of the integer
```

if the bitstring has `M < N` characters, it implies that the first `N-M`
characters are misses (since julia interpret zeros before the MSB in a bit
string as non-existent)

## Additional examples

See the examples folder
