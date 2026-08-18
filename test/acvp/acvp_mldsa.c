/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "src/common.h"

#include "mldsa_native.h"

#include "../src/decode_hex.h"
#include "../src/test_namespace.h"

#define USAGE "acvp_mldsa{lvl} [keyGen|sigGen|sigVer] {test specific arguments}"
#define KEYGEN_USAGE "acvp_mldsa{lvl} keyGen seed=HEX"
#define SIGGEN_USAGE \
  "acvp_mldsa{lvl} sigGen message=HEX sk=HEX context=HEX rnd=HEX"
#define SIGGEN_INTERNAL_USAGE \
  "acvp_mldsa{lvl} sigGenInternal message=HEX sk=HEX externalMu=0/1 rnd=HEX"
#define SIGGEN_DETERMINISTIC_USAGE \
  "acvp_mldsa{lvl} sigGenDeterministic message=HEX sk=HEX context=HEX"
#define SIGGEN_INTERNAL_DETERMINISTIC_USAGE                         \
  "acvp_mldsa{lvl} sigGenInternalDeterministic message=HEX sk=HEX " \
  "externalMu=0/1"
#define SIGGEN_PREHASH_DETERMINISTIC_USAGE                                \
  "acvp_mldsa{lvl} sigGenPreHashDeterministic ph=HEX context=HEX sk=HEX " \
  "hashAlg=STRING"
#define SIGGEN_PREHASH_SHAKE256_DETERMINISTIC_USAGE                 \
  "acvp_mldsa{lvl} sigGenPreHashShake256Deterministic message=HEX " \
  "context=HEX sk=HEX"
#define SIGVER_USAGE \
  "acvp_mldsa{lvl} sigVer message=HEX context=HEX signature=HEX pk=HEX"
#define SIGVER_INTERNAL_USAGE                                        \
  "acvp_mldsa{lvl} sigVerInternal message=HEX signature=HEX pk=HEX " \
  "externalMu=0/1"
#define SIGGEN_PREHASH_USAGE                                 \
  "acvp_mldsa{lvl} sigGenPreHash ph=HEX context=HEX sk=HEX " \
  "hashAlg=STRING rnd=HEX"
#define SIGVER_PREHASH_USAGE                                               \
  "acvp_mldsa{lvl} sigVerPreHash ph=HEX context=HEX signature=HEX pk=HEX " \
  "hashAlg=STRING"
#define SIGGEN_PREHASH_SHAKE256_USAGE                              \
  "acvp_mldsa{lvl} sigGenPreHashShake256 message=HEX context=HEX " \
  "sk=HEX rnd=HEX"
#define SIGVER_PREHASH_SHAKE256_USAGE                              \
  "acvp_mldsa{lvl} sigVerPreHashShake256 message=HEX context=HEX " \
  "signature=HEX pk=HEX"


/* Print supported API modes and exit (used by acvp_client.py --auto-detect) */
static void print_info(void)
{
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  printf("keyGen\n");
#endif
#if !defined(MLD_CONFIG_NO_SIGN_API)
  printf("sigGen\n");
#endif
#if !defined(MLD_CONFIG_NO_VERIFY_API)
  printf("sigVer\n");
#endif
}

/* maximum message length used in the ACVP tests */
#define MAX_MSG_LENGTH 8192
/* maximum context length according to FIPS-204 */
#define MAX_CTX_LENGTH 255

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

typedef enum
{
  keyGen,
  sigGen,
  sigGenInternal,
  sigGenDeterministic,
  sigGenInternalDeterministic,
  sigGenPreHashDeterministic,
  sigGenPreHashShake256Deterministic,
  sigVer,
  sigVerInternal,
  sigGenPreHash,
  sigVerPreHash,
  sigGenPreHashShake256,
  sigVerPreHashShake256
} acvp_mode;



#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
static int decode_keyed_int(const char *prefix_string, int *out,
                            const char *str)
{
  size_t str_len = strlen(str);
  size_t prefix_len = strlen(prefix_string);
  char *endptr;
  long val;

  /*
   * Check that str starts with `prefix=`
   * Use memcmp, not strcmp
   */
  if (str_len < prefix_len + 1 || memcmp(prefix_string, str, prefix_len) != 0 ||
      str[prefix_len] != '=')
  {
    goto int_usage;
  }

  str += prefix_len + 1;

  /* Parse the integer value */
  val = strtol(str, &endptr, 10);

  /* Check for parsing errors */
  if (*endptr != '\0' || endptr == str)
  {
    goto int_usage;
  }

  /* Check for overflow */
  if (val > INT_MAX || val < INT_MIN)
  {
    goto int_usage;
  }

  *out = (int)val;
  return 0;

int_usage:
  fprintf(stderr,
          "Argument %s invalid: Expected argument of the form '%s=INT' with "
          "INT being a decimal integer\n",
          str, prefix_string);
  return 1;
}

