/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Wycheproof test driver for ML-DSA.
 *
 * Usage:
 * wycheproof_mldsa{lvl} keygen_seed seed=HEX
 * wycheproof_mldsa{lvl} sign msg=HEX sk=HEX ctx=HEX
 * wycheproof_mldsa{lvl} sign_internal mu=HEX sk=HEX
 * wycheproof_mldsa{lvl} verify msg=HEX ctx=HEX sig=HEX pk=HEX
 * wycheproof_mldsa{lvl} verify_internal mu=HEX sig=HEX pk=HEX
 */

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../mldsa/src/common.h"

#include "../../mldsa/mldsa_native.h"

#define crypto_sign_keypair_internal MLD_API_NAMESPACE(keypair_internal)
#define crypto_sign_signature_internal MLD_API_NAMESPACE(signature_internal)
#define crypto_sign_verify_internal MLD_API_NAMESPACE(verify_internal)
#define crypto_sign_verify_extmu MLD_API_NAMESPACE(verify_extmu)

#define MAX_MSG_LENGTH 8192
#define MAX_CTX_LENGTH 255
#define MU_LENGTH 64

#define CHECK(x)                                              \
  do                                                          \
  {                                                           \
    int rc;                                                   \
    rc = (x);                                                 \
    if (!rc)                                                  \
    {                                                         \
      fprintf(stderr, "ERROR (%s,%d)\n", __FILE__, __LINE__); \
      exit(1);                                                \
    }                                                         \
  } while (0)

static unsigned char decode_hex_char(char hex)
{
  if (hex >= '0' && hex <= '9')
  {
    return (unsigned char)(hex - '0');
  }
  else if (hex >= 'A' && hex <= 'F')
  {
    return (unsigned char)(10 + (unsigned char)(hex - 'A'));
  }
  else if (hex >= 'a' && hex <= 'f')
  {
    return (unsigned char)(10 + (unsigned char)(hex - 'a'));
  }
  else
  {
    return 0xFF;
  }
}

static int decode_hex(const char *prefix, unsigned char *out, size_t out_len,
                      const char *hex)
{
  size_t i;
  size_t hex_len = strlen(hex);
  size_t prefix_len = strlen(prefix);

  if (hex_len < prefix_len + 1 || memcmp(prefix, hex, prefix_len) != 0 ||
      hex[prefix_len] != '=')
  {
    return 1;
  }

  hex += prefix_len + 1;
  hex_len -= prefix_len + 1;

  if (hex_len != 2 * out_len)
  {
    return 1;
  }

  for (i = 0; i < out_len; i++, hex += 2, out++)
  {
    unsigned hex0 = decode_hex_char(hex[0]);
    unsigned hex1 = decode_hex_char(hex[1]);
    if (hex0 == 0xFF || hex1 == 0xFF)
    {
      return 1;
    }
    *out = (unsigned char)((hex0 << 4) | hex1);
  }
  return 0;
}

static void print_hex(const char *name, const unsigned char *raw, size_t len)
{
  if (name != NULL)
  {
    printf("%s=", name);
  }
  for (; len > 0; len--, raw++)
  {
    printf("%02X", *raw);
  }
  printf("\n");
}

