/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*
 * Wycheproof test driver for ML-DSA.
 *
 * Usage:
 *   wycheproof_mldsa{lvl} sigGenSeedDeterministic seed=HEX message=HEX
 * context=HEX externalMu=0/1 wycheproof_mldsa{lvl} sigGenDeterministic
 * message=HEX context=HEX sk=HEX wycheproof_mldsa{lvl}
 * sigGenInternalDeterministic message=HEX sk=HEX externalMu=0/1
 *   wycheproof_mldsa{lvl} sigVer message=HEX context=HEX signature=HEX pk=HEX
 *   wycheproof_mldsa{lvl} pkFromSk sk=HEX
 */

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../mldsa/src/common.h"

#include "../../mldsa/mldsa_native.h"

/* Additional SUPERCOP-style macros for functions not in the standard set */
#define crypto_sign_keypair_internal MLD_API_NAMESPACE(keypair_internal)
#define crypto_sign_signature_internal MLD_API_NAMESPACE(signature_internal)
#define crypto_sign_pk_from_sk MLD_API_NAMESPACE(pk_from_sk)

/* maximum message length used in the Wycheproof tests */
#define MAX_MSG_LENGTH 8192
/* maximum context length according to FIPS-204 */
#define MAX_CTX_LENGTH 255

/* Print supported API modes and exit (used by wycheproof_client.py) */
static void print_info(void)
{
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  printf("keyGen\n");
  printf("pkFromSk\n");
#endif
#if !defined(MLD_CONFIG_NO_SIGN_API)
  printf("sigGen\n");
#endif
#if !defined(MLD_CONFIG_NO_VERIFY_API)
  printf("sigVer\n");
#endif
}

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

#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API) || \
    !defined(MLD_CONFIG_NO_KEYPAIR_API)
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
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API || \
          !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_KEYPAIR_API)
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
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_KEYPAIR_API */

