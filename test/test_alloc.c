/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Expose declaration of allocator (normally internal) */
#define MLD_BUILD_INTERNAL
#include "../mldsa/mldsa_native.h"
#include "../mldsa/src/common.h"
#include "notrandombytes/notrandombytes.h"

/*
 * This test checks that
 * - we handle allocator failures correctly, propagating MLD_ERR_OUT_OF_MEMORY
 *   and cleaning up all memory, and
 * - we leak no memory, and
 * - we always de-allocate in the reverse order of allocation, thereby
 *   allowing the use of a bump allocator.
 *
 * This is done through a custom bump allocator and tracking of in-flight
 * allocations.
 */

/*
 * Allocation tracker
 *
 * Simple stack of in-flight allocations that's used to test that there are
 * no leaks and that we free in reverse order than we allocate. (The absence
 * of leaks is also checked through the address sanitizer)
 */

typedef struct
{
  void *addr;
  size_t size;
  const char *file;
  int line;
  const char *var;
  const char *type;
} alloc_info_t;

#define MLD_MAX_IN_FLIGHT_ALLOCS 100
static alloc_info_t alloc_stack[MLD_MAX_IN_FLIGHT_ALLOCS];
static int alloc_stack_top = 0;

static void alloc_tracker_push(void *addr, size_t size, const char *file,
                               int line, const char *var, const char *type)
{
  if (alloc_stack_top >= MLD_MAX_IN_FLIGHT_ALLOCS)
  {
    fprintf(stderr, "ERROR: Allocation stack overflow\n");
    exit(1);
  }
  alloc_stack[alloc_stack_top].addr = addr;
  alloc_stack[alloc_stack_top].size = size;
  alloc_stack[alloc_stack_top].file = file;
  alloc_stack[alloc_stack_top].line = line;
  alloc_stack[alloc_stack_top].var = var;
  alloc_stack[alloc_stack_top].type = type;
  alloc_stack_top++;
}

static void alloc_tracker_pop(void *addr, size_t size, const char *file,
                              int line, const char *var)
{
  alloc_info_t *top;
  if (alloc_stack_top == 0)
  {
    fprintf(
        stderr,
        "ERROR: Attempting to free %s at %s:%d but allocation stack is empty\n",
        var, file, line);
    exit(1);
  }

  top = &alloc_stack[alloc_stack_top - 1];
  if (top->addr != addr || top->size != size)
  {
    fprintf(stderr,
            "ERROR: Free order violation at %s:%d\n"
            "  Attempting to free: %s (addr=%p, sz %d)\n"
            "  Expected to free:   %s (addr=%p, sz %d) allocated at %s:%d\n",
            file, line, var, addr, (int)size, top->var, top->addr,
            (int)top->size, top->file, top->line);
    exit(1);
  }

  alloc_stack_top--;
}

/*
 * Bump allocator
 *
 * A simple stack-like allocator. We can use it since freeing happens in
 * reverse order to allocation.
 */

#define MLD_BUMP_ALLOC_SIZE (128 * 1024) /* 128KB buffer */
static uint8_t *bump_buffer = NULL;      /* Base address */
static size_t bump_offset = 0;           /* Watermark */
static size_t bump_high_mark = 0;        /* High watermark */

static void *bump_alloc(size_t sz)
{
  /* Align to 32 bytes */
  size_t aligned_sz = (sz + 31) & ~((size_t)31);
  void *p;

  if (sz > MLD_BUMP_ALLOC_SIZE ||
      aligned_sz > MLD_BUMP_ALLOC_SIZE - bump_offset)
  {
    return NULL;
  }

  p = bump_buffer + bump_offset;
  bump_offset += aligned_sz;

  if (bump_offset > bump_high_mark)
  {
    bump_high_mark = bump_offset;
  }

  return p;
}

static int bump_free(void *p)
{
  if (p == NULL)
  {
    return 0;
  }

  /* Check that p is within the bump buffer */
  if (p < (void *)bump_buffer || p >= (void *)(bump_buffer + bump_offset))
  {
    return -1;
  }

  /* Reset bump offset to the freed address */
  bump_offset = (size_t)((uint8_t *)p - bump_buffer);
  return 0;
}

int alloc_counter = 0;
int fail_on_counter = -1;
int print_debug_info = 0;

static void reset_all(void)
{
  randombytes_reset();
  alloc_counter = 0;
  alloc_stack_top = 0;
  bump_offset = 0;
  fail_on_counter = -1;
}

