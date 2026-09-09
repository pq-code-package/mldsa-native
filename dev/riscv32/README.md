[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# RV32IM arithmetic backend

This directory contains the experimental ML-DSA arithmetic backend for
32-bit RISC-V implementations supporting the base integer and multiply
extensions (`RV32IM`) with the ILP32, ILP32F, and ILP32D family of ABIs for
RV32-IM.

The backend replaces the forward NTT, inverse NTT, and pointwise Montgomery
multiplication. It is not selected automatically; integrators must define
`MLD_CONFIG_USE_NATIVE_BACKEND_ARITH` and set
`MLD_CONFIG_ARITH_BACKEND_FILE` to `native/rv32im/meta.h`.

All hand-maintained code lives here. `scripts/autogen` preprocesses and
simplifies the assembly into `mldsa/src/native/rv32im/` and regenerates the
monolithic sources. Generated copies must not be edited directly.

The NTT and inverse NTT each have two wrappers around one shared readable
kernel body:

- The default wrappers use an RV32M low multiply for the Barrett `t*q` step.
- Defining `MLD_USE_NATIVE_RV32IM_SLOW_MULTIPLIER` selects shift/add wrappers
  that exploit `q = 2^23 - 2^13 + 1`.

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
schedule, modular arithmetic, and concrete bounds inline. Functional and
ILP32 ABI checks cover the generated code, but this backend currently has no
formal proof.
