# WeaklyHard.jl Documentation

[WeaklyHard](https://github.com/NilsVreman/WeaklyHard.jl) is a toolbox for analysing the real-time concept of weakly-hard constraints, in Julia.

## Installation

To install the package, simply run

```julia
using Pkg; Pkg.add("WeaklyHard")
```

## Introduction

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

## Guide

```@contents
Pages = ["man/examples.md", "man/functions.md", "man/summary.md"]
Depth = 1
```
