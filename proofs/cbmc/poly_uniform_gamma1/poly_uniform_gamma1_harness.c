// Copyright (c) The mldsa-native project authors
// SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

#include "poly_kl.h"

void harness(void)
{
/* mld_poly_uniform_gamma1 is only defined for ML-DSA-65 and with
 * MLD_CONFIG_REDUCE_RAM (or MLD_CONFIG_SERIAL_FIPS202_ONLY, see
 * poly_uniform_gamma1_serial) */
#if MLD_CONFIG_PARAMETER_SET == 65 || defined(MLD_CONFIG_REDUCE_RAM)
  mld_poly *a;
  const uint8_t *seed;
  uint16_t nonce;

  mld_poly_uniform_gamma1(a, seed, nonce);
#endif /* MLD_CONFIG_PARAMETER_SET == 65 || MLD_CONFIG_REDUCE_RAM */
}
