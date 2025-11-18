[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Multi-level mldsa-native in a single compilation unit, with native code

This directory contains a minimal example for how to build multiple instances of mldsa-native in a single compilation
unit, while additionally linking assembly sources from native code.

The auto-generated source file [mldsa_native.c](mldsa/mldsa_native.c) includes all mldsa-native C source
files. Moreover, it clears all `#define`s clauses set by mldsa-native at the end, and is hence amenable to multiple
inclusion in another compilation unit.

The manually written source file [mldsa_native_all.c](mldsa_native_all.c) includes
[mldsa_native.c](mldsa/mldsa_native.c) three times, each time using the fixed config
[multilevel_config.h](multilevel_config.h), but changing the security level (specified
by `MLD_CONFIG_PARAMETER_SET`) every time. For each inclusion, it sets `MLD_CONFIG_FILE`
appropriately first, and then includes the monobuild:
```C
/* Three instances of mldsa-native for all security levels */

#define MLD_CONFIG_FILE "multilevel_config.h"

/* Include level-independent code */
#define MLD_CONFIG_MULTILEVEL_WITH_SHARED 1
/* Keep level-independent headers at the end of monobuild file */
#define MLD_CONFIG_MONOBUILD_KEEP_SHARED_HEADERS
#define MLD_CONFIG_PARAMETER_SET 44
#include "mldsa_native.c"
#undef MLD_CONFIG_MULTILEVEL_WITH_SHARED
#undef MLD_CONFIG_PARAMETER_SET

/* Exclude level-independent code */
#define MLD_CONFIG_MULTILEVEL_NO_SHARED
#define MLD_CONFIG_PARAMETER_SET 65
#include "mldsa_native.c"
/* `#undef` all headers at the and of the monobuild file */
#undef MLD_CONFIG_MONOBUILD_KEEP_SHARED_HEADERS
#undef MLD_CONFIG_PARAMETER_SET

#define MLD_CONFIG_PARAMETER_SET 87
#include "mldsa_native.c"
#undef MLD_CONFIG_PARAMETER_SET
```

Note the setting `MLD_CONFIG_MULTILEVEL_WITH_SHARED` which forces the inclusion of all level-independent
code in the ML_DSA-44 build, and the setting `MLD_CONFIG_MULTILEVEL_NO_SHARED`, which drops all
level-independent code in the subsequent builds. Finally, `MLD_CONFIG_MONOBUILD_KEEP_SHARED_HEADERS` entails that
[mldsa_native.c](mldsa/mldsa_native.c) does not `#undefine` the `#define` clauses from level-independent files.

Since we embed [mldsa_native_all.c](mldsa_native_all.c) directly into the application source [main.c](main.c), we don't
need a header for function declarations. However, we still import [mldsa_native.h](../../mldsa/mldsa_native.h) once
with `MLD_CONFIG_API_CONSTANTS_ONLY`, for definitions of the sizes of the key material and signatures.
Excerpt from [main.c](main.c):

```c
#include "mldsa_native_all.c"

#define MLD_CONFIG_API_CONSTANTS_ONLY
#include <mldsa_native.h>
```

## Usage

Build this example with `make build`, run with `make run`.

**WARNING:** The `randombytes()` implementation used here is for TESTING ONLY. You MUST NOT use this implementation
outside of testing.
