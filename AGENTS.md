# AGENTS.md

SpaceIndices.jl is a Julia package to fetch and parse space indices (F10.7, Kp, Ap, Dst, etc.) from remote providers (Celestrak, GFZ, JB2008 data files, WDC Kyoto).

## Package Structure

- Requires Julia 1.10, 1.11, or 1.12 (`[compat] julia = "1.10, 1.11, 1.12"` in `Project.toml`).
- Entrypoint is `src/SpaceIndices.jl`. Include order matters: `types.jl` first, then the constant `_SPACE_INDEX_SETS`, then `api.jl`, `destroy.jl`, `download.jl`, `initialize.jl`, `interpolations.jl`, `misc.jl`, and finally the index-set implementations in `src/space_index_sets/` (`jb2008.jl`, `celestrak.jl`, `hpo.jl`, `dst.jl`). New code can only reference symbols defined in earlier includes.
- Each space index set is a `SpaceIndexSet` subtype implementing the API documented in `src/API.md` (`urls`, `expiry_periods`, `parse_files`, `get_url_filenames`, index accessors). Read `src/API.md` before adding or modifying an index set.
- `Dates` and `OptionalData` are `@reexport`ed, so their symbols are part of this package's public surface.
- Test dependencies are declared via `[extras]` + `[targets]` in `Project.toml` (`Test`, `DelimitedFiles`, `Logging`, `Pkg`). There is no `test/Project.toml`.
- Tests do NOT mirror `src/` one-to-one. `test/runtests.jl` includes `performance.jl` (Aqua, JET, AllocCheck — gated to non-prerelease Julia and installed via `Pkg.add` at test time), `initialization.jl`, `space_indices.jl`, `api.jl`, and `interpolations.jl`. `test/SW-All.csv` is a local data fixture.
- A committed `Manifest.toml` pins the dependency tree exactly.
- No package extensions (`ext/` does not exist).

## Commands

- Instantiate: `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
- Full test suite: `julia --project=. -e 'using Pkg; Pkg.test()'`
- Focused test file: `julia --project=. -e 'using SpaceIndices, Test, DelimitedFiles, Logging, Scratch; include("test/<file>.jl")'` — note `DelimitedFiles` and `Logging` are test-only deps, so this fails unless they resolve from your default environment; when in doubt, run the full `Pkg.test()`. `performance.jl` additionally needs Aqua, JET, and AllocCheck.
- Format: `julia -e 'using JuliaFormatter; format(".")'` — no `--project=.`; JuliaFormatter is not a project dependency and must be available in your default environment.
- Build docs: `julia --project=docs docs/make.jl` (first local run: `julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'`). Add `local` to ARGS for local-friendly URLs: `julia --project=docs docs/make.jl local`.
- Tests download index files from the internet and cache them via Scratch.jl — they need network access. Use generous timeouts: slow startup is precompilation, not a hang.

## CI

- `ci.yml`: Julia 1.10 and latest stable on Linux x64, macOS arm64, and Windows x64; buildpkg → runtest → coverage upload to Codecov.
- `ci-nightly.yml`: Julia nightly on the same OS/arch matrix (performance tests are skipped on prerelease Julia by `runtests.jl`).
- `docs.yml`: builds and deploys documentation via `julia-docdeploy`.
- There is NO format-check job — formatting is by convention, not enforced by CI.

## Code Style

- Formatting follows `.JuliaFormatter.toml`: Blue style with alignment options enabled (`align_assignment`, `align_conditional`, `align_matrix`, `align_pair_arrow`, `align_struct_field`) and `whitespace_in_kwargs = true`. That file is the source of truth.
- Source files start with a `## Description ###...` boxed header comment; section separators use `####...` boxed banners. Match this in new files.
- Test files use `@testset "Name" verbose = true begin ... end` at the top level of `runtests.jl`.

## Behavioral Constraints

- `SpaceIndices.init()` initializes all registered sets EXCEPT `Dst` (excluded by default); tests rely on this. `SpaceIndices.destroy()` resets global state — call it between tests that depend on initialization state.
- Public index access goes through `space_index(Val(:Name), instant)`; the full symbol list is enumerated in `_INDICES` in `test/runtests.jl`. Adding an index means updating that list too.
- Performance is a tested property: `AllocCheck` asserts zero allocations for `space_index` calls. Avoid introducing allocations in the index-access hot path.

## Not Configured

- No linter config, no pre-commit hooks, no `deps/build.jl` (`Pkg.build()` is a no-op), no test-name selector (no TestItemRunner/ARGS handling) — do not invent these.