/* Prototype for a re-#define'd main, to satisfy -Wmissing-prototypes. */
#if defined(main)
int main(int argc, char *argv[]);
#endif
int main(int argc, char *argv[])
{
  if (argc < 2)
  {
    goto usage;
  }

  if (strcmp(argv[1], "--info") == 0)
  {
    print_info();
    return 0;
  }

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) && !defined(MLD_CONFIG_NO_SIGN_API)
  if (strcmp(argv[1], "sigGenSeedDeterministic") == 0)
  {
    /* sigGenSeedDeterministic seed=HEX message=HEX context=HEX externalMu=0/1
     *
     * Derives sk from seed, then deterministically signs message.
     * If externalMu=1, message is the 64-byte mu and context is ignored. */
    unsigned char seed[MLDSA_SEEDBYTES];
    unsigned char message[MAX_MSG_LENGTH + MAX_CTX_LENGTH + 2];
    unsigned char context[MAX_CTX_LENGTH];
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char sig[CRYPTO_BYTES];
    unsigned char pre[MAX_CTX_LENGTH + 2];
    unsigned char rnd[MLDSA_RNDBYTES] = {0};
    size_t mlen, ctxlen, siglen;
    int externalMu;

    if (argc != 6)
    {
      goto usage;
    }

    if (decode_hex("seed", seed, sizeof(seed), argv[2]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    mlen = (strlen(argv[3]) - strlen("message=")) / 2;
    if (mlen > sizeof(message) ||
        decode_hex("message", message, mlen, argv[3]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    ctxlen = (strlen(argv[4]) - strlen("context=")) / 2;
    if (ctxlen > MAX_CTX_LENGTH ||
        decode_hex("context", context, ctxlen, argv[4]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    if (strcmp(argv[5], "externalMu=0") == 0)
    {
      externalMu = 0;
    }
    else if (strcmp(argv[5], "externalMu=1") == 0)
    {
      externalMu = 1;
    }
    else
    {
      printf("decode_error=1\n");
      return 0;
    }

    CHECK(crypto_sign_keypair_internal(pk, sk, seed) == 0);

    if (externalMu)
    {
      CHECK(crypto_sign_signature_internal(sig, &siglen, message, mlen, NULL, 0,
                                           rnd, sk, 1) == 0);
    }
    else
    {
      pre[0] = 0;
      /* Safety: Truncation is safe due to the check above. */
      pre[1] = (uint8_t)ctxlen;
      memcpy(pre + 2, context, ctxlen);
      CHECK(crypto_sign_signature_internal(sig, &siglen, message, mlen, pre,
                                           ctxlen + 2, rnd, sk, 0) == 0);
    }
    print_hex("signature", sig, siglen);
  }
  else
#endif /* !MLD_CONFIG_NO_KEYPAIR_API && !MLD_CONFIG_NO_SIGN_API */
#if !defined(MLD_CONFIG_NO_SIGN_API)
      if (strcmp(argv[1], "sigGenDeterministic") == 0)
  {
    /* sigGenDeterministic message=HEX context=HEX sk=HEX */
    unsigned char message[MAX_MSG_LENGTH];
    unsigned char context[MAX_CTX_LENGTH];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char sig[CRYPTO_BYTES];
    unsigned char pre[MAX_CTX_LENGTH + 2];
    unsigned char rnd[MLDSA_RNDBYTES] = {0};
    size_t mlen, ctxlen, siglen;

    if (argc != 5)
    {
      goto usage;
    }

    mlen = (strlen(argv[2]) - strlen("message=")) / 2;
    if (mlen > MAX_MSG_LENGTH ||
        decode_hex("message", message, mlen, argv[2]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    ctxlen = (strlen(argv[3]) - strlen("context=")) / 2;
    if (ctxlen > MAX_CTX_LENGTH ||
        decode_hex("context", context, ctxlen, argv[3]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    if (decode_hex("sk", sk, sizeof(sk), argv[4]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    pre[0] = 0;
    /* Safety: Truncation is safe due to the check above. */
    pre[1] = (uint8_t)ctxlen;
    memcpy(pre + 2, context, ctxlen);

    CHECK(crypto_sign_signature_internal(sig, &siglen, message, mlen, pre,
                                         ctxlen + 2, rnd, sk, 0) == 0);
    print_hex("signature", sig, siglen);
  }
  else if (strcmp(argv[1], "sigGenInternalDeterministic") == 0)
  {
    /* sigGenInternalDeterministic message=HEX sk=HEX externalMu=0/1 */
    unsigned char message[MAX_MSG_LENGTH + MAX_CTX_LENGTH + 2];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char sig[CRYPTO_BYTES];
    unsigned char rnd[MLDSA_RNDBYTES] = {0};
    size_t mlen, siglen;
    int externalMu;

    if (argc != 5)
    {
      goto usage;
    }

    mlen = (strlen(argv[2]) - strlen("message=")) / 2;
    if (mlen > sizeof(message) ||
        decode_hex("message", message, mlen, argv[2]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    if (decode_hex("sk", sk, sizeof(sk), argv[3]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    if (strcmp(argv[4], "externalMu=0") == 0)
    {
      externalMu = 0;
    }
    else if (strcmp(argv[4], "externalMu=1") == 0)
    {
      externalMu = 1;
    }
    else
    {
      printf("decode_error=1\n");
      return 0;
    }

    CHECK(crypto_sign_signature_internal(sig, &siglen, message, mlen, NULL, 0,
                                         rnd, sk, externalMu) == 0);
    print_hex("signature", sig, siglen);
  }
  else
#endif /* !MLD_CONFIG_NO_SIGN_API */
#if !defined(MLD_CONFIG_NO_VERIFY_API)
      if (strcmp(argv[1], "sigVer") == 0)
  {
    /* sigVer message=HEX context=HEX signature=HEX pk=HEX */
    unsigned char message[MAX_MSG_LENGTH];
    unsigned char context[MAX_CTX_LENGTH];
    unsigned char signature[CRYPTO_BYTES];
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    size_t mlen, ctxlen;

    if (argc != 6)
    {
      goto usage;
    }

    mlen = (strlen(argv[2]) - strlen("message=")) / 2;
    if (mlen > MAX_MSG_LENGTH ||
        decode_hex("message", message, mlen, argv[2]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    ctxlen = (strlen(argv[3]) - strlen("context=")) / 2;
    if (ctxlen > MAX_CTX_LENGTH ||
        decode_hex("context", context, ctxlen, argv[3]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    if (decode_hex("signature", signature, sizeof(signature), argv[4]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    if (decode_hex("pk", pk, sizeof(pk), argv[5]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    return crypto_sign_verify(signature, sizeof(signature), message, mlen,
                              context, ctxlen, pk);
  }
  else
#endif /* !MLD_CONFIG_NO_VERIFY_API */
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
      if (strcmp(argv[1], "pkFromSk") == 0)
  {
    /* pkFromSk sk=HEX */
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];

    if (argc != 3)
    {
      goto usage;
    }

    if (decode_hex("sk", sk, sizeof(sk), argv[2]) != 0)
    {
      printf("decode_error=1\n");
      return 0;
    }

    if (crypto_sign_pk_from_sk(pk, sk) != 0)
    {
      return 1;
    }
    print_hex("pk", pk, sizeof(pk));
  }
  else
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */
  {
    goto usage;
  }

  return 0;

usage:
  fprintf(stderr,
          "Usage:\n"
          "  wycheproof_mldsa{lvl} sigGenSeedDeterministic seed=HEX "
          "message=HEX context=HEX externalMu=0/1\n"
          "  wycheproof_mldsa{lvl} sigGenDeterministic message=HEX context=HEX "
          "sk=HEX\n"
          "  wycheproof_mldsa{lvl} sigGenInternalDeterministic message=HEX "
          "sk=HEX externalMu=0/1\n"
          "  wycheproof_mldsa{lvl} sigVer message=HEX context=HEX "
          "signature=HEX pk=HEX\n"
          "  wycheproof_mldsa{lvl} pkFromSk sk=HEX\n");
  return 1;
}
