/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "../notrandombytes/notrandombytes.h"

#include "../../mldsa/src/fips202/keccakf1600.h"
#include "../../mldsa/src/poly.h"
#include "../../mldsa/src/poly_kl.h"
#include "../../mldsa/src/polyvec.h"
#include "../../mldsa/src/polyvec_lazy.h"

#ifndef NUM_RANDOM_TESTS
#ifdef MLDSA_DEBUG
#define NUM_RANDOM_TESTS 800
#else
#define NUM_RANDOM_TESTS 4000
#endif
#endif /* !NUM_RANDOM_TESTS */

#define NUM_RANDOM_TESTS_SLOW 50

#define CHECK(x)                                              \
  do                                                          \
  {                                                           \
    int r;                                                    \
    r = (x);                                                  \
    if (!r)                                                   \
    {                                                         \
      fprintf(stderr, "ERROR (%s,%d)\n", __FILE__, __LINE__); \
      return 1;                                               \
    }                                                         \
  } while (0)

/* Declarations for _c functions exposed by MLD_STATIC_TESTABLE= */
void mld_poly_ntt_c(mld_poly *a);
void mld_poly_invntt_tomont_c(mld_poly *a);
void mld_poly_caddq_c(mld_poly *a);
#if !defined(MLD_CONFIG_NO_SIGN_API)
void mld_poly_decompose_c(mld_poly *a1, mld_poly *a0);
#endif
#if !defined(MLD_CONFIG_NO_VERIFY_API)
void mld_poly_use_hint_c(mld_poly *a, const mld_poly *h);
#endif
uint32_t mld_poly_chknorm_c(const mld_poly *a, int32_t B);
#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
void mld_poly_pointwise_montgomery_c(mld_poly *a, const mld_poly *b);
#endif
void mld_polyvecl_pointwise_acc_montgomery_c(mld_poly *w, const mld_polyvecl *u,
                                             const mld_polyvecl *v);
#if !defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
void mld_polyz_unpack_c(mld_poly *r, const uint8_t a[MLDSA_POLYZ_PACKEDBYTES]);
#endif
unsigned int mld_rej_uniform_c(int32_t *a, unsigned int target,
                               unsigned int offset, const uint8_t *buf,
                               unsigned int buflen);
#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
unsigned int mld_rej_eta_c(int32_t *a, unsigned int target, unsigned int offset,
                           const uint8_t *buf, unsigned int buflen);
#endif
void mld_keccakf1600_permute_c(uint64_t *state);

#if defined(MLD_USE_NATIVE_FIPS202_X1)
static void print_u64_array(const char *label, const uint64_t *array,
                            size_t len)
{
  size_t i;
  fprintf(stderr, "%s:\n", label);
  for (i = 0; i < len; i++)
  {
    if (i % 4 == 0)
    {
      fprintf(stderr, "  ");
    }
    fprintf(stderr, "%016llx", (unsigned long long)array[i]);
    if (i % 4 == 3)
    {
      fprintf(stderr, "\n");
    }
    else
    {
      fprintf(stderr, " ");
    }
  }
  if (len % 4 != 0)
  {
    fprintf(stderr, "\n");
  }
}

static int compare_u64_arrays(const uint64_t *a, const uint64_t *b,
                              unsigned len, const char *test_name)
{
  unsigned i;
  for (i = 0; i < len; i++)
  {
    if (a[i] != b[i])
    {
      fprintf(stderr, "FAIL: %s\n", test_name);
      fprintf(
          stderr,
          "  First difference at index %u: got=0x%016llx, expected=0x%016llx\n",
          i, (unsigned long long)a[i], (unsigned long long)b[i]);
      print_u64_array("Got", a, len);
      print_u64_array("Expected", b, len);
      return 0;
    }
  }
  return 1;
}
#endif /* MLD_USE_NATIVE_FIPS202_X1 */

#if defined(MLD_USE_NATIVE_NTT) || defined(MLD_USE_NATIVE_INTT) ||  \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_32) ||                    \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_88) ||                    \
    defined(MLD_USE_NATIVE_POLY_CADDQ) ||                           \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_88) ||                     \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_32) ||                     \
    defined(MLD_USE_NATIVE_POLY_CHKNORM) ||                         \
    defined(MLD_USE_NATIVE_POINTWISE_MONTGOMERY) ||                 \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7) || \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_17) ||                      \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_19) ||                      \
    defined(MLD_USE_NATIVE_REJ_UNIFORM) ||                          \
    defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA2) ||                     \
    defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA4) ||                     \
    defined(MLD_USE_NATIVE_FIPS202_X1) || defined(MLD_USE_NATIVE_FIPS202_X4)

/* Backend unit test helper functions for arithmetic native backends */
#if defined(MLD_USE_NATIVE_NTT) || defined(MLD_USE_NATIVE_INTT) ||  \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_32) ||                    \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_88) ||                    \
    defined(MLD_USE_NATIVE_POLY_CADDQ) ||                           \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_88) ||                     \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_32) ||                     \
    defined(MLD_USE_NATIVE_POINTWISE_MONTGOMERY) ||                 \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7) || \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_17) ||                      \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_19)
static void print_i32_array(const char *label, const int32_t *array, size_t len)
{
  size_t i;
  fprintf(stderr, "%s:\n", label);
  for (i = 0; i < len; i++)
  {
    if (i % 8 == 0)
    {
      fprintf(stderr, "  ");
    }
    fprintf(stderr, "%8d", array[i]);
    if (i % 8 == 7)
    {
      fprintf(stderr, "\n");
    }
    else
    {
      fprintf(stderr, " ");
    }
  }
  if (len % 8 != 0)
  {
    fprintf(stderr, "\n");
  }
}

static void generate_i32_array_zeros(int32_t *data, size_t len)
{
  memset(data, 0, len * sizeof(int32_t));
}

static void generate_i32_array_single(int32_t *data, size_t len, size_t pos,
                                      int32_t value)
{
  memset(data, 0, len * sizeof(int32_t));
  data[pos] = value;
}
#endif /* MLD_USE_NATIVE_NTT || MLD_USE_NATIVE_INTT ||                         \
          MLD_USE_NATIVE_POLY_DECOMPOSE_32 || MLD_USE_NATIVE_POLY_DECOMPOSE_88 \
          || MLD_USE_NATIVE_POLY_CADDQ || MLD_USE_NATIVE_POLY_USE_HINT_88 ||   \
          MLD_USE_NATIVE_POLY_USE_HINT_32 ||                                   \
          MLD_USE_NATIVE_POINTWISE_MONTGOMERY ||                               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7 ||               \
          MLD_USE_NATIVE_POLYZ_UNPACK_17 || MLD_USE_NATIVE_POLYZ_UNPACK_19 */

#if defined(MLD_USE_NATIVE_NTT) || defined(MLD_USE_NATIVE_INTT) ||  \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_32) ||                    \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_88) ||                    \
    defined(MLD_USE_NATIVE_POLY_CADDQ) ||                           \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_88) ||                     \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_32) ||                     \
    defined(MLD_USE_NATIVE_POLY_CHKNORM) ||                         \
    defined(MLD_USE_NATIVE_POINTWISE_MONTGOMERY) ||                 \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7) || \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_17) ||                      \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_19)
/* This does not generate a uniformly random distribution, but it's
 * good enough for our test.
 *
 * The lower bound is inclusive, the upper bound exclusive, matching
 * the CBMC assertions in the code base. */
