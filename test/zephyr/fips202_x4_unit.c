/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "src/fips202/keccakf1600.h"

#define KECCAK_RATE 136u

int main(void)
{
  MLD_ALIGN uint64_t state_x4[MLD_KECCAK_LANES * MLD_KECCAK_WAY];
  MLD_ALIGN uint64_t state_x1[MLD_KECCAK_LANES];
  MLD_ALIGN unsigned char input[MLD_KECCAK_WAY][KECCAK_RATE];
  MLD_ALIGN unsigned char output_x4[MLD_KECCAK_WAY][KECCAK_RATE];
  unsigned char output_x1[KECCAK_RATE];
  unsigned offset;
  unsigned lane;
  unsigned i;

  for (lane = 0; lane < MLD_KECCAK_WAY; lane++)
  {
    for (i = 0; i < KECCAK_RATE; i++)
    {
      input[lane][i] = (unsigned char)(17u * lane + i);
    }
  }

  /* The Armv8.1-M x4 helpers currently require word-aligned offsets and
   * buffers. Exercise every supported offset and compare with the x1 path. */
  for (offset = 0; offset < KECCAK_RATE; offset += 4)
  {
    unsigned length = KECCAK_RATE - offset;

    memset(state_x4, 0, sizeof(state_x4));
    mld_keccakf1600x4_xor_bytes(state_x4, input[0], input[1], input[2],
                                input[3], offset, length);
    mld_keccakf1600x4_permute(state_x4);
    mld_keccakf1600x4_extract_bytes(state_x4, output_x4[0], output_x4[1],
                                    output_x4[2], output_x4[3], 0, KECCAK_RATE);

    for (lane = 0; lane < MLD_KECCAK_WAY; lane++)
    {
      memset(state_x1, 0, sizeof(state_x1));
      mld_keccakf1600_xor_bytes(state_x1, input[lane], offset, length);
      mld_keccakf1600_permute(state_x1);
      mld_keccakf1600_extract_bytes(state_x1, output_x1, 0, KECCAK_RATE);
      if (memcmp(output_x4[lane], output_x1, KECCAK_RATE) != 0)
      {
        return 1;
      }
    }
  }

  return 0;
}

#undef KECCAK_RATE
