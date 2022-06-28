using Documenter, WeaklyHard

DocMeta.setdocmeta!(WeaklyHard, :DocTestSetup, :(using WeaklyHard); recursive=true)

makedocs(modules=[WeaklyHard],
         authors="NilsVreman <nils.vreman@gmail.com> and contributors",
         repo="https://github.com/NilsVreman/WeaklyHard.jl/blob/{commit}{path}#{line}",
         sitename="WeaklyHard.jl",
         format=Documenter.HTML(
                                canonical="https://NilsVreman.github.io/WeaklyHard.jl",
                                assets=String[]
                               ),
         pages=[
             "Home" => "index.md",
             "Examples" => "man/examples.md",
             "Functions" => "man/functions.md",
             "Index" => "man/summary.md"
             ])

deploydocs(repo = "github.com/NilsVreman/WeaklyHard.jl.git")