static void generate_i32_array_ranged(int32_t *data, size_t len, int min_incl,
                                      int max_excl)
{
  size_t i;

  randombytes((uint8_t *)data, len * sizeof(int32_t));
  for (i = 0; i < len; i++)
  {
    data[i] = (int32_t)((unsigned)min_incl +
                        ((unsigned)data[i] % (unsigned)(max_excl - min_incl)));
  }
}
#endif /* MLD_USE_NATIVE_NTT || MLD_USE_NATIVE_INTT ||                         \
          MLD_USE_NATIVE_POLY_DECOMPOSE_32 || MLD_USE_NATIVE_POLY_DECOMPOSE_88 \
          || MLD_USE_NATIVE_POLY_CADDQ || MLD_USE_NATIVE_POLY_USE_HINT_88 ||   \
          MLD_USE_NATIVE_POLY_USE_HINT_32 || MLD_USE_NATIVE_POLY_CHKNORM ||    \
          MLD_USE_NATIVE_POINTWISE_MONTGOMERY ||                               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7 ||               \
          MLD_USE_NATIVE_POLYZ_UNPACK_17 || MLD_USE_NATIVE_POLYZ_UNPACK_19 */

#if defined(MLD_USE_NATIVE_NTT) || defined(MLD_USE_NATIVE_INTT) ||  \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_32) ||                    \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_88) ||                    \
    defined(MLD_USE_NATIVE_POLY_CADDQ) ||                           \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_88) ||                     \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_32) ||                     \
    defined(MLD_USE_NATIVE_POINTWISE_MONTGOMERY) ||                 \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7) || \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_17) ||                      \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_19)
static int compare_i32_arrays(const int32_t *a, const int32_t *b, unsigned len,
                              const char *test_name, const int32_t *input)
{
  unsigned i;
  for (i = 0; i < len; i++)
  {
    if (a[i] != b[i])
    {
      fprintf(stderr, "FAIL: %s\n", test_name);
      fprintf(stderr,
              "  First difference at index %u: native=%d, reference=%d\n", i,
              a[i], b[i]);
      if (input)
      {
        print_i32_array("Input", input, len);
      }
      print_i32_array("Native result", a, len);
      print_i32_array("Reference result", b, len);
      return 0;
    }
  }
  return 1;
}
#endif /* MLD_USE_NATIVE_NTT || MLD_USE_NATIVE_INTT ||                         \
          MLD_USE_NATIVE_POLY_DECOMPOSE_32 || MLD_USE_NATIVE_POLY_DECOMPOSE_88 \
          || MLD_USE_NATIVE_POLY_CADDQ || MLD_USE_NATIVE_POLY_USE_HINT_88 ||   \
          MLD_USE_NATIVE_POLY_USE_HINT_32 ||                                   \
          MLD_USE_NATIVE_POINTWISE_MONTGOMERY ||                               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7 ||               \
          MLD_USE_NATIVE_POLYZ_UNPACK_17 || MLD_USE_NATIVE_POLYZ_UNPACK_19 */

#ifdef MLD_USE_NATIVE_NTT
static int test_ntt_core(const int32_t *input, const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_poly, mld_poly, 1, NULL);
  MLD_ALLOC(ref_poly, mld_poly, 1, NULL);

  if (test_poly == NULL || ref_poly == NULL)
  {
    goto cleanup;
  }

  memcpy(test_poly->coeffs, input, MLDSA_N * sizeof(int32_t));
  memcpy(ref_poly->coeffs, input, MLDSA_N * sizeof(int32_t));

  mld_poly_ntt(test_poly);
  mld_poly_ntt_c(ref_poly);

#ifdef MLD_USE_NATIVE_NTT_CUSTOM_ORDER
  mld_poly_permute_bitrev_to_custom(ref_poly->coeffs);
#endif

  /* Normalize */
  mld_poly_reduce(ref_poly);
  mld_poly_reduce(test_poly);

  mld_poly_caddq_c(ref_poly);
  mld_poly_caddq_c(test_poly);

  CHECK(compare_i32_arrays(test_poly->coeffs, ref_poly->coeffs, MLDSA_N,
                           test_name, input));
  ret = 0;

cleanup:
  MLD_FREE(ref_poly, mld_poly, 1, NULL);
  MLD_FREE(test_poly, mld_poly, 1, NULL);
  return ret;
}