int main(int argc, char *argv[])
{
  if (argc < 2)
  {
    goto usage;
  }

  if (strcmp(argv[1], "keygen_seed") == 0)
  {
    unsigned char seed[MLDSA_SEEDBYTES];
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];

    if (argc != 3 || decode_hex("seed", seed, sizeof(seed), argv[2]) != 0)
    {
      printf("decode_error=for seed\n");
      return 0;
    }

    CHECK(crypto_sign_keypair_internal(pk, sk, seed) == 0);
    print_hex("sk", sk, sizeof(sk));
  }
  else if (strcmp(argv[1], "sign") == 0)
  {
    unsigned char msg[MAX_MSG_LENGTH];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char ctx[MAX_CTX_LENGTH];
    unsigned char sig[CRYPTO_BYTES];
    size_t mlen = 0, ctxlen = 0, siglen = 0;
    unsigned char rnd[MLDSA_SEEDBYTES] = {0};
    unsigned char pre[MAX_CTX_LENGTH + 2];

    if (argc != 5)
    {
      goto usage;
    }

    mlen = (strlen(argv[2]) - strlen("msg=")) / 2;
    if (mlen > MAX_MSG_LENGTH || decode_hex("msg", msg, mlen, argv[2]) != 0)
    {
      printf("decode_error=for msg or mlen incorrect\n");
      return 0;
    }
    if (decode_hex("sk", sk, sizeof(sk), argv[3]) != 0)
    {
      printf("decode_error=for sk\n");
      return 0;
    }

    ctxlen = (strlen(argv[4]) - strlen("ctx=")) / 2;
    if (ctxlen > MAX_CTX_LENGTH || decode_hex("ctx", ctx, ctxlen, argv[4]) != 0)
    {
      printf("decode_error=for ctx or ctxlen incorrect\n");
      return 0;
    }

    pre[0] = 0;
    pre[1] = (uint8_t)ctxlen;
    if (ctxlen > 0)
    {
      memcpy(pre + 2, ctx, ctxlen);
    }

    CHECK(crypto_sign_signature_internal(sig, &siglen, msg, mlen, pre,
                                         ctxlen + 2, rnd, sk, 0) == 0);
    print_hex("sig", sig, siglen);
  }
  else if (strcmp(argv[1], "sign_internal") == 0)
  {
    unsigned char mu[MU_LENGTH];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char sig[CRYPTO_BYTES];
    size_t mulen = 0, siglen = 0;
    unsigned char rnd[MLDSA_SEEDBYTES] = {0};

    if (argc != 4)
    {
      goto usage;
    }

    mulen = (strlen(argv[2]) - strlen("mu=")) / 2;
    if (mulen != MU_LENGTH || decode_hex("mu", mu, mulen, argv[2]) != 0)
    {
      printf("decode_error=for mu or mulen incorrect\n");
      return 0;
    }
    if (decode_hex("sk", sk, sizeof(sk), argv[3]) != 0)
    {
      printf("decode_error=for sk\n");
      return 0;
    }

    CHECK(crypto_sign_signature_internal(sig, &siglen, mu, mulen, NULL, 0, rnd,
                                         sk, 1) == 0);
    print_hex("sig", sig, siglen);
  }
  else if (strcmp(argv[1], "verify") == 0)
  {
    unsigned char msg[MAX_MSG_LENGTH];
    unsigned char ctx[MAX_CTX_LENGTH];
    unsigned char sig[CRYPTO_BYTES];
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    size_t mlen = 0, ctxlen = 0;
    int res;

    if (argc != 6)
    {
      goto usage;
    }

    mlen = (strlen(argv[2]) - strlen("msg=")) / 2;
    if (mlen > MAX_MSG_LENGTH || decode_hex("msg", msg, mlen, argv[2]) != 0)
    {
      printf("decode_error=for msg or mlen incorrect\n");
      return 0;
    }
    ctxlen = (strlen(argv[3]) - strlen("ctx=")) / 2;
    if (ctxlen > MAX_CTX_LENGTH || decode_hex("ctx", ctx, ctxlen, argv[3]) != 0)
    {
      printf("decode_error=for ctx or ctxlen incorrect\n");
      return 0;
    }
    if (decode_hex("sig", sig, sizeof(sig), argv[4]) != 0)
    {
      printf("decode_error=for sig\n");
      return 0;
    }
    if (decode_hex("pk", pk, sizeof(pk), argv[5]) != 0)
    {
      printf("decode_error=for pk\n");
      return 0;
    }

    res = crypto_sign_verify(sig, sizeof(sig), msg, mlen, ctx, ctxlen, pk);
    printf("testPassed=%d\n", (res == 0) ? 1 : 0);
  }
  else if (strcmp(argv[1], "verify_internal") == 0)
  {
    unsigned char mu[MU_LENGTH];
    unsigned char sig[CRYPTO_BYTES];
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    size_t mulen = 0;
    int res;

    if (argc != 5)
    {
      goto usage;
    }

    mulen = (strlen(argv[2]) - strlen("mu=")) / 2;
    if (mulen != MU_LENGTH || decode_hex("mu", mu, mulen, argv[2]) != 0)
    {
      printf("decode_error=for mu or mulen incorrect\n");
      return 0;
    }
    if (decode_hex("sig", sig, sizeof(sig), argv[3]) != 0)
    {
      printf("decode_error=for sig\n");
      return 0;
    }
    if (decode_hex("pk", pk, sizeof(pk), argv[4]) != 0)
    {
      printf("decode_error=for pk\n");
      return 0;
    }

    res = crypto_sign_verify_extmu(sig, sizeof(sig), mu, pk);
    printf("testPassed=%d\n", (res == 0) ? 1 : 0);
  }
  else
  {
    goto usage;
  }

  return 0;

usage:
  fprintf(stderr,
          "Usage:\n"
          "  wycheproof_mldsa{lvl} keygen_seed seed=HEX\n"
          "  wycheproof_mldsa{lvl} sign msg=HEX sk=HEX ctx=HEX\n"
          "  wycheproof_mldsa{lvl} sign_internal mu=HEX sk=HEX\n"
          "  wycheproof_mldsa{lvl} verify msg=HEX ctx=HEX sig=HEX pk=HEX\n"
          "  wycheproof_mldsa{lvl} verify_internal mu=HEX sig=HEX pk=HEX\n");

  return 1;
}