void *custom_alloc(size_t sz, const char *file, int line, const char *var,
                   const char *type)
{
  void *p = NULL;
  if (alloc_counter++ == fail_on_counter)
  {
    return NULL;
  }

  p = bump_alloc(sz);
  if (p == NULL)
  {
    fprintf(stderr,
            "ERROR: Bump allocator (%d bytes) ran out of memory. "
            "%s *%s (%d bytes) at %s:%d\n",
            (int)MLD_BUMP_ALLOC_SIZE, type, var, (int)sz, file, line);
    exit(1);
  }

  if (print_debug_info == 1)
  {
    fprintf(stderr, "Alloc #%d: %s %s (%d bytes) at %s:%d\n", alloc_counter,
            type, var, (int)sz, file, line);
  }

  alloc_tracker_push(p, sz, file, line, var, type);
  return p;
}

void custom_free(void *p, size_t sz, const char *file, int line,
                 const char *var, const char *type)
{
  (void)sz;
  (void)type;

  if (p != NULL)
  {
    alloc_tracker_pop(p, sz, file, line, var);
  }

  if (bump_free(p) != 0)
  {
    fprintf(stderr, "ERROR: Free failed: %s %s (%d bytes) at %s:%d\n", type,
            var, (int)sz, file, line);
    exit(1);
  }
}

#define TEST_ALLOC_FAILURE(test_name, call)                                   \
  do                                                                          \
  {                                                                           \
    int num_allocs, i, rc;                                                    \
    /* First pass: count allocations */                                       \
    bump_high_mark = 0;                                                       \
    reset_all();                                                              \
    rc = call;                                                                \
    if (rc != 0)                                                              \
    {                                                                         \
      fprintf(stderr, "ERROR: %s failed in counting pass\n", test_name);      \
      return 1;                                                               \
    }                                                                         \
    if (alloc_stack_top != 0)                                                 \
    {                                                                         \
      fprintf(stderr, "ERROR: %s leaked %d allocation(s) in counting pass\n", \
              test_name, alloc_stack_top);                                    \
      return 1;                                                               \
    }                                                                         \
    num_allocs = alloc_counter;                                               \
    /* Second pass: test each allocation failure */                           \
    for (i = 0; i < num_allocs; i++)                                          \
    {                                                                         \
      reset_all();                                                            \
      fail_on_counter = i;                                                    \
      rc = call;                                                              \
      if (rc != MLD_ERR_OUT_OF_MEMORY)                                        \
      {                                                                       \
        int rc2;                                                              \
        /* Re-run dry-run and print debug info */                             \
        reset_all();                                                          \
        print_debug_info = 1;                                                 \
        rc2 = call;                                                           \
        (void)rc2;                                                            \
        if (rc == 0)                                                          \
        {                                                                     \
          fprintf(stderr,                                                     \
                  "ERROR: %s unexpectedly succeeded when allocation %d/%d "   \
                  "was instrumented to fail\n",                               \
                  test_name, i + 1, num_allocs);                              \
        }                                                                     \
        else                                                                  \
        {                                                                     \
          fprintf(stderr,                                                     \
                  "ERROR: %s failed with wrong error code %d "                \
                  "(expected %d) when allocation %d/%d was instrumented "     \
                  "to fail\n",                                                \
                  test_name, rc, MLD_ERR_OUT_OF_MEMORY, i + 1, num_allocs);   \
        }                                                                     \
        return 1;                                                             \
      }                                                                       \
      if (alloc_stack_top != 0)                                               \
      {                                                                       \
        fprintf(stderr,                                                       \
                "ERROR: %s leaked %d allocation(s) when allocation %d/%d "    \
                "was instrumented to fail\n",                                 \
                test_name, alloc_stack_top, i + 1, num_allocs);               \
        return 1;                                                             \
      }                                                                       \
    }                                                                         \
    printf(                                                                   \
        "Allocation test for %s PASSED.\n"                                    \
        "  Max dynamic allocation: %d bytes\n",                               \
        test_name, (int)bump_high_mark);                                      \
  } while (0)

static int test_keygen_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];

  TEST_ALLOC_FAILURE("mld_keypair", mld_keypair(pk, sk));
  return 0;
}

static int test_sign_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t msg[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t siglen;

  /* Generate valid keypair first */
  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in sign test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE(
      "mld_signature",
      mld_signature(sig, &siglen, msg, sizeof(msg), ctx, sizeof(ctx) - 1, sk));
  return 0;
}

