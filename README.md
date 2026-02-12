# SpaceIndices.jl

[![CI](https://github.com/JuliaSpace/SpaceIndices.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/JuliaSpace/SpaceIndices.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/JuliaSpace/SpaceIndices.jl/branch/main/graph/badge.svg?token=6RTJKQHNPF)](https://codecov.io/gh/JuliaSpace/SpaceIndices.jl)
[![docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)][docs-stable-url]
[![docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)][docs-dev-url]
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![DOI](https://zenodo.org/badge/625061522.svg)](https://zenodo.org/doi/10.5281/zenodo.8339346)

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

Those sets provide the following indices:

| **Space Index Set** | **Index**             | **Description**                                                    | **Unit**            |
|:--------------------|:----------------------|:-------------------------------------------------------------------|:--------------------|
| `Celestrak`         | `F10obs`              | Observed F10.7 (10.7-cm solar flux)                                | 10⁻²² W / (M² ⋅ Hz) |
|                     | `F10obs_avg_center81` | Observed F10.7 (10.7-cm solar flux) averaged over 81 days centered | 10⁻²² W / (M² ⋅ Hz) |
|                     | `F10obs_avg_last81`   | Observed F10.7 (10.7-cm solar flux) averaged over 81 last days     | 10⁻²² W / (M² ⋅ Hz) |
|                     | `F10adj`              | Adjusted F10.7 (10.7-cm solar flux)                                | 10⁻²² W / (M² ⋅ Hz) |
|                     | `F10adj_avg_center81` | Observed F10.7 (10.7-cm solar flux) averaged over 81 days centered | 10⁻²² W / (M² ⋅ Hz) |
|                     | `F10adj_avg_last81`   | Observed F10.7 (10.7-cm solar flux) averaged over 81 last days     | 10⁻²² W / (M² ⋅ Hz) |
|                     | `Ap`                  | Ap index computed every three hours                                |                     |
|                     | `Ap_daily`            | Daily Ap index                                                     |                     |
|                     | `Kp`                  | Kp index computed every three hours                                |                     |
|                     | `Kp_daily`            | Daily Kp index                                                     |                     |
|                     | `Cp`                  | Daily planetary character figure                                   |                     |
|                     | `C9`                  | Daily magnetic index on Cp basis                                   |                     |
|                     | `ISN`                 | International sunspot number                                       |                     |
|                     | `BSRN`                | Bartels solar rotation number                                      |                     |
|                     | `ND`                  | Number of days into Bartels solar rotation cycle                   | Days                |
| `JB2008`            | `DTC`                 | Exospheric temperature variation caused by the Dst index           | K                   |
|                     | `S10`                 | EUV index (26-34 nm) scaled to F10.7                               | 10⁻²² W / (M² ⋅ Hz) |
|                     | `M10`                 | MG2 index scaled to F10.7                                          | 10⁻²² W / (M² ⋅ Hz) |
|                     | `Y10`                 | Solar X-ray & Lya index scaled to F10.7                            | 10⁻²² W / (M² ⋅ Hz) |
|                     | `S81a`                | 81-day averaged EUV index (26-34 nm) scaled to F10.7               | 10⁻²² W / (M² ⋅ Hz) |
|                     | `M81a`                | 81-day averaged MG2 index scaled to F10.7                          | 10⁻²² W / (M² ⋅ Hz) |
|                     | `Y81a`                | 81-day averaged solar X-ray & Lya index scaled to F10.7            | 10⁻²² W / (M² ⋅ Hz) |
| `Hpo`               | `Hp30`                | Geomagnetic index with 30-minute resolution                        |                     |
|                     | `ap30`                | Linear geomagnetic activity index (30-minute)                      |                     |
|                     | `Hp60`                | Geomagnetic index with 60-minute resolution                        |                     |
|                     | `ap60`                | Linear geomagnetic activity index (60-minute)                      |                     |
| `Dst`               | `Dst`                 | Disturbance Storm Time index (hourly)                              | nT                  |
|                     | `DTC_Dst`             | Exospheric temperature variation from Dst (DTCMAKEDR algorithm)    | K                   |

## Installation

This package can be installed using:

``` julia
julia> using Pkg
julia> Pkg.add("SpaceIndices")
```

## Documentation

For more information, see the [documentation][docs-stable-url].

[docs-dev-url]: https://juliaspace.github.io/SpaceIndices.jl/dev
[docs-stable-url]: https://juliaspace.github.io/SpaceIndices.jl/stable
