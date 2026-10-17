[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Standard Library Dependencies

mldsa-native has minimal dependencies on the C standard library. This document lists all stdlib functions used and configuration options for custom replacements.

## Dependencies

### Memory Functions
- **memcpy**: Used extensively for copying data structures, keys, and intermediate values
- **memset**: Used for zeroing state structures and buffers. It need not be hardened against compiler optimization: security-critical zeroing goes through `mld_zeroize`, which can be replaced via `MLD_CONFIG_CUSTOM_ZEROIZE`. Its default implementation may use `memset`, but follows it with a compiler barrier so that the zeroing is not optimized away

### Debug Functions (MLDSA_DEBUG builds only)
- **fprintf**: Used in debug.c for error reporting to stderr
- **exit**: Used in debug.c to terminate on assertion failures

## Custom Replacements

Custom replacements can be provided for memory functions using the configuration options in `mldsa/mldsa_native_config.h`:

### MLD_CONFIG_CUSTOM_MEMCPY
Replaces all `memcpy` calls with a custom implementation. When enabled, you must define a `mld_memcpy` function with the same signature as the standard `memcpy`.

### MLD_CONFIG_CUSTOM_MEMSET
Replaces all `memset` calls with a custom implementation. When enabled, you must define a `mld_memset` function with the same signature as the standard `memset`.

See the configuration examples in `mldsa/mldsa_native_config.h` and test configurations in `test/configs/custom_*_config.h` for usage examples and implementation requirements.