static int parse_str(const char *prefix, char *out, size_t out_max_len,
                     const char *str)
{
  size_t str_len = strlen(str);
  size_t prefix_len = strlen(prefix);
  size_t value_len;

  /*
   * Check that str starts with `prefix=`
   * Use memcmp, not strcmp
   */
  if (str_len < prefix_len + 1 || memcmp(prefix, str, prefix_len) != 0 ||
      str[prefix_len] != '=')
  {
    goto str_usage;
  }

  str += prefix_len + 1;
  value_len = strlen(str);

  if (value_len >= out_max_len)
  {
    fprintf(stderr,
            "Argument %s invalid: String value too long (max %u characters)\n",
            str - prefix_len - 1, (unsigned)(out_max_len - 1));
    return 1;
  }

  strncpy(out, str, out_max_len - 1);
  out[out_max_len - 1] = '\0';
  return 0;

str_usage:
  fprintf(stderr,
          "Argument %s invalid: Expected argument of the form '%s=STRING'\n",
          str, prefix);
  return 1;
}
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_SIGN_API)
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
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
static MLD_NOINLINE void acvp_mldsa_keyGen_AFT(
    const unsigned char seed[MLDSA_RNDBYTES])
{
  unsigned char pk[MLDSA_PK_BYTES];
  unsigned char sk[MLDSA_SK_BYTES];

  CHECK(mld_sign_keypair_internal(pk, sk, seed) == 0);

  print_hex("pk", pk, sizeof(pk));
  print_hex("sk", sk, sizeof(sk));
}

#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
/* Private key expanded from a seed. Kept in .bss (not on main's stack) so that
 * main's per-case argument handling stays small on RAM-tight targets. */
static unsigned char acvp_expanded_sk[MLDSA_SK_BYTES];
#endif

/*
 * Resolve the sigGen key argument. "sk=HEX" (keyFormat 'expanded') is decoded
 * in place and a pointer into arg is returned; "seed=HEX" (keyFormat 'seed')
 * is expanded via keyGen. Returns NULL on failure. MLD_NOINLINE keeps the
 * keyGen scratch out of the caller's (main's) stack frame.
 */
static MLD_NOINLINE unsigned char *decode_sk(char *arg)
{
  size_t seed_len = strlen("seed=");
  /* Prefix check via memcmp; strncmp is unavailable on baremetal builds. */
  if (strlen(arg) >= seed_len && memcmp(arg, "seed=", seed_len) == 0)
  {
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
    unsigned char pk[MLDSA_PK_BYTES];
    unsigned char *seed = decode_hex("seed", MLDSA_SEEDBYTES, arg);
    if (seed == NULL)
    {
      return NULL;
    }
    if (mld_sign_keypair_internal(pk, acvp_expanded_sk, seed) != 0)
    {
      fprintf(stderr, "Failed to expand seed into private key\n");
      return NULL;
    }
    return acvp_expanded_sk;
#else  /* !MLD_CONFIG_NO_KEYPAIR_API */
    fprintf(stderr, "seed key format requires the keyGen API\n");
    return NULL;
#endif /* MLD_CONFIG_NO_KEYPAIR_API */
  }
  return decode_hex("sk", MLDSA_SK_BYTES, arg);
}

static MLD_NOINLINE void acvp_mldsa_sigGen_AFT(
    const unsigned char *message, size_t mlen,
    const unsigned char rnd[MLDSA_SEEDBYTES],
    const unsigned char sk[MLDSA_SK_BYTES], const unsigned char *context,
    size_t ctxlen)
{
  unsigned char sig[MLDSA_SIG_BYTES];
  unsigned char pre[MAX_CTX_LENGTH + 2];

  CHECK(ctxlen <= 255);
  pre[0] = 0;
  /* Safety: Truncation is safe due to the check above. */
  pre[1] = (uint8_t)ctxlen;
  memcpy(pre + 2, context, ctxlen);

  CHECK(mld_sign_signature_internal(sig, message, mlen, pre, ctxlen + 2, rnd,
                                    sk, 0) == 0);
  print_hex("signature", sig, sizeof(sig));
}

