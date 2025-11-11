[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Multi-level mldsa-native in a single compilation unit

This directory contains a minimal example for how to build multiple instances of mldsa-native in a single compilation
unit. Only the C-backend is exercised.

The auto-generated source file [mldsa_native.c](mldsa/mldsa_native.c) includes all mldsa-native C source
files. Moreover, it clears all `#define`s clauses set by mldsa-native at the end, and is hence amenable to multiple
inclusion in another compilation unit.

The manually written source file [mldsa_native_all.c](mldsa_native_all.c) includes
[mldsa_native.c](mldsa/mldsa_native.c) three times, each time using the fixed config
[multilevel_config.h](multilevel_config.h), but changing the security level (specified
by `MLD_CONFIG_PARAMETER_SET`) every time.
```C
#define MLD_CONFIG_FILE "multilevel_config.h"

/* Three instances of mldsa-native for all security levels */

/* Include level-independent code */
#define MLD_CONFIG_MULTILEVEL_WITH_SHARED
/* Keep level-independent headers at the end of monobuild file */
#define MLD_CONFIG_MONOBUILD_KEEP_SHARED_HEADERS
#define MLD_CONFIG_PARAMETER_SET 44
#include "mldsa_native.c"
#undef MLD_CONFIG_PARAMETER_SET
#undef MLD_CONFIG_MULTILEVEL_WITH_SHARED

/* Exclude level-independent code */
#define MLD_CONFIG_MULTILEVEL_NO_SHARED
#define MLD_CONFIG_PARAMETER_SET 65
#include "mldsa_native.c"
#undef MLD_CONFIG_PARAMETER_SET
/* `#undef` all headers at the and of the monobuild file */
#undef MLD_CONFIG_MONOBUILD_KEEP_SHARED_HEADERS

#define MLD_CONFIG_PARAMETER_SET 87
#include "mldsa_native.c"
#undef MLD_CONFIG_PARAMETER_SET
```

Note the setting `MLD_CONFIG_MULTILEVEL_WITH_SHARED` which forces the inclusion of all level-independent
code in the MLDSA-44 build, and the setting `MLD_CONFIG_MULTILEVEL_NO_SHARED`, which drops all
level-independent code in the subsequent builds. Finally, `MLD_CONFIG_MONOBUILD_KEEP_SHARED_HEADERS` entails that
`mldsa_native.c` does not `#undefine` the `#define` clauses from level-independent files.

To make the monolithic multi-level build accessible from the application source [main.c](main.c), we provide
[mldsa_native_all.h](mldsa_native_all.h), which includes [mldsa_native.h](../../mldsa/mldsa_native.h) once per
configuration. Note that we don't refer to the configuration using `MLD_CONFIG_FILE`, but by setting
`MLD_CONFIG_API_XXX` explicitly. Otherwise, [mldsa_native.h](../../mldsa/mldsa_native.h) would include the confg, which
would lead to name-clashes upon multiple use.

```C
#define MLD_CONFIG_API_NO_SUPERCOP

/* API for MLDSA-44 */
#define MLD_CONFIG_API_PARAMETER_SET 44
#define MLD_CONFIG_API_NAMESPACE_PREFIX mldsa44
#include <mldsa_native.h>
#undef MLD_CONFIG_API_PARAMETER_SET
#undef MLD_CONFIG_API_NAMESPACE_PREFIX
#undef MLD_H

/* API for MLDSA-65*/
#define MLD_CONFIG_API_PARAMETER_SET 65
#define MLD_CONFIG_API_NAMESPACE_PREFIX mldsa65
#include <mldsa_native.h>
#undef MLD_CONFIG_API_PARAMETER_SET
#undef MLD_CONFIG_API_NAMESPACE_PREFIX
#undef MLD_H

/* API for MLDSA-87 */
#define MLD_CONFIG_API_PARAMETER_SET 87
#define MLD_CONFIG_API_NAMESPACE_PREFIX mldsa87
#include <mldsa_native.h>
#undef MLD_CONFIG_API_PARAMETER_SET
#undef MLD_CONFIG_API_NAMESPACE_PREFIX
#undef MLD_H
```

## Usage

Build this example with `make build`, run with `make run`.

**WARNING:** The `randombytes()` implementation used here is for TESTING ONLY. You MUST NOT use this implementation
outside of testing.
