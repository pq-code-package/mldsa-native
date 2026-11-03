# Armv8.1-M MVE arithmetic

This opt-in backend accelerates pointwise Montgomery multiplication, norm checks,
and use-hint for ML-DSA-65/87. ML-DSA-44 keeps the C /88 use-hint path; NTT,
inverse NTT, sampling and other operations keep their existing C fallbacks.
It supports fixed-level and shared multilevel builds without polynomial scratch
buffers. It requires an MVE target, for example `-mcpu=cortex-m55 -mthumb`.

Select it through the existing configuration:

```c
#define MLD_CONFIG_USE_NATIVE_BACKEND_ARITH
#define MLD_CONFIG_ARITH_BACKEND_FILE "native/armv81m/meta.h"
```

Optionally define `MLD_ARMV81M_USE_MVE_MEMOPS` to select the byte-tail-predicated
copy, set and zeroize helpers. These accept arbitrary byte lengths and unaligned
byte pointers; copy has the usual non-overlap requirement. This option replaces
all three corresponding standard memory hooks; combining it with custom hook
implementations is rejected. It needs no forced architecture
macro. It can also be selected without this arithmetic backend.

For reduced-RAM four-row verification, define `MLD_CONFIG_REDUCE_RAM` and
`MLD_CONFIG_REDUCE_RAM_X4`. To use the x4 extraction optimisation, select the
existing FIPS202 backend separately:

```c
#define MLD_CONFIG_USE_NATIVE_BACKEND_FIPS202
#define MLD_CONFIG_FIPS202_BACKEND_FILE "fips202/native/armv81m/mve.h"
```

Compile the normal `mldsa_native.c` and `mldsa_native_asm.S` units, or include
all relevant individual sources. Canonical arithmetic sources are maintained in
`dev/armv81m`; regenerate the production files with
`scripts/autogen --force-cross armv81m`.

The 14.38% ML-DSA-87 verification gain measured during research belongs to a
separate frozen benchmark overlay with additional NTT, sampling and Keccak
implementations. It is not a cycle claim for this smaller modular port.