static MLD_NOINLINE void acvp_mldsa_sigGenInternal_AFT(
    const unsigned char *message, size_t mlen,
    const unsigned char rnd[MLDSA_SEEDBYTES],
    const unsigned char sk[MLDSA_SK_BYTES], int externalMu)
{
  unsigned char sig[MLDSA_SIG_BYTES];
  CHECK(mld_sign_signature_internal(sig, message, mlen, NULL, 0, rnd, sk,
                                    externalMu) == 0);
  print_hex("signature", sig, sizeof(sig));
}

/* Deterministic signing functions - use all-zero rnd for deterministic mode */

static MLD_NOINLINE void acvp_mldsa_sigGenDeterministic_AFT(
    const unsigned char *message, size_t mlen,
    const unsigned char sk[MLDSA_SK_BYTES], const unsigned char *context,
    size_t ctxlen)
{
  unsigned char sig[MLDSA_SIG_BYTES];
  unsigned char rnd[MLDSA_SEEDBYTES] = {0}; /* Zero rnd for deterministic */

  unsigned char pre[MAX_CTX_LENGTH + 2];

  CHECK(ctxlen <= 255);
  pre[0] = 0;
  /* Safety: Truncation is safe due to the check above. */
  pre[1] = (uint8_t)ctxlen;
  memcpy(pre + 2, context, ctxlen);

  CHECK(mld_sign_signature_internal(sig, message, mlen, pre, ctxlen + 2, rnd,
                                    sk, 0) == 0);
  print_hex("signature", sig, sizeof(sig));
}

static MLD_NOINLINE void acvp_mldsa_sigGenInternalDeterministic_AFT(
    const unsigned char *message, size_t mlen,
    const unsigned char sk[MLDSA_SK_BYTES], int externalMu)
{
  unsigned char sig[MLDSA_SIG_BYTES];
  unsigned char rnd[MLDSA_SEEDBYTES] = {0}; /* Zero rnd for deterministic */

  CHECK(mld_sign_signature_internal(sig, message, mlen, NULL, 0, rnd, sk,
                                    externalMu) == 0);
  print_hex("signature", sig, sizeof(sig));
}
#endif /* !MLD_CONFIG_NO_SIGN_API */


#if !defined(MLD_CONFIG_NO_VERIFY_API)
static MLD_NOINLINE int acvp_mldsa_sigVer_AFT(
    const unsigned char *message, size_t mlen, const unsigned char *context,
    size_t ctxlen, const unsigned char signature[MLDSA_SIG_BYTES],
    const unsigned char pk[MLDSA_PK_BYTES])
{
  return mld_sign_verify(signature, message, mlen, context, ctxlen, pk);
}


static MLD_NOINLINE int acvp_mldsa_sigVerInternal_AFT(
    const unsigned char *message, size_t mlen,
    const unsigned char signature[MLDSA_SIG_BYTES],
    const unsigned char pk[MLDSA_PK_BYTES], int externalMu)
{
  if (externalMu)
  {
    return mld_sign_verify_extmu(signature, message, pk);
  }
  else
  {
    return mld_sign_verify_internal(signature, message, mlen, NULL, 0, pk, 0);
  }
}
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
static int str_to_hash_alg(const char *hashAlg)
{
  if (strcmp(hashAlg, "SHA2-224") == 0)
  {
    return MLD_PREHASH_SHA2_224;
  }
  if (strcmp(hashAlg, "SHA2-256") == 0)
  {
    return MLD_PREHASH_SHA2_256;
  }
  if (strcmp(hashAlg, "SHA2-384") == 0)
  {
    return MLD_PREHASH_SHA2_384;
  }
  if (strcmp(hashAlg, "SHA2-512") == 0)
  {
    return MLD_PREHASH_SHA2_512;
  }
  if (strcmp(hashAlg, "SHA2-512/224") == 0)
  {
    return MLD_PREHASH_SHA2_512_224;
  }
  if (strcmp(hashAlg, "SHA2-512/256") == 0)
  {
    return MLD_PREHASH_SHA2_512_256;
  }
  if (strcmp(hashAlg, "SHA3-224") == 0)
  {
    return MLD_PREHASH_SHA3_224;
  }
  if (strcmp(hashAlg, "SHA3-256") == 0)
  {
    return MLD_PREHASH_SHA3_256;
  }
  if (strcmp(hashAlg, "SHA3-384") == 0)
  {
    return MLD_PREHASH_SHA3_384;
  }
  if (strcmp(hashAlg, "SHA3-512") == 0)
  {
    return MLD_PREHASH_SHA3_512;
  }
  if (strcmp(hashAlg, "SHAKE-128") == 0)
  {
    return MLD_PREHASH_SHAKE_128;
  }
  if (strcmp(hashAlg, "SHAKE-256") == 0)
  {
    return MLD_PREHASH_SHAKE_256;
  }
  /* Invalid hash algorithm */
  fprintf(stderr, "Error: Unsupported hash algorithm: %s\n", hashAlg);
  exit(1);
}
#endif /* !MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_NOINLINE int acvp_mldsa_sigGenPreHash_AFT(
    const unsigned char *ph, size_t phlen, const unsigned char *context,
    size_t ctxlen, const unsigned char rng[MLDSA_RNDBYTES],
    const unsigned char sk[MLDSA_SK_BYTES], const char *hashAlg)
{
  unsigned char signature[MLDSA_SIG_BYTES];
  if (mld_sign_signature_pre_hash_internal(signature, ph, phlen, context,
                                           ctxlen, rng, sk,
                                           str_to_hash_alg(hashAlg)) != 0)
  {
    return 1;
  }

  print_hex("signature", signature, MLDSA_SIG_BYTES);
  return 0;
}

