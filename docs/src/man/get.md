# Obtaining the Space Indices

```@meta
CurrentModule = SpaceIndices
```

```@repl get
using Dates
using SpaceIndices
SpaceIndices.Scratch.clear_scratchspaces!(SpaceIndices)
```

After the initialization shown in [Initialization of Space Indices](@ref), the user can
obtain the space index value using the function:

```julia
space_index(::Val{:index}, jd::Number; kwargs...) -> Number
space_index(::Val{:index}, instant::DateTime; kwargs...) -> Number
```

where `index` is the desired space index and `jd` is the Julian Day to obtain the
information. The latter can also be specified using `instant`, which is a `DateTime` object.

```@repl get
SpaceIndices.init()

space_index(Val(:F10adj), DateTime(2020, 6, 19))

space_index(Val(:F10adj), 2.4590195e6)
```

The following space indices are currently supported:

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

!!! note
    The `Dst` index set is not included in the default `SpaceIndices.init()` call. It must
    be initialized separately after an ap data source (`Celestrak` or `Hpo`) is available.
    See [Initialization of Space Indices](@ref) for details.
