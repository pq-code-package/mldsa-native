[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# FIPS202 backend for Armv8.1-M + MVE: Development sources

This directory contains the development sources for a FIPS202 backend targeting
the Armv8.1-M + MVE/Helium architecture.

The scalar x1 Keccak-f[1600] permutation is adapted from the bit-interleaved
Armv7-M implementation by Adomnicai/XKCP distributed with SLOTHY. The x1
XOR/extract hooks convert bytes on the fly so the state remains bit-interleaved
between permutations.

**Warning:** This backend is still in active development and has not yet undergone
the same level of review as the rest of the code. Use at your own risk!