static int test_native_ntt(void)
{
  int ret = 1;
  int pos, i;
  MLD_ALLOC(test_data, int32_t, MLDSA_N, NULL);

  if (test_data == NULL)
  {
    goto cleanup;
  }

  generate_i32_array_zeros(test_data, MLDSA_N);
  CHECK(test_ntt_core(test_data, "ntt_zeros") == 0);

  for (pos = 0; pos < MLDSA_N; pos += MLDSA_N / 8)
  {
    generate_i32_array_single(test_data, MLDSA_N, (size_t)pos, 1);
    CHECK(test_ntt_core(test_data, "ntt_single") == 0);
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged(test_data, MLDSA_N, -MLDSA_Q + 1, MLDSA_Q);
    CHECK(test_ntt_core(test_data, "ntt_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(test_data, int32_t, MLDSA_N, NULL);
  return ret;
}
#endif /* MLD_USE_NATIVE_NTT */

#ifdef MLD_USE_NATIVE_INTT
static int test_invntt_tomont_core(const int32_t *input, const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_poly, mld_poly, 1, NULL);
  MLD_ALLOC(ref_poly, mld_poly, 1, NULL);

  if (test_poly == NULL || ref_poly == NULL)
  {
    goto cleanup;
  }

  memcpy(test_poly->coeffs, input, MLDSA_N * sizeof(int32_t));
  memcpy(ref_poly->coeffs, input, MLDSA_N * sizeof(int32_t));

#ifdef MLD_USE_NATIVE_NTT_CUSTOM_ORDER
  mld_poly_permute_bitrev_to_custom(test_poly->coeffs);
#endif

  mld_poly_invntt_tomont(test_poly);
  mld_poly_invntt_tomont_c(ref_poly);

  /* Normalize */
  mld_poly_reduce(ref_poly);
  mld_poly_reduce(test_poly);

  mld_poly_caddq_c(ref_poly);
  mld_poly_caddq_c(test_poly);

  CHECK(compare_i32_arrays(test_poly->coeffs, ref_poly->coeffs, MLDSA_N,
                           test_name, input));
  ret = 0;

cleanup:
  MLD_FREE(ref_poly, mld_poly, 1, NULL);
  MLD_FREE(test_poly, mld_poly, 1, NULL);
  return ret;
}

static int test_native_invntt_tomont(void)
{
  int ret = 1;
  int pos, i;
  MLD_ALLOC(test_data, int32_t, MLDSA_N, NULL);

  if (test_data == NULL)
  {
    goto cleanup;
  }

  generate_i32_array_zeros(test_data, MLDSA_N);
  CHECK(test_invntt_tomont_core(test_data, "invntt_tomont_zeros") == 0);

  for (pos = 0; pos < MLDSA_N; pos += MLDSA_N / 8)
  {
    generate_i32_array_single(test_data, MLDSA_N, (size_t)pos, 1);
    CHECK(test_invntt_tomont_core(test_data, "invntt_tomont_single") == 0);
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged(test_data, MLDSA_N, -MLDSA_Q + 1, MLDSA_Q);
    CHECK(test_invntt_tomont_core(test_data, "invntt_tomont_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(test_data, int32_t, MLDSA_N, NULL);
  return ret;
}
#endif /* MLD_USE_NATIVE_INTT */

#if (defined(MLD_USE_NATIVE_POLY_DECOMPOSE_32) ||  \
     defined(MLD_USE_NATIVE_POLY_DECOMPOSE_88)) && \
    !defined(MLD_CONFIG_NO_SIGN_API)
static int test_poly_decompose_core(const mld_poly *input_poly,
                                    const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_a1, mld_poly, 1, NULL);
  MLD_ALLOC(test_a0, mld_poly, 1, NULL);
  MLD_ALLOC(ref_a1, mld_poly, 1, NULL);
  MLD_ALLOC(ref_a0, mld_poly, 1, NULL);

  if (test_a1 == NULL || test_a0 == NULL || ref_a1 == NULL || ref_a0 == NULL)
  {
    goto cleanup;
  }

  mld_memcpy(test_a0, input_poly, sizeof(mld_poly));
  mld_memcpy(ref_a0, input_poly, sizeof(mld_poly));

  mld_poly_decompose(test_a1, test_a0);
  mld_poly_decompose_c(ref_a1, ref_a0);

  CHECK(compare_i32_arrays(test_a1->coeffs, ref_a1->coeffs, MLDSA_N, test_name,
                           input_poly->coeffs));
  CHECK(compare_i32_arrays(test_a0->coeffs, ref_a0->coeffs, MLDSA_N, test_name,
                           input_poly->coeffs));
  ret = 0;

cleanup:
  MLD_FREE(ref_a0, mld_poly, 1, NULL);
  MLD_FREE(ref_a1, mld_poly, 1, NULL);
  MLD_FREE(test_a0, mld_poly, 1, NULL);
  MLD_FREE(test_a1, mld_poly, 1, NULL);
  return ret;
}
static int test_native_decompose(void)
{
  int ret = 1;
  int i;
  MLD_ALLOC(test_poly, mld_poly, 1, NULL);

  if (test_poly == NULL)
  {
    goto cleanup;
  }

  generate_i32_array_zeros(test_poly->coeffs, MLDSA_N);
  CHECK(test_poly_decompose_core(test_poly, "poly_decompose_zeros") == 0);

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged(test_poly->coeffs, MLDSA_N, 0, MLDSA_Q);
    CHECK(test_poly_decompose_core(test_poly, "poly_decompose_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(test_poly, mld_poly, 1, NULL);
  return ret;
}
#endif /* (MLD_USE_NATIVE_POLY_DECOMPOSE_32 || \
          MLD_USE_NATIVE_POLY_DECOMPOSE_88) && !MLD_CONFIG_NO_SIGN_API */

#if defined(MLD_USE_NATIVE_POLY_CADDQ)
static int test_caddq_core(const int32_t *input, const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_poly, mld_poly, 1, NULL);
  MLD_ALLOC(ref_poly, mld_poly, 1, NULL);

  if (test_poly == NULL || ref_poly == NULL)
  {
    goto cleanup;
  }

  memcpy(test_poly->coeffs, input, MLDSA_N * sizeof(int32_t));
  memcpy(ref_poly->coeffs, input, MLDSA_N * sizeof(int32_t));

  mld_poly_caddq(test_poly);
  mld_poly_caddq_c(ref_poly);

  CHECK(compare_i32_arrays(test_poly->coeffs, ref_poly->coeffs, MLDSA_N,
                           test_name, input));
  ret = 0;

cleanup:
  MLD_FREE(ref_poly, mld_poly, 1, NULL);
  MLD_FREE(test_poly, mld_poly, 1, NULL);
  return ret;
}
static int test_native_caddq(void)
{
  int ret = 1;
  int pos, i;
  MLD_ALLOC(test_data, int32_t, MLDSA_N, NULL);

  if (test_data == NULL)
  {
    goto cleanup;
  }

  generate_i32_array_zeros(test_data, MLDSA_N);
  CHECK(test_caddq_core(test_data, "poly_caddq_zeros") == 0);

  for (pos = 0; pos < MLDSA_N; pos += MLDSA_N / 8)
  {
    generate_i32_array_single(test_data, MLDSA_N, (size_t)pos, 1);
    CHECK(test_caddq_core(test_data, "poly_caddq_single") == 0);
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged(test_data, MLDSA_N, -MLDSA_Q + 1, MLDSA_Q);
    CHECK(test_caddq_core(test_data, "poly_caddq_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(test_data, int32_t, MLDSA_N, NULL);
  return ret;
}
#endif /* MLD_USE_NATIVE_POLY_CADDQ */

#if (defined(MLD_USE_NATIVE_POLY_USE_HINT_88) ||  \
     defined(MLD_USE_NATIVE_POLY_USE_HINT_32)) && \
    !defined(MLD_CONFIG_NO_VERIFY_API)
static int test_poly_use_hint_core(const mld_poly *poly_a,
                                   const mld_poly *poly_h,
                                   const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_a, mld_poly, 1, NULL);
  MLD_ALLOC(ref_a, mld_poly, 1, NULL);

  if (test_a == NULL || ref_a == NULL)
  {
    goto cleanup;
  }

  *test_a = *poly_a;
  *ref_a = *poly_a;
  mld_poly_use_hint(test_a, poly_h);
  mld_poly_use_hint_c(ref_a, poly_h);

  CHECK(compare_i32_arrays(test_a->coeffs, ref_a->coeffs, MLDSA_N, test_name,
                           poly_a->coeffs));
  ret = 0;

cleanup:
  MLD_FREE(ref_a, mld_poly, 1, NULL);
  MLD_FREE(test_a, mld_poly, 1, NULL);
  return ret;
}
static int test_native_use_hint(void)
{
  int ret = 1;
  int i;
  MLD_ALLOC(poly_a, mld_poly, 1, NULL);
  MLD_ALLOC(poly_h, mld_poly, 1, NULL);

  if (poly_a == NULL || poly_h == NULL)
  {
    goto cleanup;
  }

  generate_i32_array_zeros(poly_a->coeffs, MLDSA_N);
  generate_i32_array_zeros(poly_h->coeffs, MLDSA_N);
  CHECK(test_poly_use_hint_core(poly_a, poly_h, "poly_use_hint_zeros") == 0);

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged(poly_a->coeffs, MLDSA_N, 0, MLDSA_Q);
    generate_i32_array_ranged(poly_h->coeffs, MLDSA_N, 0, 2);
    CHECK(test_poly_use_hint_core(poly_a, poly_h, "poly_use_hint_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(poly_h, mld_poly, 1, NULL);
  MLD_FREE(poly_a, mld_poly, 1, NULL);
  return ret;
}
#endif /* (MLD_USE_NATIVE_POLY_USE_HINT_88 || MLD_USE_NATIVE_POLY_USE_HINT_32) \
          && !MLD_CONFIG_NO_VERIFY_API */

#if defined(MLD_USE_NATIVE_POLY_CHKNORM)
static int test_poly_chknorm_core(const mld_poly *input_poly, int32_t B,
                                  const char *test_name)
{
  uint32_t test_result, ref_result;

  test_result = mld_poly_chknorm(input_poly, B);
  ref_result = mld_poly_chknorm_c(input_poly, B);

  if (test_result != ref_result)
  {
    fprintf(stderr, "FAIL: %s - result mismatch: native=%u, ref=%u\n",
            test_name, test_result, ref_result);
    return 1;
  }

  return 0;
}

static int test_native_poly_chknorm(void)
{
  int ret = 1;
  int i;
  MLD_ALLOC(test_poly, mld_poly, 1, NULL);

  if (test_poly == NULL)
  {
    goto cleanup;
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged(test_poly->coeffs, MLDSA_N,
                              -MLD_REDUCE32_RANGE_MAX, MLD_REDUCE32_RANGE_MAX);
    CHECK(test_poly_chknorm_core(test_poly, MLDSA_Q - MLD_REDUCE32_RANGE_MAX,
                                 "poly_chknorm_MAX_B") == 0);
    CHECK(test_poly_chknorm_core(test_poly, MLDSA_GAMMA1 - MLDSA_BETA,
                                 "poly_chknorm_gamma1_minus_beta") == 0);
    CHECK(test_poly_chknorm_core(test_poly, MLDSA_GAMMA2 - MLDSA_BETA,
                                 "poly_chknorm_gamma2_minus_beta") == 0);
    CHECK(test_poly_chknorm_core(test_poly, MLDSA_GAMMA2,
                                 "poly_chknorm_gamma2") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(test_poly, mld_poly, 1, NULL);
  return ret;
}
#endif /* MLD_USE_NATIVE_POLY_CHKNORM */

#if defined(MLD_USE_NATIVE_POINTWISE_MONTGOMERY) && \
    (!defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API))
static int test_poly_pointwise_montgomery_core(const mld_poly *poly_a,
                                               const mld_poly *poly_b,
                                               const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_poly_c, mld_poly, 1, NULL);
  MLD_ALLOC(ref_poly_c, mld_poly, 1, NULL);

  if (test_poly_c == NULL || ref_poly_c == NULL)
  {
    goto cleanup;
  }

  *test_poly_c = *poly_a;
  *ref_poly_c = *poly_a;
  mld_poly_pointwise_montgomery(test_poly_c, poly_b);
  mld_poly_pointwise_montgomery_c(ref_poly_c, poly_b);

  CHECK(compare_i32_arrays(test_poly_c->coeffs, ref_poly_c->coeffs, MLDSA_N,
                           test_name, poly_a->coeffs));
  ret = 0;

cleanup:
  MLD_FREE(ref_poly_c, mld_poly, 1, NULL);
  MLD_FREE(test_poly_c, mld_poly, 1, NULL);
  return ret;
}

static int test_native_pointwise_montgomery(void)
{
  int ret = 1;
  int pos, i;
  MLD_ALLOC(test_poly_a, mld_poly, 1, NULL);
  MLD_ALLOC(test_poly_b, mld_poly, 1, NULL);

  if (test_poly_a == NULL || test_poly_b == NULL)
  {
    goto cleanup;
  }

  generate_i32_array_zeros(test_poly_a->coeffs, MLDSA_N);
  generate_i32_array_zeros(test_poly_b->coeffs, MLDSA_N);
  CHECK(test_poly_pointwise_montgomery_core(test_poly_a, test_poly_b,
                                            "pointwise_montgomery_zeros") == 0);

  for (pos = 0; pos < MLDSA_N; pos += MLDSA_N / 8)
  {
    generate_i32_array_single(test_poly_a->coeffs, MLDSA_N, (size_t)pos, 1);
    generate_i32_array_single(test_poly_b->coeffs, MLDSA_N, (size_t)pos, 1);
    CHECK(test_poly_pointwise_montgomery_core(
              test_poly_a, test_poly_b, "pointwise_montgomery_single") == 0);
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged(test_poly_a->coeffs, MLDSA_N,
                              -(MLD_NTT_BOUND - 1), MLD_NTT_BOUND);
    generate_i32_array_ranged(test_poly_b->coeffs, MLDSA_N,
                              -(MLD_NTT_BOUND - 1), MLD_NTT_BOUND);
    CHECK(test_poly_pointwise_montgomery_core(
              test_poly_a, test_poly_b, "pointwise_montgomery_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(test_poly_b, mld_poly, 1, NULL);
  MLD_FREE(test_poly_a, mld_poly, 1, NULL);
  return ret;
}
#endif /* MLD_USE_NATIVE_POINTWISE_MONTGOMERY && (!MLD_CONFIG_NO_SIGN_API || \
          !MLD_CONFIG_NO_VERIFY_API) */

#if defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7)
static int test_polyvecl_pointwise_acc_montgomery_core(const mld_polyvecl *u,
                                                       const mld_polyvecl *v,
                                                       const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_w, mld_poly, 1, NULL);
  MLD_ALLOC(ref_w, mld_poly, 1, NULL);

  if (test_w == NULL || ref_w == NULL)
  {
    goto cleanup;
  }

  mld_polyvecl_pointwise_acc_montgomery(test_w, u, v);
  mld_polyvecl_pointwise_acc_montgomery_c(ref_w, u, v);

  CHECK(compare_i32_arrays(test_w->coeffs, ref_w->coeffs, MLDSA_N, test_name,
                           NULL));
  ret = 0;

cleanup:
  MLD_FREE(ref_w, mld_poly, 1, NULL);
  MLD_FREE(test_w, mld_poly, 1, NULL);
  return ret;
}

static int test_native_polyvecl_pointwise_acc_montgomery(void)
{
  int ret = 1;
  unsigned int i;
  MLD_ALLOC(u, mld_polyvecl, 1, NULL);
  MLD_ALLOC(v, mld_polyvecl, 1, NULL);

  if (u == NULL || v == NULL)
  {
    goto cleanup;
  }

  /* Test with zeros */
  generate_i32_array_zeros((int32_t *)u, MLDSA_L * MLDSA_N);
  generate_i32_array_zeros((int32_t *)v, MLDSA_L * MLDSA_N);
  CHECK(test_polyvecl_pointwise_acc_montgomery_core(u, v,
                                                    "polyvecl_acc_zeros") == 0);

  /* Test with random values */
  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    generate_i32_array_ranged((int32_t *)u, MLDSA_L * MLDSA_N, 0, MLDSA_Q);
    generate_i32_array_ranged((int32_t *)v, MLDSA_L * MLDSA_N,
                              -MLD_NTT_BOUND + 1, MLD_NTT_BOUND);
    CHECK(test_polyvecl_pointwise_acc_montgomery_core(
              u, v, "polyvecl_acc_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(v, mld_polyvecl, 1, NULL);
  MLD_FREE(u, mld_polyvecl, 1, NULL);
  return ret;
}
#endif /* MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4 || \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5 || \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7 */


#if (defined(MLD_USE_NATIVE_POLYZ_UNPACK_17) ||  \
     defined(MLD_USE_NATIVE_POLYZ_UNPACK_19)) && \
    (!defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API))
static int test_mld_polyz_unpack_core(const uint8_t *input,
                                      const char *test_name)
{
  int ret = 1;
  MLD_ALLOC(test_poly, mld_poly, 1, NULL);
  MLD_ALLOC(ref_poly, mld_poly, 1, NULL);

  if (test_poly == NULL || ref_poly == NULL)
  {
    goto cleanup;
  }

  mld_polyz_unpack(test_poly, input);
  mld_polyz_unpack_c(ref_poly, input);

  CHECK(compare_i32_arrays(test_poly->coeffs, ref_poly->coeffs, MLDSA_N,
                           test_name, NULL));
  ret = 0;

cleanup:
  MLD_FREE(ref_poly, mld_poly, 1, NULL);
  MLD_FREE(test_poly, mld_poly, 1, NULL);
  return ret;
}

static int test_native_polyz_unpack(void)
{
  int ret = 1;
  int i;
  MLD_ALLOC(test_bytes, uint8_t, MLDSA_POLYZ_PACKEDBYTES, NULL);

  if (test_bytes == NULL)
  {
    goto cleanup;
  }

  memset(test_bytes, 0, MLDSA_POLYZ_PACKEDBYTES);
  CHECK(test_mld_polyz_unpack_core(test_bytes, "polyz_unpack_zeros") == 0);


  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    randombytes(test_bytes, MLDSA_POLYZ_PACKEDBYTES);
    CHECK(test_mld_polyz_unpack_core(test_bytes, "polyz_unpack_random") == 0);
  }

  ret = 0;

cleanup:
  MLD_FREE(test_bytes, uint8_t, MLDSA_POLYZ_PACKEDBYTES, NULL);
  return ret;
}
#endif /* (MLD_USE_NATIVE_POLYZ_UNPACK_17 || MLD_USE_NATIVE_POLYZ_UNPACK_19) \
          && (!MLD_CONFIG_NO_SIGN_API || !MLD_CONFIG_NO_VERIFY_API) */

#ifdef MLD_USE_NATIVE_REJ_UNIFORM
#define DEFINE_REJ_UNIFORM_TEST(NBLOCKS)                                 \
  static int test_native_rej_uniform_nblocks_##NBLOCKS(void)             \
  {                                                                      \
    const unsigned buflen = (NBLOCKS) * 168; /* SHAKE128_RATE */         \
    int ret = 1;                                                         \
    int i;                                                               \
    MLD_ALLOC(r_test, int32_t, MLDSA_N, NULL);                           \
    MLD_ALLOC(r_ref, int32_t, MLDSA_N, NULL);                            \
    MLD_ALLOC(buf, uint8_t, (NBLOCKS) * 168, NULL);                      \
                                                                         \
    if (r_test == NULL || r_ref == NULL || buf == NULL)                  \
    {                                                                    \
      goto cleanup;                                                      \
    }                                                                    \
                                                                         \
    for (i = 0; i < NUM_RANDOM_TESTS; i++)                               \
    {                                                                    \
      int native_ret;                                                    \
      unsigned c_ret;                                                    \
      randombytes(buf, buflen);                                          \
                                                                         \
      native_ret = mld_rej_uniform_native(r_test, MLDSA_N, buf, buflen); \
      if (native_ret == MLD_NATIVE_FUNC_FALLBACK)                        \
      {                                                                  \
        ret = 0;                                                         \
        goto cleanup;                                                    \
      }                                                                  \
                                                                         \
      c_ret = mld_rej_uniform_c(r_ref, MLDSA_N, 0, buf, buflen);         \
                                                                         \
      CHECK((unsigned)native_ret == c_ret);                              \
      CHECK(compare_i32_arrays(r_test, r_ref, (unsigned)native_ret,      \
                               "rej_uniform", NULL));                    \
    }                                                                    \
                                                                         \
    ret = 0;                                                             \
                                                                         \
  cleanup:                                                               \
    MLD_FREE(buf, uint8_t, (NBLOCKS) * 168, NULL);                       \
    MLD_FREE(r_ref, int32_t, MLDSA_N, NULL);                             \
    MLD_FREE(r_test, int32_t, MLDSA_N, NULL);                            \
    return ret;                                                          \
  }

DEFINE_REJ_UNIFORM_TEST(1)
DEFINE_REJ_UNIFORM_TEST(2)
DEFINE_REJ_UNIFORM_TEST(3)
DEFINE_REJ_UNIFORM_TEST(4)
DEFINE_REJ_UNIFORM_TEST(5)
#endif /* MLD_USE_NATIVE_REJ_UNIFORM */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
#if defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA2) && MLDSA_ETA == 2
#define REJ_UNIFORM_ETA2_BUFLEN 136 /* 1 * SHAKE256_RATE */
static int test_native_rej_uniform_eta2(void)
{
  int ret = 1;
  int i;
  MLD_ALLOC(r_test, int32_t, MLDSA_N, NULL);
  MLD_ALLOC(r_ref, int32_t, MLDSA_N, NULL);
  MLD_ALLOC(buf, uint8_t, REJ_UNIFORM_ETA2_BUFLEN, NULL);

  if (r_test == NULL || r_ref == NULL || buf == NULL)
  {
    goto cleanup;
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    int native_ret;
    unsigned c_ret;
    randombytes(buf, REJ_UNIFORM_ETA2_BUFLEN);

    native_ret = mld_rej_uniform_eta2_native(r_test, MLDSA_N, buf,
                                             REJ_UNIFORM_ETA2_BUFLEN);
    if (native_ret == MLD_NATIVE_FUNC_FALLBACK)
    {
      ret = 0;
      goto cleanup;
    }

    c_ret = mld_rej_eta_c(r_ref, MLDSA_N, 0, buf, REJ_UNIFORM_ETA2_BUFLEN);

    CHECK((unsigned)native_ret == c_ret);
    CHECK(compare_i32_arrays(r_test, r_ref, (unsigned)native_ret,
                             "rej_uniform_eta2", NULL));
  }

  ret = 0;

cleanup:
  MLD_FREE(buf, uint8_t, REJ_UNIFORM_ETA2_BUFLEN, NULL);
  MLD_FREE(r_ref, int32_t, MLDSA_N, NULL);
  MLD_FREE(r_test, int32_t, MLDSA_N, NULL);
  return ret;
}
#undef REJ_UNIFORM_ETA2_BUFLEN
#endif /* MLD_USE_NATIVE_REJ_UNIFORM_ETA2 && MLDSA_ETA == 2 */

#if defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA4) && MLDSA_ETA == 4
#define REJ_UNIFORM_ETA4_BUFLEN 272 /* 2 * SHAKE256_RATE */
static int test_native_rej_uniform_eta4(void)
{
  int ret = 1;
  int i;
  MLD_ALLOC(r_test, int32_t, MLDSA_N, NULL);
  MLD_ALLOC(r_ref, int32_t, MLDSA_N, NULL);
  MLD_ALLOC(buf, uint8_t, REJ_UNIFORM_ETA4_BUFLEN, NULL);

  if (r_test == NULL || r_ref == NULL || buf == NULL)
  {
    goto cleanup;
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    int native_ret;
    unsigned c_ret;
    randombytes(buf, REJ_UNIFORM_ETA4_BUFLEN);

    native_ret = mld_rej_uniform_eta4_native(r_test, MLDSA_N, buf,
                                             REJ_UNIFORM_ETA4_BUFLEN);
    if (native_ret == MLD_NATIVE_FUNC_FALLBACK)
    {
      ret = 0;
      goto cleanup;
    }

    c_ret = mld_rej_eta_c(r_ref, MLDSA_N, 0, buf, REJ_UNIFORM_ETA4_BUFLEN);

    CHECK((unsigned)native_ret == c_ret);
    CHECK(compare_i32_arrays(r_test, r_ref, (unsigned)native_ret,
                             "rej_uniform_eta4", NULL));
  }

  ret = 0;

cleanup:
  MLD_FREE(buf, uint8_t, REJ_UNIFORM_ETA4_BUFLEN, NULL);
  MLD_FREE(r_ref, int32_t, MLDSA_N, NULL);
  MLD_FREE(r_test, int32_t, MLDSA_N, NULL);
  return ret;
}
#undef REJ_UNIFORM_ETA4_BUFLEN
#endif /* MLD_USE_NATIVE_REJ_UNIFORM_ETA4 && MLDSA_ETA == 4 */
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */


#ifdef MLD_USE_NATIVE_FIPS202_X1
static int test_keccakf1600_permute(void)
{
  int ret = 1;
  int i;
  MLD_ALLOC(state, uint64_t, MLD_KECCAK_LANES, NULL);
  MLD_ALLOC(state_ref, uint64_t, MLD_KECCAK_LANES, NULL);

  if (state == NULL || state_ref == NULL)
  {
    goto cleanup;
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    randombytes((uint8_t *)state, MLD_KECCAK_LANES * sizeof(uint64_t));
    memcpy(state_ref, state, MLD_KECCAK_LANES * sizeof(uint64_t));

    mld_keccakf1600_permute(state);
    mld_keccakf1600_permute_c(state_ref);

    CHECK(compare_u64_arrays(state, state_ref, MLD_KECCAK_LANES,
                             "keccakf1600_permute"));
  }

  ret = 0;

cleanup:
  MLD_FREE(state_ref, uint64_t, MLD_KECCAK_LANES, NULL);
  MLD_FREE(state, uint64_t, MLD_KECCAK_LANES, NULL);
  return ret;
}
#endif /* MLD_USE_NATIVE_FIPS202_X1 */

/*
 * Test that x4 Keccak (xor_bytes, permute, extract_bytes) produces
 * the same results as the x1 C reference.
 */
#ifdef MLD_USE_NATIVE_FIPS202_X4
#define MAX_RATE 136

static int test_keccakf1600x4_xor_permute_extract(void)
{
  int ret = 1;
  int i, j;
  unsigned char output_x4[MLD_KECCAK_WAY][MAX_RATE];
  unsigned char output_x1[MAX_RATE];
  unsigned char input[MLD_KECCAK_WAY][MAX_RATE];
  uint8_t xor_offset, xor_length, ext_offset, ext_length;
  MLD_ALLOC(state_x4, uint64_t, MLD_KECCAK_LANES *MLD_KECCAK_WAY, NULL);
  MLD_ALLOC(state_x1, uint64_t, MLD_KECCAK_LANES, NULL);

  if (state_x4 == NULL || state_x1 == NULL)
  {
    goto cleanup;
  }

  for (i = 0; i < NUM_RANDOM_TESTS; i++)
  {
    /* Generate random offset and length for xor_bytes */
    randombytes(&xor_offset, 1);
    randombytes(&xor_length, 1);
    xor_offset = xor_offset % MAX_RATE;
    xor_length = (uint8_t)(1 + (xor_length % (MAX_RATE - xor_offset)));

    /* Generate random offset and length for extract_bytes */
    randombytes(&ext_offset, 1);
    randombytes(&ext_length, 1);
    ext_offset = ext_offset % MAX_RATE;
    ext_length = (uint8_t)(1 + (ext_length % (MAX_RATE - ext_offset)));

    /* Generate different random input for each lane */
    for (j = 0; j < MLD_KECCAK_WAY; j++)
    {
      randombytes(input[j], xor_length);
    }

    /* Run x4 implementation */
    memset(state_x4, 0, MLD_KECCAK_LANES * MLD_KECCAK_WAY * sizeof(uint64_t));
    mld_keccakf1600x4_xor_bytes(state_x4, input[0], input[1], input[2],
                                input[3], xor_offset, xor_length);
    mld_keccakf1600x4_permute(state_x4);
    mld_keccakf1600x4_extract_bytes(state_x4, output_x4[0], output_x4[1],
                                    output_x4[2], output_x4[3], ext_offset,
                                    ext_length);

    /* Compare each lane against x1 C reference */
    for (j = 0; j < MLD_KECCAK_WAY; j++)
    {
      memset(state_x1, 0, MLD_KECCAK_LANES * sizeof(uint64_t));
      mld_keccakf1600_xor_bytes(state_x1, input[j], xor_offset, xor_length);
      mld_keccakf1600_permute_c(state_x1);
      mld_keccakf1600_extract_bytes(state_x1, output_x1, ext_offset,
                                    ext_length);

      CHECK(memcmp(output_x4[j], output_x1, ext_length) == 0);
    }
  }

  ret = 0;

cleanup:
  MLD_FREE(state_x1, uint64_t, MLD_KECCAK_LANES, NULL);
  MLD_FREE(state_x4, uint64_t, MLD_KECCAK_LANES *MLD_KECCAK_WAY, NULL);
  return ret;
}

#undef MAX_RATE
#endif /* MLD_USE_NATIVE_FIPS202_X4 */

static int test_backend_units(void)
{
  /* Set fixed seed for reproducible tests */
  randombytes_reset();


#ifdef MLD_USE_NATIVE_NTT
  CHECK(test_native_ntt() == 0);
#endif

#ifdef MLD_USE_NATIVE_INTT
  CHECK(test_native_invntt_tomont() == 0);
#endif

#if (defined(MLD_USE_NATIVE_POLY_DECOMPOSE_32) ||  \
     defined(MLD_USE_NATIVE_POLY_DECOMPOSE_88)) && \
    !defined(MLD_CONFIG_NO_SIGN_API)
  CHECK(test_native_decompose() == 0);
#endif

#ifdef MLD_USE_NATIVE_POLY_CADDQ
  CHECK(test_native_caddq() == 0);
#endif

#if (defined(MLD_USE_NATIVE_POLY_USE_HINT_88) ||  \
     defined(MLD_USE_NATIVE_POLY_USE_HINT_32)) && \
    !defined(MLD_CONFIG_NO_VERIFY_API)
  CHECK(test_native_use_hint() == 0);
#endif

#if defined(MLD_USE_NATIVE_POLY_CHKNORM)
  CHECK(test_native_poly_chknorm() == 0);
#endif

#if defined(MLD_USE_NATIVE_POINTWISE_MONTGOMERY) && \
    (!defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API))
  CHECK(test_native_pointwise_montgomery() == 0);
#endif

#if defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7)
  CHECK(test_native_polyvecl_pointwise_acc_montgomery() == 0);
#endif

#if (defined(MLD_USE_NATIVE_POLYZ_UNPACK_17) ||  \
     defined(MLD_USE_NATIVE_POLYZ_UNPACK_19)) && \
    (!defined(MLD_CONFIG_NO_SIGN_API) || !defined(MLD_CONFIG_NO_VERIFY_API))
  CHECK(test_native_polyz_unpack() == 0);
#endif

#ifdef MLD_USE_NATIVE_REJ_UNIFORM
  CHECK(test_native_rej_uniform_nblocks_1() == 0);
  CHECK(test_native_rej_uniform_nblocks_2() == 0);
  CHECK(test_native_rej_uniform_nblocks_3() == 0);
  CHECK(test_native_rej_uniform_nblocks_4() == 0);
  CHECK(test_native_rej_uniform_nblocks_5() == 0);
#endif /* MLD_USE_NATIVE_REJ_UNIFORM */

#if !defined(MLD_CONFIG_NO_KEYPAIR_API)
#if defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA2) && MLDSA_ETA == 2
  CHECK(test_native_rej_uniform_eta2() == 0);
#endif
#if defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA4) && MLDSA_ETA == 4
  CHECK(test_native_rej_uniform_eta4() == 0);
#endif
#endif /* !MLD_CONFIG_NO_KEYPAIR_API */

#ifdef MLD_USE_NATIVE_FIPS202_X1
  CHECK(test_keccakf1600_permute() == 0);
#endif

#ifdef MLD_USE_NATIVE_FIPS202_X4
  CHECK(test_keccakf1600x4_xor_permute_extract() == 0);
#endif

  return 0;
}
#endif /* MLD_USE_NATIVE_NTT || MLD_USE_NATIVE_INTT ||                         \
          MLD_USE_NATIVE_POLY_DECOMPOSE_32 || MLD_USE_NATIVE_POLY_DECOMPOSE_88 \
          || MLD_USE_NATIVE_POLY_CADDQ || MLD_USE_NATIVE_POLY_USE_HINT_88 ||   \
          MLD_USE_NATIVE_POLY_USE_HINT_32 || MLD_USE_NATIVE_POLY_CHKNORM ||    \
          MLD_USE_NATIVE_POINTWISE_MONTGOMERY ||                               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7 ||               \
          MLD_USE_NATIVE_POLYZ_UNPACK_17 || MLD_USE_NATIVE_POLYZ_UNPACK_19 ||  \
          MLD_USE_NATIVE_REJ_UNIFORM || MLD_USE_NATIVE_REJ_UNIFORM_ETA2 ||     \
          MLD_USE_NATIVE_REJ_UNIFORM_ETA4 || MLD_USE_NATIVE_FIPS202_X1 ||      \
          MLD_USE_NATIVE_FIPS202_X4 */

#if !defined(MLD_CONFIG_NO_SIGN_API)
/* Test that eager and lazy polyvec init+get produce the same results */
/* This test keeps the large ML-DSA-87 workspace static to avoid test harness
 * stack pressure when the Zephyr FIPS202 backend is enabled. */
#define TEST_STATIC_ALLOC(v, T, N)      \
  static MLD_ALIGN T mld_static_##v[N]; \
  T *v = mld_static_##v
#define TEST_STATIC_FREE(v)                              \
  do                                                     \
  {                                                      \
    mld_zeroize(mld_static_##v, sizeof(mld_static_##v)); \
    (v) = NULL;                                          \
  } while (0)

static int test_polyvec_lazy_eager(void)
{
  int ret = 1;
  unsigned int i, t;
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
  unsigned int j;
#endif
  TEST_STATIC_ALLOC(packed_s1, uint8_t, MLDSA_L *MLDSA_POLYETA_PACKEDBYTES);
  TEST_STATIC_ALLOC(packed_s2, uint8_t, MLDSA_K *MLDSA_POLYETA_PACKEDBYTES);
  TEST_STATIC_ALLOC(packed_t0, uint8_t, MLDSA_K *MLDSA_POLYT0_PACKEDBYTES);
  TEST_STATIC_ALLOC(rho, uint8_t, MLDSA_SEEDBYTES);
  TEST_STATIC_ALLOC(rhoprime, uint8_t, MLDSA_CRHBYTES);
  TEST_STATIC_ALLOC(s1_eager, mld_sk_s1hat_eager, 1);
  TEST_STATIC_ALLOC(s1_lazy, mld_sk_s1hat_lazy, 1);
  TEST_STATIC_ALLOC(s2_eager, mld_sk_s2hat_eager, 1);
  TEST_STATIC_ALLOC(s2_lazy, mld_sk_s2hat_lazy, 1);
  TEST_STATIC_ALLOC(t0_eager, mld_sk_t0hat_eager, 1);
  TEST_STATIC_ALLOC(t0_lazy, mld_sk_t0hat_lazy, 1);
  TEST_STATIC_ALLOC(y_eager, mld_yvec_eager, 1);
  TEST_STATIC_ALLOC(y_lazy, mld_yvec_lazy, 1);
  TEST_STATIC_ALLOC(poly_eager, mld_poly, 1);
  TEST_STATIC_ALLOC(poly_lazy, mld_poly, 1);
  TEST_STATIC_ALLOC(mat_eager, mld_polymat_eager, 1);
  TEST_STATIC_ALLOC(mat_lazy, mld_polymat_lazy, 1);
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
  TEST_STATIC_ALLOC(v, mld_polyvecl, 1);
#endif
  TEST_STATIC_ALLOC(scratch_eager, mld_polyvecl, 1);
  TEST_STATIC_ALLOC(scratch_lazy, mld_polyvecl, 1);
  TEST_STATIC_ALLOC(w_eager, mld_polyveck, 1);
  TEST_STATIC_ALLOC(w_lazy, mld_polyveck, 1);

  for (t = 0; t < NUM_RANDOM_TESTS_SLOW; t++)
  {
    /* Test s1vec: eager vs lazy */
    randombytes(packed_s1, MLDSA_L * MLDSA_POLYETA_PACKEDBYTES);
    mld_unpack_sk_s1hat_eager(s1_eager, packed_s1);
    mld_unpack_sk_s1hat_lazy(s1_lazy, packed_s1);

    for (i = 0; i < MLDSA_L; i++)
    {
      mld_sk_s1hat_get_poly_eager(poly_eager, s1_eager, i);
      mld_sk_s1hat_get_poly_lazy(poly_lazy, s1_lazy, i);
      CHECK(memcmp(poly_eager, poly_lazy, sizeof(mld_poly)) == 0);
    }

    /* Test s2vec: eager vs lazy */
    randombytes(packed_s2, MLDSA_K * MLDSA_POLYETA_PACKEDBYTES);
    mld_unpack_sk_s2hat_eager(s2_eager, packed_s2);
    mld_unpack_sk_s2hat_lazy(s2_lazy, packed_s2);

    for (i = 0; i < MLDSA_K; i++)
    {
      mld_sk_s2hat_get_poly_eager(poly_eager, s2_eager, i);
      mld_sk_s2hat_get_poly_lazy(poly_lazy, s2_lazy, i);
      CHECK(memcmp(poly_eager, poly_lazy, sizeof(mld_poly)) == 0);
    }

    /* Test t0vec: eager vs lazy */
    randombytes(packed_t0, MLDSA_K * MLDSA_POLYT0_PACKEDBYTES);
    mld_unpack_sk_t0hat_eager(t0_eager, packed_t0);
    mld_unpack_sk_t0hat_lazy(t0_lazy, packed_t0);

    for (i = 0; i < MLDSA_K; i++)
    {
      mld_sk_t0hat_get_poly_eager(poly_eager, t0_eager, i);
      mld_sk_t0hat_get_poly_lazy(poly_lazy, t0_lazy, i);
      CHECK(memcmp(poly_eager, poly_lazy, sizeof(mld_poly)) == 0);
    }
  }

#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
  /* Test row helpers: eager vs lazy. Both compute one row of A * v in
   * Montgomery (NTT domain), reduced mod q, but with different storage
   * strategies for A. */
  for (t = 0; t < NUM_RANDOM_TESTS_SLOW; t++)
  {
    randombytes(rho, MLDSA_SEEDBYTES);
    mld_polyvec_matrix_expand_eager(mat_eager, rho);
    mld_polyvec_matrix_expand_lazy(mat_lazy, rho);

    randombytes((uint8_t *)v, sizeof(mld_polyvecl));
    for (i = 0; i < MLDSA_L; i++)
    {
      for (j = 0; j < MLDSA_N; j++)
      {
        v->vec[i].coeffs[j] %= MLD_NTT_BOUND;
      }
    }

    for (i = 0; i < MLDSA_K; i++)
    {
      mld_polyvec_matrix_pointwise_montgomery_row_eager(poly_eager, mat_eager,
                                                        v, i);
      mld_polyvec_matrix_pointwise_montgomery_row_lazy(poly_lazy, mat_lazy, v,
                                                       i);
      /* Compare mod q */
      mld_poly_caddq(poly_eager);
      mld_poly_caddq(poly_lazy);
      CHECK(memcmp(poly_eager, poly_lazy, sizeof(mld_poly)) == 0);
    }
  }
#endif /* !MLD_CONFIG_NO_KEYPAIR_API || !MLD_CONFIG_NO_VERIFY_API */

  /* Test yvec: eager vs lazy. Verify that mld_yvec_get_poly_eager and
   * mld_yvec_get_poly_lazy produce the same y[i], and that the matrix-vector
   * multiplication via the yvec helper produces the same w. */
  for (t = 0; t < NUM_RANDOM_TESTS_SLOW; t++)
  {
    randombytes(rhoprime, MLDSA_CRHBYTES);

    mld_yvec_init_eager(y_eager, rhoprime, 0);
    mld_yvec_init_lazy(y_lazy, rhoprime, 0);

    for (i = 0; i < MLDSA_L; i++)
    {
      mld_yvec_get_poly_eager(poly_eager, y_eager, i);
      mld_yvec_get_poly_lazy(poly_lazy, y_lazy, i);
      CHECK(memcmp(poly_eager, poly_lazy, sizeof(mld_poly)) == 0);
    }

    randombytes(rho, MLDSA_SEEDBYTES);
    mld_polyvec_matrix_expand_eager(mat_eager, rho);
    mld_polyvec_matrix_expand_lazy(mat_lazy, rho);

    mld_polyvec_matrix_pointwise_montgomery_yvec_eager(w_eager, mat_eager,
                                                       y_eager, scratch_eager);
    mld_polyvec_matrix_pointwise_montgomery_yvec_lazy(w_lazy, mat_lazy, y_lazy,
                                                      scratch_lazy);

    /* Compare mod q */
    mld_polyveck_reduce(w_eager);
    mld_polyveck_reduce(w_lazy);
    mld_polyveck_caddq(w_eager);
    mld_polyveck_caddq(w_lazy);
    CHECK(memcmp(w_eager, w_lazy, sizeof(mld_polyveck)) == 0);
  }

  ret = 0;

  TEST_STATIC_FREE(w_lazy);
  TEST_STATIC_FREE(w_eager);
  TEST_STATIC_FREE(scratch_lazy);
  TEST_STATIC_FREE(scratch_eager);
#if !defined(MLD_CONFIG_NO_KEYPAIR_API) || !defined(MLD_CONFIG_NO_VERIFY_API)
  TEST_STATIC_FREE(v);
#endif
  TEST_STATIC_FREE(mat_lazy);
  TEST_STATIC_FREE(mat_eager);
  TEST_STATIC_FREE(poly_lazy);
  TEST_STATIC_FREE(poly_eager);
  TEST_STATIC_FREE(y_lazy);
  TEST_STATIC_FREE(y_eager);
  TEST_STATIC_FREE(t0_lazy);
  TEST_STATIC_FREE(t0_eager);
  TEST_STATIC_FREE(s2_lazy);
  TEST_STATIC_FREE(s2_eager);
  TEST_STATIC_FREE(s1_lazy);
  TEST_STATIC_FREE(s1_eager);
  TEST_STATIC_FREE(rhoprime);
  TEST_STATIC_FREE(rho);
  TEST_STATIC_FREE(packed_t0);
  TEST_STATIC_FREE(packed_s2);
  TEST_STATIC_FREE(packed_s1);
  return ret;
}
#undef TEST_STATIC_FREE
#undef TEST_STATIC_ALLOC
#endif /* !MLD_CONFIG_NO_SIGN_API */

/* Prototype for a re-#define'd main, to satisfy -Wmissing-prototypes. */
#if defined(main)
int main(void);
#endif
int main(void)
{
  /* WARNING: Test-only
   * Normally, you would want to seed a PRNG with trustworthy entropy here. */
  randombytes_reset();

#if !defined(MLD_CONFIG_NO_SIGN_API)
  CHECK(test_polyvec_lazy_eager() == 0);
#endif

  /* Run backend unit tests */
#if defined(MLD_USE_NATIVE_NTT) || defined(MLD_USE_NATIVE_INTT) ||  \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_32) ||                    \
    defined(MLD_USE_NATIVE_POLY_DECOMPOSE_88) ||                    \
    defined(MLD_USE_NATIVE_POLY_CADDQ) ||                           \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_88) ||                     \
    defined(MLD_USE_NATIVE_POLY_USE_HINT_32) ||                     \
    defined(MLD_USE_NATIVE_POLY_CHKNORM) ||                         \
    defined(MLD_USE_NATIVE_POINTWISE_MONTGOMERY) ||                 \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5) || \
    defined(MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7) || \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_17) ||                      \
    defined(MLD_USE_NATIVE_POLYZ_UNPACK_19) ||                      \
    defined(MLD_USE_NATIVE_REJ_UNIFORM) ||                          \
    defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA2) ||                     \
    defined(MLD_USE_NATIVE_REJ_UNIFORM_ETA4) ||                     \
    defined(MLD_USE_NATIVE_FIPS202_X1) || defined(MLD_USE_NATIVE_FIPS202_X4)
  CHECK(test_backend_units() == 0);
