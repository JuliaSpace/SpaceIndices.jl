SpaceIndices.jl Changelog
=========================

Version 2.1.0
-------------

- ![Feature][badge-feature] We added the support for the Dst index. (PR [#11][gh-pr-11])
- ![Enhancement][badge-enhancement] The differentiability tests were moved to an external
  package, leading to a huge reduction in the testing time of SpaceIndices.jl. (PR
[#11][gh-pr-11])

Version 2.0.1
-------------

- ![Bugfix][badge-bugfix] The tests are now passing in Julia 1.12. (PR [#9][gh-pr-9])

Version 2.0.0
-------------

- ![BREAKING][badge-breaking] The types of the indices `BSRN`, `ND`, `kp`, `ap`, `ISN`, and
  `ap_daily` have changed to support the automatic differentiation. Hence, this is a
  breaking release.
- ![Enhancement][badge-enhancement] The package now supports automatic differentiation using
  many packages. (PR [#7][gh-pr-7])

Version 1.2.2
-------------

- ![Bugfix][badge-bugfix] We fixed a bug that was failing the documentation build process.

Version 1.2.1
-------------

- ![Enhancement][badge-enhancement] The package now uses `Downloads.download` instead of
  `Base.download` to download the space index files.
- ![Enhancement][badge-enhancement] Minor source-code updates.
- ![Enhancement][badge-enhancement] We updated the documentation.

Version 1.2.0
-------------

- ![Feature][badge-feature] We can pass the keyword `filepaths` to the function
  `SpaceIndices.init` when initializing individual sets to specify local files with the
  indices. Hence, the algorithm will use those paths instead of downloading the indices from
  the locations in `urls` function. (Issue [#6][gh-issue-6])

Verison 1.1.2
-------------

- ![Bugfix][badge-bugfix] We updated the URLs of the space indices related to the JB2008
  atmospheric model. (Issue [#5][gh-issue-5])

Version 1.1.1
-------------

- ![Bugfix][badge-bugfix] We can now process the file `SW-All.csv` if there are invalid
  lines. In those cases, the lines will be rejected. (Issue [#4][gh-issue-4])
- ![Enhancement][badge-enhancement] We now use the Julian Day instead of `DateTime` as the
  internal date representation. Notice that the public API has not changed. This
  modification made SpaceIndices.jl compatible with automatic differentiation packages.
  (PR [#3][gh-pr-3])
- ![Info][badge-info] The Kp and Ap vectors returned by `space_index` are now `Vector`s
  instead of `Tuple`s.

Version 1.1.0
-------------

- ![Enhancement][badge-enhancement] We now use the Celestrak file `SW-All.csv` to obtain
  some space indices such as the F10.7, Ap, and Kp. We also removed the old files
  `fluxtable.txt` and `Kp_ap_Ap_SN_F107_since_1932.txt`. Notice that this modification **is
  not considered** to be breaking because all indices can be fetched using the same
  functions (API). (PR [#2][gh-pr-2]))
- ![Feature][badge-feature] We added some other indices available in `SW-All.csv`.
  (PR [#2][gh-pr-2]))

Version 1.0.0
-------------

- ![BREAKING][badge-breaking] We renamed all the API and initialization functions to improve
  name consistency. Now, only the function `space_index` is exported. All others must be
  accessed using `SpaceIndices.` prefix.
- ![Feature][badge-feature] We added the following space index sets: `JB2008` and `KpAp`.
- ![Enhancement][badge-enhancement] We now re-export the modules `OptionalData` and `Dates`.
- ![Enhancement][badge-enhancement] We remove the dependency on **Interpolations.jl**
  because we only require simple interpolation algorithms (1D-constant and linear). Hence,
  we could implement fast algorithms inside the package, reducing the loading time.

Version 0.1.0
-------------

- Initial version.
  - This version was based on the code in **SatelliteToolbox.jl**. However, many API changes
    were implemented.

[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/Deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/Feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/Enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/Bugfix-purple.svg
[badge-info]: https://img.shields.io/badge/Info-gray.svg

[gh-issue-4]: https://github.com/JuliaSpace/SpaceIndices.jl/issues/4
[gh-issue-5]: https://github.com/JuliaSpace/SpaceIndices.jl/issues/5
[gh-issue-6]: https://github.com/JuliaSpace/SpaceIndices.jl/issues/6

[gh-pr-2]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/2
[gh-pr-3]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/3
[gh-pr-7]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/7
[gh-pr-9]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/9
[gh-pr-11]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/11
[gh-pr-12]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/12
