module PrintingTests

using Test
using WeaklyHard

@testset "Print automaton" begin
    g1 = build_automaton(AnyHitConstraint(1, 3))
    @test_nowarn println(g1)
    @test_nowarn println(g1.head)

    g2 = build_automaton(AnyHitConstraint(10, 16))
    @test_nowarn println(g2)
    @test_nowarn println(g2.head)

    g3 = build_automaton(RowHitConstraint(15, 60))
    @test_nowarn println(g3)
    @test_nowarn println(g3.head)
end #testset

@testset "Print BigInt" begin
    g1 = build_automaton(AnyHitConstraint(1, 3))
    seq1 = random_sequence(g1, 200)
    @test_nowarn bitstring(seq1)
    seq2 = random_sequence(g2, 100_000)
    @test_nowarn bitstring(seq2)
end #testset

@testset "Print Constraint" begin
    l1 = AnyHitConstraint(1, 3)
    @test_nowarn println(l1)
    l2 = AnyMissConstraint(1, 3)
    @test_nowarn println(l2)
    l3 = RowHitConstraint(1, 3)
    @test_nowarn println(l3)
    l4 = RowMissConstraint(1, 3)
    @test_nowarn println(l4)
end #testset

end # module
