[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Isabelle/HOL Proofs

This directory collects the Isabelle/HOL developments shipped with
`mldsa-native`:

- [`compress/`](compress) — Barrett-division proofs for ML-DSA's `Decompose`.
- [`neon_ntt/`](neon_ntt) — formalisation of the modular-arithmetic kernels
  from the "Neon NTT" paper.

Each subdirectory has its own `README.md` and `Makefile` describing how to
build that particular development. This page only covers how to obtain
Isabelle itself.

## Installing Isabelle

Both developments need the `isabelle` tool. The subdirectory Makefiles locate
it via three variables:

- `ISABELLE_HOME` — the directory containing the `isabelle` binary.
- `ISABELLE_DIR` — the distribution root (queried as `$(ISABELLE_DIR)/bin/isabelle`).
- `ISABELLE_VERSION` — the version string, e.g. `Isabelle2025-2`.

By default these point at the macOS `Isabelle2025-2.app` install layout. On
other platforms, or for a different version, override them on the `make`
command line.

### Official release (recommended)

Download Isabelle from <https://isabelle.in.tum.de/> and install it following
the platform instructions there. The developments above are tested with
`Isabelle2025-2`.
Then either put the `isabelle` binary on your `PATH`, or point the Makefile
variables at your install, e.g.:

```
make ISABELLE_VERSION=Isabelle2025-2 \
     ISABELLE_HOME=/path/to/Isabelle2025-2/bin
```

### nix shell

The flake provides an `isabelle` devShell that pulls Isabelle from nixpkgs and
exports `ISABELLE_VERSION`, `ISABELLE_HOME`, and `ISABELLE_DIR` for you:

```
nix develop .#isabelle
```

It also bundles the TeX distribution that Isabelle needs to typeset the
NeonNTT PDF, so the subdirectory Makefiles work without any further
configuration:

```
cd proofs/isabelle/neon_ntt && make
cd proofs/isabelle/compress  && make
```