#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
static MLD_NOINLINE int acvp_mldsa_sigVerPreHash_AFT(
    const unsigned char *ph, size_t phlen, const unsigned char *context,
    size_t ctxlen, const unsigned char signature[MLDSA_SIG_BYTES],
    const unsigned char pk[MLDSA_PK_BYTES], const char *hashAlg)
{
  return mld_sign_verify_pre_hash_internal(
      signature, ph, phlen, context, ctxlen, pk, str_to_hash_alg(hashAlg));
}
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_NOINLINE int acvp_mldsa_sigGenPreHashShake256_AFT(
    const unsigned char *message, size_t mlen, const unsigned char *context,
    size_t ctxlen, const unsigned char rnd[MLDSA_RNDBYTES],
    const unsigned char sk[MLDSA_SK_BYTES])
{
  unsigned char signature[MLDSA_SIG_BYTES];
  if (mld_sign_signature_pre_hash_shake256(signature, message, mlen, context,
                                           ctxlen, rnd, sk) != 0)
  {
    return 1;
  }

  print_hex("signature", signature, MLDSA_SIG_BYTES);
  return 0;
}

#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
static MLD_NOINLINE int acvp_mldsa_sigVerPreHashShake256_AFT(
    const unsigned char *message, size_t mlen, const unsigned char *context,
    size_t ctxlen, const unsigned char signature[MLDSA_SIG_BYTES],
    const unsigned char pk[MLDSA_PK_BYTES])
{
  return mld_sign_verify_pre_hash_shake256(signature, message, mlen, context,
                                           ctxlen, pk);
}
#endif /* !MLD_CONFIG_NO_VERIFY_API */

/* Deterministic prehash signing functions */
#if !defined(MLD_CONFIG_NO_SIGN_API)
static MLD_NOINLINE int acvp_mldsa_sigGenPreHashDeterministic_AFT(
    const unsigned char *ph, size_t phlen, const unsigned char *context,
    size_t ctxlen, const unsigned char sk[MLDSA_SK_BYTES], const char *hashAlg)
{
  unsigned char signature[MLDSA_SIG_BYTES];
  unsigned char rnd[MLDSA_RNDBYTES] = {0}; /* Zero rnd for deterministic */

  if (mld_sign_signature_pre_hash_internal(signature, ph, phlen, context,
                                           ctxlen, rnd, sk,
                                           str_to_hash_alg(hashAlg)) != 0)
  {
    return 1;
  }

  print_hex("signature", signature, MLDSA_SIG_BYTES);
  return 0;
}

static MLD_NOINLINE int acvp_mldsa_sigGenPreHashShake256Deterministic_AFT(
    const unsigned char *message, size_t mlen, const unsigned char *context,
    size_t ctxlen, const unsigned char sk[MLDSA_SK_BYTES])
{
  unsigned char signature[MLDSA_SIG_BYTES];
  unsigned char rnd[MLDSA_RNDBYTES] = {0}; /* Zero rnd for deterministic */

  if (mld_sign_signature_pre_hash_shake256(signature, message, mlen, context,
                                           ctxlen, rnd, sk) != 0)
  {
    return 1;
  }

  print_hex("signature", signature, MLDSA_SIG_BYTES);
  return 0;
}
#endif /* !MLD_CONFIG_NO_SIGN_API */


