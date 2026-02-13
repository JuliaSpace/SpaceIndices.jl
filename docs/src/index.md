# SpaceIndices.jl

This package allows to automatically fetch and parse space indices.

The space index sets supported in this version are:

| **Space Index Set** | **File**                        | **Expiry period** | **Information**                                                  |
|:--------------------|:--------------------------------|:------------------|:-----------------------------------------------------------------|
| `Celestrak`         | `SW-All.csv`                    | 1 day             | F10.7, AP, KP, ISN, C9, Cp, ND, BSRN (historic and predicted).   |
| `JB2008`            | `DTCFILE.TXT`                   | 1 day             | Exospheric temperature variation caused by the Dst index.        |
|                     | `SOLFSMY.TXT`                   | 1 day             | Indices necessary for the JB2008 atmospheric model.              |
| `Hpo`               | `Hp30_ap30_complete_series.txt` | 1 day             | Complete historical Hp30/ap30 geomagnetic indices (since 1985).  |
|                     | `Hp60_ap60_complete_series.txt` | 1 day             | Complete historical Hp60/ap60 geomagnetic indices (since 1985).  |
| `Dst`               | Kyoto WDC HTML pages            | 1 day             | Hourly Dst index and dTc storm-time temperature correction.      |

## Installation

This package can be installed using:

```julia-repl
julia> using Pkg
julia> Pkg.add("SpaceIndices")
```