#endif /* MLD_USE_NATIVE_NTT || MLD_USE_NATIVE_INTT ||                         \
          MLD_USE_NATIVE_POLY_DECOMPOSE_32 || MLD_USE_NATIVE_POLY_DECOMPOSE_88 \
          || MLD_USE_NATIVE_POLY_CADDQ || MLD_USE_NATIVE_POLY_USE_HINT_88 ||   \
          MLD_USE_NATIVE_POLY_USE_HINT_32 || MLD_USE_NATIVE_POLY_CHKNORM ||    \
          MLD_USE_NATIVE_POINTWISE_MONTGOMERY ||                               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L4 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L5 ||               \
          MLD_USE_NATIVE_POLYVECL_POINTWISE_ACC_MONTGOMERY_L7 ||               \
          MLD_USE_NATIVE_POLYZ_UNPACK_17 || MLD_USE_NATIVE_POLYZ_UNPACK_19 ||  \
          MLD_USE_NATIVE_REJ_UNIFORM || MLD_USE_NATIVE_REJ_UNIFORM_ETA2 ||     \
          MLD_USE_NATIVE_REJ_UNIFORM_ETA4 || MLD_USE_NATIVE_FIPS202_X1 ||      \
          MLD_USE_NATIVE_FIPS202_X4 */


  return 0;
}