static int test_verify_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t msg[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t siglen;

  /* Generate valid keypair and signature first */
  alloc_counter = 0;
  alloc_stack_top = 0;
  bump_offset = 0;
  fail_on_counter = -1;
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in verify test setup\n");
    return 1;
  }

  if (mld_signature(sig, &siglen, msg, sizeof(msg), ctx, sizeof(ctx) - 1, sk) !=
      0)
  {
    fprintf(stderr, "ERROR: mld_signature failed in verify test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE("mld_verify", mld_verify(sig, siglen, msg, sizeof(msg),
                                              ctx, sizeof(ctx) - 1, pk));
  return 0;
}

static int test_sign_combined_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sm[CRYPTO_BYTES + 32];
  uint8_t msg[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t smlen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in sign combined test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE("mld_sign", mld_sign(sm, &smlen, msg, sizeof(msg), ctx,
                                          sizeof(ctx) - 1, sk));
  return 0;
}

static int test_open_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sm[CRYPTO_BYTES + 32];
  uint8_t msg[32] = {0};
  uint8_t msg_out[CRYPTO_BYTES + 32];
  const uint8_t ctx[] = "test context";
  size_t smlen, mlen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in open test setup\n");
    return 1;
  }

  if (mld_sign(sm, &smlen, msg, sizeof(msg), ctx, sizeof(ctx) - 1, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_sign failed in open test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE("mld_open", mld_open(msg_out, &mlen, sm, smlen, ctx,
                                          sizeof(ctx) - 1, pk));
  return 0;
}

static int test_signature_extmu_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t mu[64] = {0};
  size_t siglen;

  randombytes_reset();
  alloc_counter = 0;
  alloc_stack_top = 0;
  bump_offset = 0;
  fail_on_counter = -1;
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_keypair failed in signature_extmu test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE("mld_signature_extmu",
                     mld_signature_extmu(sig, &siglen, mu, sk));
  return 0;
}

static int test_verify_extmu_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t mu[64] = {0};
  size_t siglen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in verify_extmu test setup\n");
    return 1;
  }

  if (mld_signature_extmu(sig, &siglen, mu, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_signature_extmu failed in verify_extmu test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE("mld_verify_extmu", mld_verify_extmu(sig, siglen, mu, pk));
  return 0;
}

static int test_signature_pre_hash_shake256_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t msg[32] = {0};
  uint8_t rnd[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t siglen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_keypair failed in signature_pre_hash_shake256 test "
            "setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE(
      "mld_signature_pre_hash_shake256",
      mld_signature_pre_hash_shake256(sig, &siglen, msg, sizeof(msg), ctx,
                                      sizeof(ctx) - 1, rnd, sk));
  return 0;
}

static int test_verify_pre_hash_shake256_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t sig[CRYPTO_BYTES];
  uint8_t msg[32] = {0};
  uint8_t rnd[32] = {0};
  const uint8_t ctx[] = "test context";
  size_t siglen;

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_keypair failed in verify_pre_hash_shake256 test "
            "setup\n");
    return 1;
  }

  if (mld_signature_pre_hash_shake256(sig, &siglen, msg, sizeof(msg), ctx,
                                      sizeof(ctx) - 1, rnd, sk) != 0)
  {
    fprintf(stderr,
            "ERROR: mld_signature_pre_hash_shake256 failed in "
            "verify_pre_hash_shake256 test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE("mld_verify_pre_hash_shake256",
                     mld_verify_pre_hash_shake256(sig, siglen, msg, sizeof(msg),
                                                  ctx, sizeof(ctx) - 1, pk));
  return 0;
}

static int test_pk_from_sk_alloc_failure(void)
{
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];

  reset_all();
  if (mld_keypair(pk, sk) != 0)
  {
    fprintf(stderr, "ERROR: mld_keypair failed in pk_from_sk test setup\n");
    return 1;
  }

  TEST_ALLOC_FAILURE("mld_pk_from_sk", mld_pk_from_sk(pk, sk));
  return 0;
}

int main(void)
{
  MLD_ALIGN uint8_t bump_buffer_storage[MLD_BUMP_ALLOC_SIZE];
  bump_buffer = bump_buffer_storage;

  if (test_keygen_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_sign_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_verify_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_sign_combined_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_open_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_signature_extmu_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_verify_extmu_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_signature_pre_hash_shake256_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_verify_pre_hash_shake256_alloc_failure() != 0)
  {
    return 1;
  }

  if (test_pk_from_sk_alloc_failure() != 0)
  {
    return 1;
  }

  return 0;
}
