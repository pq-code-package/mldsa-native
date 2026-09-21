[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# RV32IM arithmetic backend

This directory contains the ML-DSA arithmetic backend for 32-bit RISC-V
implementations supporting the base integer and multiply extensions
(`RV32IM`) with the ILP32, ILP32F, and ILP32D family of ABIs.

The backend replaces the forward NTT, inverse NTT, and pointwise Montgomery
multiplication. When native arithmetic is enabled, `fastmul.h` is selected by
default on RV32IM targets. Integrators can select `slowmul.h` explicitly with
`MLD_CONFIG_ARITH_BACKEND_FILE`.

All hand-maintained code lives here. `scripts/autogen` preprocesses and
simplifies the assembly into `mldsa/src/native/rv32im/` and regenerates the
monolithic sources. Generated copies must not be edited directly.

The NTT and inverse NTT each have two profile selections around one shared
readable kernel body:

- `fastmul.h` uses an RV32M low multiply for the Barrett `t*q` step.
- `slowmul.h` selects shift/add wrappers that exploit `q = 2^23 - 2^13 + 1`.

Both variants use `mulh` and therefore still require RV32M. The alternative
only avoids an additional low multiply on implementations where that
operation is comparatively expensive.

Constant-time use requires the target's 32-bit multiplier to execute RV32M
`mul` and `mulh` with data-independent latency. RV32IM does not
architecturally guarantee this property, so integrators must establish it for
the selected core.

The assembly uses only integer registers, so it follows the integer calling
convention shared by ILP32, ILP32F, and ILP32D. Generation checks the source
as RV32IM/ILP32; linked tests inherit the target toolchain's compatible ABI.

There is no separate `_opt` source tree. The sources document their transform
schedule, modular arithmetic, and concrete bounds inline. HOL-Light proves
functional correctness, memory safety, and secret-independent execution for
both multiplier profiles. The timing result assumes that `mul` and `mulh`
have data-independent latency on the selected core.
