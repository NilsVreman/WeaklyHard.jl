# WeaklyHard.jl
This repository contains the source code for the WeaklyHard.jl package submitted
anonymously as supplementary material to the paper:
    "WeaklyHard.jl: Scalable Analysis of Weakly-Hard Constraints"

The following file contains an introduction on how to use the tool alongside
some simple examples.


[![Build Status](https://github.com/NilsVreman/WeaklyHard.jl/workflows/CI/badge.svg)](https://github.com/NilsVreman/WeaklyHard.jl/actions)
[![Coverage](https://codecov.io/gh/NilsVreman/WeaklyHard.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/NilsVreman/WeaklyHard.jl)

__TODO ASAP__: Fix this file 

## How To Activate and Use the Package
The WeaklyHard.jl package was developed in Julia [1] version 1.5.4.
The Julia distribution should however be close to irrelevant, since the only
dependency the package has is the Test.jl and LinearAlgebra.jl packages (which
are automatically included in all Julia distributions).

### Quick Introduction to Packages in Julia
A Julia package (also denoted a `Module`) is an environment containing at least
3 files:

* `Project.toml`: The Project-file contains most of the package information,
  e.g., authors, package version, package name, and dependencies,
* `Manifest.toml`: The Manifest-file is a machine-generated file tracking
  dependencies of the package dependencies, and
* `WeaklyHard.jl` (the Module file): Containing the code that is imported when
  the package is imported.

A package is included by `using` or `import`. When `using` a package, functions
(specified by the developers) are exported to global scope and can be used
freely by the user.

### Basics for Activating WeaklyHard.jl
1. When a Julia distribution (preferrably a newer version) has been installed,
   open the root directory (the directory containing `Project.toml`,
   `Manifest.toml`, `src/`, and `test/`).
2. Activate the Julia REPL.
3. Activate the package manager by pressing the `]`-key.
4. Activate the WeaklyHard.jl environment by entering `activate .`.
5. Instantiate the project dependencies by entering `instantiate`
6. Go back to the Julia command line by pressing the `backspace`-key until the
   command line states `julia>` again.
7. Activate the WeaklyHard.jl environment by entering `using WeaklyHard`
8. The package is now activated and present in the global scope.

### Basics for Using WeaklyHard.jl 
We now provide four different examples of how to use the package.

__NOTE (automaton representation)__: 

An automaton is represented by a record containing `X` amount of type `IntI` words as:

```
Automaton{IntI} with X vertices:
{
        WordVertex{IntI}(x => y, z)
        ...
}
```

Here, `WordVertex{IntI}(x => y, z)` indicates a vertex represented by an `IntI`
type, where `x` is the word the vertex is representating and `y`, `z` are the
direct successors corresponding to respectively a deadline miss and a deadline
hit.

#### Example 1 - Comparing single constraints
```
lambda1 = AnyHitConstraint(3, 5)
lambda2 = AnyMissConstraint(1, 3)

is_dominant(lambda1, lambda2) # false
is_dominant(lambda2, lambda1) # true
```

#### Example 2 - Comparing sets of constraints
```
lambda1 = AnyHitConstraint(13, 18)
lambda2 = AnyMissConstraint(4, 16)
lambda3 = RowHitConstraint(2, 6)
lambda4 = AnyHitConstraint(4, 7)
lambda5 = RowMissConstraint(3)

Lambda1 = Set([lambda1, lambda2, lambda5])
Lambda2 = Set([lambda3, lambda4, lambda5])
Lambda  = union(Lambda1, Lambda2)

Lambda1_star = dominant_set(Lambda1) # returns Lambda1
Lambda2_star = dominant_set(Lambda2) # returns Set([lambda3, lambda4])
Lambda3_star = dominant_set(Lambda)  # returns Set([lambda1, lambda2, lambda3, lambda4])
```

#### Example 3 - Generating automata representation (Example 1 in paper)
Consider Example 1 in Section IV-D:

```
lambda1 = AnyHitConstraint(1, 3)
lambda2 = RowHitConstraint(2, 6)

is_dominant(lambda1, lambda2) # false
is_dominant(lambda2, lambda1) # false

Lambda = Set([lambda1, lambda2])

G1 = build_automaton(lambda1) 
# Automaton{Int64} with 3 vertices:
# {
#         WordVertex{Int64}(100 => ---, 001) # --- is an infeasible vertex
#         WordVertex{Int64}(010 => 100, 001)
#         WordVertex{Int64}(001 => 010, 001)
# } with head: WordVertex{Int64}(1 => 10, 1 

G2 = build_automaton(lambda2)
# Automaton{Int64} with 6 vertices:
# {
#         WordVertex{Int64}(01100 => 11000, 00001)
#         WordVertex{Int64}(11000 => -----, 00001)
#         WordVertex{Int64}(01101 => 11000, 00011)
#         WordVertex{Int64}(00011 => 00110, 00011)
#         WordVertex{Int64}(00110 => 01100, 01101)
#         WordVertex{Int64}(00001 => -----, 00011)
# } with head: WordVertex{Int64}(11 => 110, 11)

G = build_automaton(Lambda)
# Automaton{Int64} with 7 vertices:
# {
#         WordVertex{Int64}(011010 => ------, 110101)
#         WordVertex{Int64}(001101 => 011010, 000011)
#         WordVertex{Int64}(011001 => ------, 000011)
#         WordVertex{Int64}(110101 => ------, 000011)
#         WordVertex{Int64}(000011 => 000110, 000011)
#         WordVertex{Int64}(000110 => 001100, 001101)
#         WordVertex{Int64}(001100 => ------, 011001)
# } with head: WordVertex{Int64}(11 => 110, 11)

minimize_automaton!(G)
# Automaton{Int64} with 5 vertices: # Note: G changes after this command
# {
#         WordVertex{Int64}(01101 => 01100, 00011)
#         WordVertex{Int64}(11001 => -----, 00011)
#         WordVertex{Int64}(00011 => 00110, 00011)
#         WordVertex{Int64}(00110 => 01100, 01101)
#         WordVertex{Int64}(01100 => -----, 11001)
# } with head: WordVertex{Int64}(11 => 110, 11)
```

#### Example 4 - Generating random sequence adhering to G
Assume `G` is the automaton generated in Example 3:

```
N = 100 # length of the sequence 
seq = random_sequence(G, N) # returns a BigInt (Integer with more than 64 bits)
bitstring(seq) # Prints the sequence as a bit string
```

if the bitstring has `M < N` characters, it implies that the first `N-M`
characters are misses (since julia interpret zeros before the MSB in a bit
string as non-existent)

#### Example 5 - Generating satisfaction set adhering to G
Assume `G` is the automaton generated in Example 3.

```
N = 30                                  # length of the sequence 
satisfaction_set = all_sequences(G, N)  # returns a Set{Int32} with 8_577_449 integers.  
```

if a bitstring in the set has `M < N` characters, it implies that the first
`N-M` characters are misses (since julia interpret zeros before the MSB in a bit
string as non-existent)

## References
[1] J. Bezanson, A. Edelman, S. Karpinski, and V. Shah. Julia: A fresh approach to numerical computing. SIAM review, 59(1):65-98, 2017.
