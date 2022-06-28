using Documenter, WeaklyHard

#DocMeta.setdocmeta!(WeaklyHard, :DocTestSetup, :(using WeaklyHard); recursive=true)

makedocs(modules=[WeaklyHard],
         format=Documenter.HTML(),
         sitename="WeaklyHard.jl",
         pages=[
             "Home" => "index.md",
             "Examples" => "man/examples.md",
             "Functions" => "man/functions.md",
             "Index" => "man/summary.md"
             ])

deploydocs(repo = "github.com/NilsVreman/WeaklyHard.jl.git")
