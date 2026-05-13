/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

#ifndef MLD_CBMC_H
#define MLD_CBMC_H

/***************************************************
 * Basic replacements for __CPROVER_XXX contracts
 ***************************************************/
#ifndef CBMC

#define __contract__(x)
#define __loop__(x)
#define cassert(x)

#else /* !CBMC */


#define __contract__(x) x
#define __loop__(x) x

/* Conditionally expand to __VA_ARGS__ depending on MLD_CONFIG_REDUCE_RAM. */
#if defined(MLD_CONFIG_REDUCE_RAM)
#define MLD_IF_REDUCE_RAM(...) __VA_ARGS__
#define MLD_IF_NOT_REDUCE_RAM(...)
#else
#define MLD_IF_REDUCE_RAM(...)
#define MLD_IF_NOT_REDUCE_RAM(...) __VA_ARGS__
#endif

/* https://diffblue.github.io/cbmc/contracts-assigns.html */
#define assigns(...) __CPROVER_assigns(__VA_ARGS__)

/* https://diffblue.github.io/cbmc/contracts-requires-ensures.html */
#define requires(...) __CPROVER_requires(__VA_ARGS__)
#define ensures(...) __CPROVER_ensures(__VA_ARGS__)
/* https://diffblue.github.io/cbmc/contracts-loops.html */
#define invariant(...) __CPROVER_loop_invariant(__VA_ARGS__)
#define decreases(...) __CPROVER_decreases(__VA_ARGS__)
/* cassert to avoid confusion with in-built assert */
#define cassert(x) __CPROVER_assert(x, "cbmc assertion failed")
#define assume(...) __CPROVER_assume(__VA_ARGS__)

/***************************************************
 * Macros for "expression" forms that may appear
 * _inside_ top-level contracts.
 ***************************************************/

/*
 * function return value - useful inside ensures
 * https://diffblue.github.io/cbmc/contracts-functions.html
 */
#define return_value (__CPROVER_return_value)

/*
 * assigns l-value targets
 * https://diffblue.github.io/cbmc/contracts-assigns.html
 */
#define object_whole(...) __CPROVER_object_whole(__VA_ARGS__)
#define memory_slice(...) __CPROVER_object_upto(__VA_ARGS__)
#define same_object(...) __CPROVER_same_object(__VA_ARGS__)

/*
 * Pointer-related predicates
 * https://diffblue.github.io/cbmc/contracts-memory-predicates.html
 */
#define memory_no_alias(...) __CPROVER_is_fresh(__VA_ARGS__)
#define readable(...) __CPROVER_r_ok(__VA_ARGS__)
#define writeable(...) __CPROVER_w_ok(__VA_ARGS__)

/* Maximum supported buffer size
 *
 * Larger buffers may be supported, but due to internal modeling constraints
 * in CBMC, the proofs of memory- and type-safety won't be able to run.
 *
 * If you find yourself in need for a buffer size larger than this,
 * please contact the maintainers, so we can prioritize work to relax
 * this somewhat artificial bound.
 */
#define MLD_MAX_BUFFER_SIZE (SIZE_MAX >> 12)


/*
 * History variables
 * https://diffblue.github.io/cbmc/contracts-history-variables.html
 */
#define old(...) __CPROVER_old(__VA_ARGS__)
#define loop_entry(...) __CPROVER_loop_entry(__VA_ARGS__)

/*
 * Quantifiers
 * Note that the range on qvar is _exclusive_ between qvar_lb .. qvar_ub
 * https://diffblue.github.io/cbmc/contracts-quantifiers.html
 */

/*
 * Prevent clang-format from corrupting CBMC's special ==> operator
 */
/* clang-format off */
#define forall(qvar, qvar_lb, qvar_ub, predicate)                 \
  __CPROVER_forall                                                \
  {                                                               \
    unsigned qvar;                                                \
    ((qvar_lb) <= (qvar) && (qvar) < (qvar_ub)) ==> (predicate)   \
  }

#define exists(qvar, qvar_lb, qvar_ub, predicate)               \
  __CPROVER_exists                                              \
  {                                                             \
    unsigned qvar;                                              \
    ((qvar_lb) <= (qvar) && (qvar) < (qvar_ub)) && (predicate)  \
  }
/* clang-format on */

/***************************************************
 * Convenience macros for common contract patterns
 ***************************************************/
/*
 * Prevent clang-format from corrupting CBMC's special ==> operator
 */
/* clang-format off */
#define CBMC_CONCAT_(left, right) left##right
#define CBMC_CONCAT(left, right) CBMC_CONCAT_(left, right)

