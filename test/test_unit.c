/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "notrandombytes/notrandombytes.h"

#include "../mldsa/src/poly.h"

#ifndef NUM_RANDOM_TESTS
#ifdef MLDSA_DEBUG
#define NUM_RANDOM_TESTS 1000
#else
#define NUM_RANDOM_TESTS 5000
#endif
#endif /* !NUM_RANDOM_TESTS */

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
#if defined(MLD_USE_NATIVE_NTT) || defined(MLD_USE_NATIVE_INTT)
/* Backend unit test helper functions */
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

#ifdef MLD_USE_NATIVE_NTT
static int test_ntt_core(const int32_t *input, const char *test_name)
{
  mld_poly test_poly, ref_poly;

  memcpy(test_poly.coeffs, input, MLDSA_N * sizeof(int32_t));
  memcpy(ref_poly.coeffs, input, MLDSA_N * sizeof(int32_t));

  mld_poly_ntt(&test_poly);
  mld_poly_ntt_c(&ref_poly);

#ifdef MLD_USE_NATIVE_NTT_CUSTOM_ORDER
  mld_poly_permute_bitrev_to_custom(ref_poly.coeffs);
#endif

  /* Normalize */
  mld_poly_reduce(&ref_poly);
  mld_poly_reduce(&test_poly);

  mld_poly_caddq_c(&ref_poly);
  mld_poly_caddq_c(&test_poly);

  CHECK(compare_i32_arrays(test_poly.coeffs, ref_poly.coeffs, MLDSA_N,
                           test_name, input));
  return 0;
}

static int test_native_ntt(void)
{
  int32_t test_data[MLDSA_N];
  int pos, i;

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

  return 0;
}
#endif /* MLD_USE_NATIVE_NTT */

#ifdef MLD_USE_NATIVE_INTT
static int test_invntt_tomont_core(const int32_t *input, const char *test_name)
{
  mld_poly test_poly, ref_poly;

  memcpy(test_poly.coeffs, input, MLDSA_N * sizeof(int32_t));
  memcpy(ref_poly.coeffs, input, MLDSA_N * sizeof(int32_t));

#ifdef MLD_USE_NATIVE_NTT_CUSTOM_ORDER
  mld_poly_permute_bitrev_to_custom(test_poly.coeffs);
#endif

  mld_poly_invntt_tomont(&test_poly);
  mld_poly_invntt_tomont_c(&ref_poly);

  /* Normalize */
  mld_poly_reduce(&ref_poly);
  mld_poly_reduce(&test_poly);

  mld_poly_caddq_c(&ref_poly);
  mld_poly_caddq_c(&test_poly);

  CHECK(compare_i32_arrays(test_poly.coeffs, ref_poly.coeffs, MLDSA_N,
                           test_name, input));
  return 0;
}

static int test_native_invntt_tomont(void)
{
  int32_t test_data[MLDSA_N];
  int pos, i;

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

  return 0;
}
#endif /* MLD_USE_NATIVE_INTT */

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

  return 0;
}
#endif /* MLD_USE_NATIVE_NTT || MLD_USE_NATIVE_INTT */

int main(void)
{
  /* WARNING: Test-only
   * Normally, you would want to seed a PRNG with trustworthy entropy here. */
  randombytes_reset();

  /* Run backend unit tests */
#if defined(MLD_USE_NATIVE_NTT) || defined(MLD_USE_NATIVE_INTT)
  CHECK(test_backend_units() == 0);
#endif


  return 0;
}
