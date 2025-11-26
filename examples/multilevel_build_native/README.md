[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Multi-level build

This directory contains a minimal example for how to build mldsa-native with support for all 3 security levels
ML-DSA-44, ML-DSA-65, and ML-DSA-87. All level-independent code is shared, and native backends are in use.

The library is built 3 times in different build directories `build/mldsa{44,65,87}`. For the ML-DSA-44 build, we set
`MLD_CONFIG_MULTILEVEL_WITH_SHARED` to force the inclusion of all level-independent code in the
ML-DSA-44 build. For ML-DSA-65 and ML-DSA-87, we set `MLD_CONFIG_MULTILEVEL_NO_SHARED` to not include any
level-independent code. Finally, we use the common namespace prefix `mldsa` as `MLD_CONFIG_NAMESPACE_PREFIX` for all three
builds; the suffix 44/65/87 will be added to level-dependent functions automatically.

## Usage

Build this example with `make build`, run with `make run`.