#define array_bound_core(qvar, qvar_lb, qvar_ub, array_var,            \
                         value_lb, value_ub)                           \
  __CPROVER_forall                                                     \
  {                                                                    \
    unsigned qvar;                                                     \
    ((qvar_lb) <= (qvar) && (qvar) < (qvar_ub)) ==>                    \
        (((int)(value_lb) <= ((array_var)[(qvar)])) &&                 \
         (((array_var)[(qvar)]) < (int)(value_ub)))                    \
  }

#define array_bound(array_var, qvar_lb, qvar_ub, value_lb, value_ub) \
  array_bound_core(CBMC_CONCAT(_cbmc_idx, __COUNTER__), (qvar_lb),   \
      (qvar_ub), (array_var), (value_lb), (value_ub))

#define array_unchanged_core(qvar, qvar_lb, qvar_ub, array_var)                   \
  __CPROVER_forall                                                                \
  {                                                                               \
    unsigned qvar;                                                                \
    ((qvar_lb) <= (qvar) && (qvar) < (qvar_ub)) ==>                               \
    ((array_var)[(qvar)]) == (old(* (int32_t (*)[(qvar_ub)])(array_var)))[(qvar)] \
  }

#define array_unchanged(array_var, N) \
    array_unchanged_core(CBMC_CONCAT(_cbmc_idx, __COUNTER__), 0, (N), (array_var))

#define array_unchanged_u64_core(qvar, qvar_lb, qvar_ub, array_var)                \
  __CPROVER_forall                                                                 \
  {                                                                                \
    unsigned qvar;                                                                 \
    ((qvar_lb) <= (qvar) && (qvar) < (qvar_ub)) ==>                                \
    ((array_var)[(qvar)]) == (old(* (uint64_t (*)[(qvar_ub)])(array_var)))[(qvar)] \
  }

#define array_unchanged_u64(array_var, N) \
    array_unchanged_u64_core(CBMC_CONCAT(_cbmc_idx, __COUNTER__), 0, (N), (array_var))
/* clang-format on */

/***************************************************
 * Variadic compaction of memory annotations
 *
 * disjoint(arg, ...) -- inside requires(...): expands each arg to a
 *   memory_no_alias(...) check and AND-joins them.
 * slices(arg, ...)   -- inside assigns(...): expands each arg to a
 *   memory_slice(...) target, comma-joined.
 *
 * Each arg is either:
 *   - a bare object   x       -> size is sizeof(*(x))
 *   - a pair          (x, N)  -> size is N (interpreted as a byte count)
 *
 * Requires a C99 preprocessor; only seen by the compiler in CBMC
 * builds. Capped at 16 args per call.
 ***************************************************/

#define MLD_CBMC_NARGS(...)                                                  \
  MLD_CBMC_NARGS_(__VA_ARGS__, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, \
                  3, 2, 1)
#define MLD_CBMC_NARGS_(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, \
                        _13, _14, _15, _16, N, ...)                        \
  N

#define MLD_CBMC_PROBE_(...) ~, 1
#define MLD_CBMC_CHECK_(...) MLD_CBMC_CHECK_N_(__VA_ARGS__, 0)
#define MLD_CBMC_CHECK_N_(_a, _b, ...) _b
#define MLD_CBMC_IS_PAIR(x) MLD_CBMC_CHECK_(MLD_CBMC_PROBE_ x)

#define MLD_CBMC_NA(x) MLD_CBMC_NA_(MLD_CBMC_IS_PAIR(x), x)
#define MLD_CBMC_NA_(t, x) MLD_CBMC_NA__(t, x)
#define MLD_CBMC_NA__(t, x) MLD_CBMC_NA_##t(x)
#define MLD_CBMC_NA_0(x) memory_no_alias((x), sizeof(*(x)))
#define MLD_CBMC_NA_1(x) MLD_CBMC_NA_PAIR_ x
#define MLD_CBMC_NA_PAIR_(p, n) memory_no_alias((p), (n))

#define MLD_CBMC_SL(x) MLD_CBMC_SL_(MLD_CBMC_IS_PAIR(x), x)
#define MLD_CBMC_SL_(t, x) MLD_CBMC_SL__(t, x)
#define MLD_CBMC_SL__(t, x) MLD_CBMC_SL_##t(x)
#define MLD_CBMC_SL_0(x) memory_slice((x), sizeof(*(x)))
#define MLD_CBMC_SL_1(x) MLD_CBMC_SL_PAIR_ x
#define MLD_CBMC_SL_PAIR_(p, n) memory_slice((p), (n))

