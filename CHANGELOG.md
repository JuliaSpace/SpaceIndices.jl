SpaceIndices.jl Changelog
=========================

Version 2.3.0
-------------

- ![Feature][badge-feature] We added the space index set `SatelliteToolboxSpaceIndexSets`,
  which provides the new index `F10predicted`: a long-term prediction of the F10.7 index
  computed using a harmonic model fitted to the observed data. The model coefficients are
  fitted daily in the repository [SatelliteToolboxSpaceIndexSets][stsis-repo].
- ![Enhancement][badge-enhancement] The remote files are now downloaded using up to three
  attempts with a delay between them, improving the resilience against transient network
  failures.
- ![Enhancement][badge-enhancement] If all the attempts to download a remote file fail but
  an old version exists in the local cache, the package now uses the cached file, logging
  a warning, instead of throwing an error. Additionally, a failed download no longer
  deletes the previously cached version of the file.
- ![Info][badge-info] We removed the index `DTC_Dst` from the documentation since it was
  removed from the package in v2.1.1.

Version 2.2.0
-------------

- ![Enhancement][badge-enhancement] The CelesTrak file parser now streams the file with
  typed parsing instead of using `readdlm`, substantially reducing the allocations during
  the initialization.
- ![Enhancement][badge-enhancement] The latest provisional Dst month is now cached. Hence,
  the initialization of the Dst space index set performs one network probe instead of
  three, and the file list seen by the API functions is always consistent.
- ![Enhancement][badge-enhancement] We removed type instabilities in the Hpo file parsers.
- ![Bugfix][badge-bugfix] We fixed a bug in the CelesTrak file parser that could silently
  delete the data of a day when the file contained duplicated or predicted-monthly entries.
- ![Bugfix][badge-bugfix] We fixed a bug in the JB2008 file parsers that threw a
  `BoundsError` when the files contained empty lines.
- ![Bugfix][badge-bugfix] We fixed a bug in the Hpo forecast merge that could associate
  data with the wrong day if the Hp30 and Hp60 forecast files had different date ranges.
- ![Bugfix][badge-bugfix] We fixed the macro `SpaceIndices.@data_handler`, which ignored
  its argument and only worked inside `SpaceIndices.@register` and `SpaceIndices.@object`.
- ![Info][badge-info] The package now requires JSON.jl v1 and no longer depends on
  DelimitedFiles.jl.
- ![Info][badge-info] We fixed many errors in the documentation, including wrong return
  types and signatures in docstrings.

Version 2.1.1
-------------

- ![Info][badge-info]: We are removing the DTC index that was built using the Dst data. Up
  to know, we do not know the license of the file DTCMAKEDR_AUTO.f provided by SET. When we
  obtain the license, we might revisit this decision. We are treating this removal as a bug
  fix.
- ![Enhancement][badge-enhancement] The algorithm to parse the Dst files were improved.

Version 2.1.0
-------------

- ![Feature][badge-feature] We added the support for the Dst index. (PR [#11][gh-pr-11])
- ![Enhancement][badge-enhancement] The differentiability tests were moved to an external
  package, leading to a huge reduction in the testing time of SpaceIndices.jl. (PR
  [#12][gh-pr-12])

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

[badge-breaking]: https://img.shields.io/badge/Breaking-DC2626?style=flat-square
[badge-deprecation]: https://img.shields.io/badge/Deprecation-D97706?style=flat-square
[badge-feature]: https://img.shields.io/badge/Feature-16A34A?style=flat-square
[badge-enhancement]: https://img.shields.io/badge/Enhancement-0284C7?style=flat-square
[badge-bugfix]: https://img.shields.io/badge/Bugfix-DB2777?style=flat-square
[badge-info]: https://img.shields.io/badge/Info-475569?style=flat-square

[stsis-repo]: https://github.com/JuliaSpace/SatelliteToolboxSpaceIndexSets

[gh-issue-4]: https://github.com/JuliaSpace/SpaceIndices.jl/issues/4
[gh-issue-5]: https://github.com/JuliaSpace/SpaceIndices.jl/issues/5
[gh-issue-6]: https://github.com/JuliaSpace/SpaceIndices.jl/issues/6

[gh-pr-2]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/2
[gh-pr-3]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/3
[gh-pr-7]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/7
[gh-pr-9]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/9
[gh-pr-11]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/11
[gh-pr-12]: https://github.com/JuliaSpace/SpaceIndices.jl/pull/12