/* Prototype for a re-#define'd main, to satisfy -Wmissing-prototypes. */
#if defined(main)
int main(int argc, char *argv[]);
#endif
int main(int argc, char *argv[])
{
  acvp_mode mode;

  if (argc == 0)
  {
    goto usage;
  }
  argc--, argv++;

  if (argc == 0)
  {
    goto usage;
  }

  if (strcmp(*argv, "--info") == 0)
  {
    print_info();
    return 0;
  }

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
  if (strcmp(*argv, "keyGen") == 0)
  {
    mode = keyGen;
  }
  else
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */
#if !defined(MLD_CONFIG_NO_SIGN_API)
      if (strcmp(*argv, "sigGen") == 0)
  {
    mode = sigGen;
  }
  else if (strcmp(*argv, "sigGenInternal") == 0)
  {
    mode = sigGenInternal;
  }
  else if (strcmp(*argv, "sigGenDeterministic") == 0)
  {
    mode = sigGenDeterministic;
  }
  else if (strcmp(*argv, "sigGenInternalDeterministic") == 0)
  {
    mode = sigGenInternalDeterministic;
  }
  else if (strcmp(*argv, "sigGenPreHashDeterministic") == 0)
  {
    mode = sigGenPreHashDeterministic;
  }
  else if (strcmp(*argv, "sigGenPreHashShake256Deterministic") == 0)
  {
    mode = sigGenPreHashShake256Deterministic;
  }
  else if (strcmp(*argv, "sigGenPreHash") == 0)
  {
    mode = sigGenPreHash;
  }
  else if (strcmp(*argv, "sigGenPreHashShake256") == 0)
  {
    mode = sigGenPreHashShake256;
  }
  else
#endif /* !MLD_CONFIG_NO_SIGN_API */
#if !defined(MLD_CONFIG_NO_VERIFY_API)
      if (strcmp(*argv, "sigVer") == 0)
  {
    mode = sigVer;
  }
  else if (strcmp(*argv, "sigVerInternal") == 0)
  {
    mode = sigVerInternal;
  }
  else if (strcmp(*argv, "sigVerPreHash") == 0)
  {
    mode = sigVerPreHash;
  }
  else if (strcmp(*argv, "sigVerPreHashShake256") == 0)
  {
    mode = sigVerPreHashShake256;
  }
  else
#endif /* !MLD_CONFIG_NO_VERIFY_API */
  {
    goto usage;
  }
  argc--, argv++;

  switch (mode)
  {
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
    case keyGen:
    {
      unsigned char *seed;
      /* Parse seed */
      if (argc == 0 ||
          (seed = decode_hex("seed", MLDSA_SEEDBYTES, *argv)) == NULL)
      {
        goto keygen_usage;
      }
      argc--, argv++;

      /* Call function under test */
      acvp_mldsa_keyGen_AFT(seed);
      break;
    }
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
    case sigGen:
    {
      unsigned char *message;
      unsigned char *rnd;
      unsigned char *context;
      unsigned char *sk;
      size_t mlen, ctxlen;

      /* Parse message */
      if (argc == 0)
      {
        goto siggen_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto siggen_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto siggen_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto siggen_usage;
      }
      argc--, argv++;

      /* Parse rnd */
      if (argc == 0 || (rnd = decode_hex("rnd", MLDSA_RNDBYTES, *argv)) == NULL)
      {
        goto siggen_usage;
      }
      argc--, argv++;

      /* Call function under test */
      acvp_mldsa_sigGen_AFT(message, mlen, rnd, sk, context, ctxlen);
      break;
    }
    case sigGenInternal:
    {
      unsigned char *message;
      unsigned char *rnd;
      unsigned char *sk;
      int externalMu;
      size_t mlen;

      /* Parse message */
      if (argc == 0)
      {
        goto siggen_internal_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH + MAX_CTX_LENGTH + 2 ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto siggen_internal_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_internal_usage;
      }
      argc--, argv++;

      /* Parse externalMu */
      if (argc == 0 ||
          decode_keyed_int("externalMu", &externalMu, *argv) != 0 ||
          externalMu > 1 || externalMu < 0)
      {
        goto siggen_internal_usage;
      }
      argc--, argv++;

      /* Parse rnd */
      if (argc == 0 || (rnd = decode_hex("rnd", MLDSA_RNDBYTES, *argv)) == NULL)
      {
        goto siggen_internal_usage;
      }
      argc--, argv++;


      /* Call function under test */
      acvp_mldsa_sigGenInternal_AFT(message, mlen, rnd, sk, externalMu);
      break;
    }

    case sigGenDeterministic:
    {
      unsigned char *message;
      unsigned char *context;
      unsigned char *sk;
      size_t mlen, ctxlen;

      /* Parse message */
      if (argc == 0)
      {
        goto siggen_deterministic_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto siggen_deterministic_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_deterministic_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto siggen_deterministic_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto siggen_deterministic_usage;
      }
      argc--, argv++;

      /* Call function under test */
      acvp_mldsa_sigGenDeterministic_AFT(message, mlen, sk, context, ctxlen);
      break;
    }

    case sigGenInternalDeterministic:
    {
      unsigned char *message;
      unsigned char *sk;
      int externalMu;
      size_t mlen;

      /* Parse message */
      if (argc == 0)
      {
        goto siggen_internal_deterministic_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH + MAX_CTX_LENGTH + 2 ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto siggen_internal_deterministic_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_internal_deterministic_usage;
      }
      argc--, argv++;

      /* Parse externalMu */
      if (argc == 0 ||
          decode_keyed_int("externalMu", &externalMu, *argv) != 0 ||
          externalMu > 1 || externalMu < 0)
      {
        goto siggen_internal_deterministic_usage;
      }
      argc--, argv++;

      /* Call function under test */
      acvp_mldsa_sigGenInternalDeterministic_AFT(message, mlen, sk, externalMu);
      break;
    }
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
    case sigVer:
    {
      unsigned char *message;
      unsigned char *context;
      unsigned char *signature;
      unsigned char *pk;
      size_t mlen, ctxlen;

      /* Parse message */
      if (argc == 0)
      {
        goto sigver_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto sigver_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto sigver_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto sigver_usage;
      }
      argc--, argv++;

      /* Parse signature */
      if (argc == 0 ||
          (signature = decode_hex("signature", MLDSA_SIG_BYTES, *argv)) == NULL)
      {
        goto sigver_usage;
      }
      argc--, argv++;


      /* Parse pk */
      if (argc == 0 || (pk = decode_hex("pk", MLDSA_PK_BYTES, *argv)) == NULL)
      {
        goto sigver_usage;
      }
      argc--, argv++;


      /* Call function under test */
      return acvp_mldsa_sigVer_AFT(message, mlen, context, ctxlen, signature,
                                   pk);
    }


    case sigVerInternal:
    {
      unsigned char *message;
      unsigned char *signature;
      unsigned char *pk;
      size_t mlen;
      int externalMu;

      /* Parse message */
      if (argc == 0)
      {
        goto sigver_internal_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto sigver_internal_usage;
      }
      argc--, argv++;

      /* Parse signature */
      if (argc == 0 ||
          (signature = decode_hex("signature", MLDSA_SIG_BYTES, *argv)) == NULL)
      {
        goto sigver_internal_usage;
      }
      argc--, argv++;


      /* Parse pk */
      if (argc == 0 || (pk = decode_hex("pk", MLDSA_PK_BYTES, *argv)) == NULL)
      {
        goto sigver_internal_usage;
      }
      argc--, argv++;

      /* Parse externalMu */
      if (argc == 0 ||
          decode_keyed_int("externalMu", &externalMu, *argv) != 0 ||
          externalMu > 1 || externalMu < 0)
      {
        goto sigver_internal_usage;
      }
      argc--, argv++;



      /* Call function under test */
      return acvp_mldsa_sigVerInternal_AFT(message, mlen, signature, pk,
                                           externalMu);
    }
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
    case sigGenPreHash:
    {
      unsigned char *ph;
      unsigned char *context;
      unsigned char *rnd;
      unsigned char *sk;
      char hashAlg[100];
      size_t phlen;
      size_t ctxlen;

      /* Parse ph */
      if (argc == 0)
      {
        goto siggen_prehash_usage;
      }
      phlen = (strlen(*argv) - strlen("ph=")) / 2;
      if (phlen > 64 || (ph = decode_hex("ph", phlen, *argv)) == NULL)
      {
        goto siggen_prehash_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto siggen_prehash_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto siggen_prehash_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_prehash_usage;
      }
      argc--, argv++;

      /* Parse hashAlg */
      if (argc == 0 ||
          parse_str("hashAlg", hashAlg, sizeof(hashAlg), *argv) != 0)
      {
        goto siggen_prehash_usage;
      }
      argc--, argv++;

      /* Parse rnd */
      if (argc == 0 || (rnd = decode_hex("rnd", MLDSA_RNDBYTES, *argv)) == NULL)
      {
        goto siggen_prehash_usage;
      }
      argc--, argv++;

      /* Call function under test */
      return acvp_mldsa_sigGenPreHash_AFT(ph, phlen, context, ctxlen, rnd, sk,
                                          hashAlg);
    }
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
    case sigVerPreHash:
    {
      unsigned char *ph;
      unsigned char *context;
      unsigned char *signature;
      unsigned char *pk;
      char hashAlg[100];
      size_t phlen;
      size_t ctxlen;

      /* Parse message */
      if (argc == 0)
      {
        goto sigver_prehash_usage;
      }
      phlen = (strlen(*argv) - strlen("ph=")) / 2;
      if (phlen > 64 || (ph = decode_hex("ph", phlen, *argv)) == NULL)
      {
        goto sigver_prehash_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto sigver_prehash_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto sigver_prehash_usage;
      }
      argc--, argv++;

      /* Parse signature */
      if (argc == 0 ||
          (signature = decode_hex("signature", MLDSA_SIG_BYTES, *argv)) == NULL)
      {
        goto sigver_prehash_usage;
      }
      argc--, argv++;


      /* Parse pk */
      if (argc == 0 || (pk = decode_hex("pk", MLDSA_PK_BYTES, *argv)) == NULL)
      {
        goto sigver_prehash_usage;
      }
      argc--, argv++;

      /* Parse hashAlg */
      if (argc == 0 ||
          parse_str("hashAlg", hashAlg, sizeof(hashAlg), *argv) != 0)
      {
        goto sigver_prehash_usage;
      }
      argc--, argv++;



      /* Call function under test */
      return acvp_mldsa_sigVerPreHash_AFT(ph, phlen, context, ctxlen, signature,
                                          pk, hashAlg);
    }
#endif /* !MLD_CONFIG_NO_VERIFY_API */

#if !defined(MLD_CONFIG_NO_SIGN_API)
    case sigGenPreHashShake256:
    {
      unsigned char *message;
      unsigned char *context;
      unsigned char *rnd;
      unsigned char *sk;
      size_t mlen;
      size_t ctxlen;

      /* Parse message */
      if (argc == 0)
      {
        goto siggen_prehash_shake256_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto siggen_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto siggen_prehash_shake256_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto siggen_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Parse rnd */
      if (argc == 0 || (rnd = decode_hex("rnd", MLDSA_RNDBYTES, *argv)) == NULL)
      {
        goto siggen_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Call function under test */
      return acvp_mldsa_sigGenPreHashShake256_AFT(message, mlen, context,
                                                  ctxlen, rnd, sk);
    }

    case sigGenPreHashDeterministic:
    {
      unsigned char *ph;
      unsigned char *context;
      unsigned char *sk;
      char hashAlg[100];
      size_t phlen;
      size_t ctxlen;

      /* Parse ph */
      if (argc == 0)
      {
        goto siggen_prehash_deterministic_usage;
      }
      phlen = (strlen(*argv) - strlen("ph=")) / 2;
      if (phlen > 64 || (ph = decode_hex("ph", phlen, *argv)) == NULL)
      {
        goto siggen_prehash_deterministic_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto siggen_prehash_deterministic_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto siggen_prehash_deterministic_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_prehash_deterministic_usage;
      }
      argc--, argv++;

      /* Parse hashAlg */
      if (argc == 0 ||
          parse_str("hashAlg", hashAlg, sizeof(hashAlg), *argv) != 0)
      {
        goto siggen_prehash_deterministic_usage;
      }
      argc--, argv++;

      /* Call function under test */
      return acvp_mldsa_sigGenPreHashDeterministic_AFT(ph, phlen, context,
                                                       ctxlen, sk, hashAlg);
    }

    case sigGenPreHashShake256Deterministic:
    {
      unsigned char *message;
      unsigned char *context;
      unsigned char *sk;
      size_t mlen;
      size_t ctxlen;

      /* Parse message */
      if (argc == 0)
      {
        goto siggen_prehash_shake256_deterministic_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto siggen_prehash_shake256_deterministic_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto siggen_prehash_shake256_deterministic_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto siggen_prehash_shake256_deterministic_usage;
      }
      argc--, argv++;

      /* Parse sk */
      if (argc == 0 || (sk = decode_sk(*argv)) == NULL)
      {
        goto siggen_prehash_shake256_deterministic_usage;
      }
      argc--, argv++;

      /* Call function under test */
      return acvp_mldsa_sigGenPreHashShake256Deterministic_AFT(
          message, mlen, context, ctxlen, sk);
    }
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
    case sigVerPreHashShake256:
    {
      unsigned char *message;
      unsigned char *context;
      unsigned char *signature;
      unsigned char *pk;
      size_t mlen;
      size_t ctxlen;

      /* Parse message */
      if (argc == 0)
      {
        goto sigver_prehash_shake256_usage;
      }
      mlen = (strlen(*argv) - strlen("message=")) / 2;
      if (mlen > MAX_MSG_LENGTH ||
          (message = decode_hex("message", mlen, *argv)) == NULL)
      {
        goto sigver_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Parse context */
      if (argc == 0)
      {
        goto sigver_prehash_shake256_usage;
      }
      ctxlen = (strlen(*argv) - strlen("context=")) / 2;
      if (ctxlen > MAX_CTX_LENGTH ||
          (context = decode_hex("context", ctxlen, *argv)) == NULL)
      {
        goto sigver_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Parse signature */
      if (argc == 0 ||
          (signature = decode_hex("signature", MLDSA_SIG_BYTES, *argv)) == NULL)
      {
        goto sigver_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Parse pk */
      if (argc == 0 || (pk = decode_hex("pk", MLDSA_PK_BYTES, *argv)) == NULL)
      {
        goto sigver_prehash_shake256_usage;
      }
      argc--, argv++;

      /* Call function under test */
      return acvp_mldsa_sigVerPreHashShake256_AFT(message, mlen, context,
                                                  ctxlen, signature, pk);
    }
#endif /* !MLD_CONFIG_NO_VERIFY_API */
    default:
      goto usage;
  }

  return (0);

usage:
  fprintf(stderr, USAGE "\n");
  return (1);

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
keygen_usage:
  fprintf(stderr, KEYGEN_USAGE "\n");
  return (1);
#endif

#if !defined(MLD_CONFIG_NO_SIGN_API)
siggen_usage:
  fprintf(stderr, SIGGEN_USAGE "\n");
  return (1);

siggen_internal_usage:
  fprintf(stderr, SIGGEN_INTERNAL_USAGE "\n");
  return (1);

siggen_deterministic_usage:
  fprintf(stderr, SIGGEN_DETERMINISTIC_USAGE "\n");
  return (1);

siggen_internal_deterministic_usage:
  fprintf(stderr, SIGGEN_INTERNAL_DETERMINISTIC_USAGE "\n");
  return (1);

siggen_prehash_deterministic_usage:
  fprintf(stderr, SIGGEN_PREHASH_DETERMINISTIC_USAGE "\n");
  return (1);

siggen_prehash_shake256_deterministic_usage:
  fprintf(stderr, SIGGEN_PREHASH_SHAKE256_DETERMINISTIC_USAGE "\n");
  return (1);

siggen_prehash_usage:
  fprintf(stderr, SIGGEN_PREHASH_USAGE "\n");
  return (1);

siggen_prehash_shake256_usage:
  fprintf(stderr, SIGGEN_PREHASH_SHAKE256_USAGE "\n");
  return (1);
#endif /* !MLD_CONFIG_NO_SIGN_API */

#if !defined(MLD_CONFIG_NO_VERIFY_API)
sigver_usage:
  fprintf(stderr, SIGVER_USAGE "\n");
  return (1);

sigver_internal_usage:
  fprintf(stderr, SIGVER_INTERNAL_USAGE "\n");
  return (1);

sigver_prehash_usage:
  fprintf(stderr, SIGVER_PREHASH_USAGE "\n");
  return (1);

sigver_prehash_shake256_usage:
  fprintf(stderr, SIGVER_PREHASH_SHAKE256_USAGE "\n");
  return (1);
#endif /* !MLD_CONFIG_NO_VERIFY_API */
}
