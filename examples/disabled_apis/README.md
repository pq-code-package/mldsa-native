[//]: # (SPDX-License-Identifier: CC-BY-4.0)

# Disabled APIs

This directory tests building mldsa-native with individual APIs disabled
via `MLD_CONFIG_NO_KEYPAIR_API`, `MLD_CONFIG_NO_SIGN_API`, and
`MLD_CONFIG_NO_VERIFY_API`.

## Use Case

Use these configuration options when you only need a subset of ML-DSA
functionality and want to minimize code size.

## What is tested

For each parameter set (44, 65, 87), the following configurations are
built and tested:

- **keygen_only**: `MLD_CONFIG_NO_SIGN_API` + `MLD_CONFIG_NO_VERIFY_API`
- **sign_only**: `MLD_CONFIG_NO_KEYPAIR_API` + `MLD_CONFIG_NO_VERIFY_API`
- **verify_only**: `MLD_CONFIG_NO_KEYPAIR_API` + `MLD_CONFIG_NO_SIGN_API`
- **sign_verify**: `MLD_CONFIG_NO_KEYPAIR_API`

## Usage

```bash
make build   # Build all 12 variants
make run     # Run all 12 variants
```
