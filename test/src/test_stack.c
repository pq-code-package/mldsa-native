/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mldsa_native.h"

#include "test_namespace.h"

/*
 * We measure the internal deterministic entry points rather than the
 * randomized wrappers: they are available in every configuration, so the
 * same measurements are taken under reduced-API builds such as
 * MLD_CONFIG_NO_RANDOMIZED_API. The randomized wrappers merely add a seed
 * buffer and a randombytes() call on top.
 */
static void test_keygen_only(void)
{
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  unsigned char pk[MLDSA_PK_BYTES];
  unsigned char sk[MLDSA_SK_BYTES];
  unsigned char seed[MLDSA_SEEDBYTES] = {0};

  /* Only call keypair_internal - this is what we're measuring */
  /* seed is zero-initialized; its value is irrelevant for stack measurement */
  int ret = mld_sign_keypair_internal(pk, sk, seed);
  (void)ret; /* Ignore return value - we only care about stack measurement */
#else        /* !MLD_CONFIG_NO_KEYPAIR_API */
  printf("keygen test skipped (API disabled)\n");
#endif       /* MLD_CONFIG_NO_KEYPAIR_API */
}

static void test_sign_only(void)
{
#if !defined(MLD_CONFIG_NO_SIGN_API)
  unsigned char sk[MLDSA_SK_BYTES] = {0};
  unsigned char sig[MLDSA_SIG_BYTES];
  unsigned char rnd[MLDSA_RNDBYTES] = {0};
  const unsigned char msg[] = "test message for stack measurement";
  const unsigned char ctx[] = "test context";
  unsigned char pre[2 + sizeof(ctx) - 1];
  int ret;

  /* Prepare pre = (0, ctxlen, ctx) */
  pre[0] = 0;
  pre[1] = sizeof(ctx) - 1;
  memcpy(pre + 2, ctx, sizeof(ctx) - 1);

  /* Only call signature_internal - this is what we're measuring */
  /* sk is zero-initialized (invalid key, but OK for stack measurement) */
  ret = mld_sign_signature_internal(sig, msg, sizeof(msg) - 1, pre, sizeof(pre),
                                    rnd, sk, 0);
  (void)ret; /* Ignore return value - we only care about stack measurement */
#else        /* !MLD_CONFIG_NO_SIGN_API */
  printf("sign test skipped (API disabled)\n");
#endif       /* MLD_CONFIG_NO_SIGN_API */
}

static void test_verify_only(void)
{
#if !defined(MLD_CONFIG_NO_VERIFY_API)
  unsigned char pk[MLDSA_PK_BYTES] = {0};
  unsigned char sig[MLDSA_SIG_BYTES] = {0};
  const unsigned char msg[] = "test message for stack measurement";
  const unsigned char ctx[] = "test context";

  /* Only call verify - this is what we're measuring */
  /* pk and sig are zero-initialized (invalid, but OK for stack measurement) */
  int ret =
      mld_sign_verify(sig, msg, sizeof(msg) - 1, ctx, sizeof(ctx) - 1, pk);
  (void)ret; /* Ignore return value - we only care about stack measurement */
#else        /* !MLD_CONFIG_NO_VERIFY_API */
  printf("verify test skipped (API disabled)\n");
#endif       /* MLD_CONFIG_NO_VERIFY_API */
}

/* Prototype for a re-#define'd main, to satisfy -Wmissing-prototypes. */
#if defined(main)
int main(int argc, char *argv[]);
#endif
int main(int argc, char *argv[])
{
  if (argc != 2)
  {
    fprintf(stderr, "Usage: %s <keygen|sign|verify>\n", argv[0]);
    return 1;
  }

  if (strcmp(argv[1], "keygen") == 0)
  {
    test_keygen_only();
  }
  else if (strcmp(argv[1], "sign") == 0)
  {
    test_sign_only();
  }
  else if (strcmp(argv[1], "verify") == 0)
  {
    test_verify_only();
  }
  else
  {
    fprintf(stderr, "Unknown test: %s\n", argv[1]);
    return 1;
  }

  return 0;
}