#define MLD_CBMC_AND_1(M, a) M(a)
#define MLD_CBMC_AND_2(M, a, ...) M(a) && MLD_CBMC_AND_1(M, __VA_ARGS__)
#define MLD_CBMC_AND_3(M, a, ...) M(a) && MLD_CBMC_AND_2(M, __VA_ARGS__)
#define MLD_CBMC_AND_4(M, a, ...) M(a) && MLD_CBMC_AND_3(M, __VA_ARGS__)
#define MLD_CBMC_AND_5(M, a, ...) M(a) && MLD_CBMC_AND_4(M, __VA_ARGS__)
#define MLD_CBMC_AND_6(M, a, ...) M(a) && MLD_CBMC_AND_5(M, __VA_ARGS__)
#define MLD_CBMC_AND_7(M, a, ...) M(a) && MLD_CBMC_AND_6(M, __VA_ARGS__)
#define MLD_CBMC_AND_8(M, a, ...) M(a) && MLD_CBMC_AND_7(M, __VA_ARGS__)
#define MLD_CBMC_AND_9(M, a, ...) M(a) && MLD_CBMC_AND_8(M, __VA_ARGS__)
#define MLD_CBMC_AND_10(M, a, ...) M(a) && MLD_CBMC_AND_9(M, __VA_ARGS__)
#define MLD_CBMC_AND_11(M, a, ...) M(a) && MLD_CBMC_AND_10(M, __VA_ARGS__)
#define MLD_CBMC_AND_12(M, a, ...) M(a) && MLD_CBMC_AND_11(M, __VA_ARGS__)
#define MLD_CBMC_AND_13(M, a, ...) M(a) && MLD_CBMC_AND_12(M, __VA_ARGS__)
#define MLD_CBMC_AND_14(M, a, ...) M(a) && MLD_CBMC_AND_13(M, __VA_ARGS__)
#define MLD_CBMC_AND_15(M, a, ...) M(a) && MLD_CBMC_AND_14(M, __VA_ARGS__)
#define MLD_CBMC_AND_16(M, a, ...) M(a) && MLD_CBMC_AND_15(M, __VA_ARGS__)

#define MLD_CBMC_COMMA_1(M, a) M(a)
#define MLD_CBMC_COMMA_2(M, a, ...) M(a), MLD_CBMC_COMMA_1(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_3(M, a, ...) M(a), MLD_CBMC_COMMA_2(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_4(M, a, ...) M(a), MLD_CBMC_COMMA_3(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_5(M, a, ...) M(a), MLD_CBMC_COMMA_4(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_6(M, a, ...) M(a), MLD_CBMC_COMMA_5(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_7(M, a, ...) M(a), MLD_CBMC_COMMA_6(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_8(M, a, ...) M(a), MLD_CBMC_COMMA_7(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_9(M, a, ...) M(a), MLD_CBMC_COMMA_8(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_10(M, a, ...) M(a), MLD_CBMC_COMMA_9(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_11(M, a, ...) M(a), MLD_CBMC_COMMA_10(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_12(M, a, ...) M(a), MLD_CBMC_COMMA_11(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_13(M, a, ...) M(a), MLD_CBMC_COMMA_12(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_14(M, a, ...) M(a), MLD_CBMC_COMMA_13(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_15(M, a, ...) M(a), MLD_CBMC_COMMA_14(M, __VA_ARGS__)
#define MLD_CBMC_COMMA_16(M, a, ...) M(a), MLD_CBMC_COMMA_15(M, __VA_ARGS__)

#define MLD_CBMC_DISPATCH_(prefix, n, M, ...) prefix##n(M, __VA_ARGS__)
#define MLD_CBMC_DISPATCH(prefix, n, M, ...) \
  MLD_CBMC_DISPATCH_(prefix, n, M, __VA_ARGS__)

#define disjoint(...)                                                         \
  (MLD_CBMC_DISPATCH(MLD_CBMC_AND_, MLD_CBMC_NARGS(__VA_ARGS__), MLD_CBMC_NA, \
                     __VA_ARGS__))

#define slices(...)                                                            \
  MLD_CBMC_DISPATCH(MLD_CBMC_COMMA_, MLD_CBMC_NARGS(__VA_ARGS__), MLD_CBMC_SL, \
                    __VA_ARGS__)

/* Wrapper around array_bound operating on absolute values.
 *
 * The absolute value bound `k` is exclusive.
 *
 * Note that since the lower bound in array_bound is inclusive, we have to
 * raise it by 1 here.
 */
#define array_abs_bound(arr, lb, ub, k) \
  array_bound((arr), (lb), (ub), -((int)(k)) + 1, (k))

#endif /* CBMC */

#endif /* !MLD_CBMC_H */
