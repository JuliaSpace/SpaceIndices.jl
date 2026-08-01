using Documenter
using SpaceIndices

makedocs(;
    modules = [SpaceIndices],
    format = Documenter.HTML(;
        prettyurls = !("local" in ARGS),
        canonical = "https://juliaspace.github.io/SpaceIndices.jl/stable/",
    ),
    sitename = "SpaceIndices.jl",
    authors = "Ronan Arraes Jardim Chagas",
    pages = [
        "Home" => "index.md",
        "Quick start" => "man/quick_start.md",
        "Usage" => [
            "Initialization"    => "man/initialization.md",
            "Get space indices" => "man/get.md",
            "API"               => "man/api.md",
        ],
        "Library" => "lib/library.md",
    ],
)

deploydocs(; repo = "github.com/JuliaSpace/SpaceIndices.jl.git", target = "build")
