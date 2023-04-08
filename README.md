SpaceIndices.jl
===============

[![CI](https://github.com/JuliaSpace/SpaceIndices.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/JuliaSpace/SpaceIndices.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/JuliaSpace/SpaceIndices.jl/branch/main/graph/badge.svg?token=6RTJKQHNPF)](https://codecov.io/gh/JuliaSpace/SpaceIndices.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

This package allows to automatically fetch and parse space indices.

The files supported in this version are:

| File            | Expiry period      | Information                                              |
|:----------------|:-------------------|:---------------------------------------------------------|
| `fluxtable.txt` | 1 day              | It contains the F10.7 flux data (observed and adjusted). |

## Installation

This package can be installed using:

``` julia
julia> using Pkg
julia> Pkg.add("SpaceIndices")
```
