/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
 /*
  * This file is derived from the public domain
  * AVX2 Dilithium implementation @[REF_AVX2].
  */

#include "../../../common.h"
#if defined(MLD_ARITH_BACKEND_X86_64_DEFAULT) && \
    !defined(MLD_CONFIG_MULTILEVEL_NO_SHARED)

#include "consts.h"

.text
.global MLD_ASM_NAMESPACE(mld_pointwise_montgomery_avx2)
MLD_ASM_FN_SYMBOL(mld_pointwise_montgomery_avx2)
#consts
vmovdqa		MLD_AVX2_BACKEND_DATA_OFFSET_8XQINV*4(%rcx),%ymm0
vmovdqa		MLD_AVX2_BACKEND_DATA_OFFSET_8XQ*4(%rcx),%ymm1

xor		%eax,%eax
_looptop1:
#load
vmovdqa		(%rsi),%ymm2
vmovdqa		32(%rsi),%ymm4
vmovdqa		64(%rsi),%ymm6
vmovdqa		(%rdx),%ymm10
vmovdqa		32(%rdx),%ymm12
vmovdqa		64(%rdx),%ymm14
vpsrlq		$32,%ymm2,%ymm3
vpsrlq		$32,%ymm4,%ymm5
vmovshdup	%ymm6,%ymm7
vpsrlq		$32,%ymm10,%ymm11
vpsrlq		$32,%ymm12,%ymm13
vmovshdup	%ymm14,%ymm15

#mul
vpmuldq		%ymm2,%ymm10,%ymm2
vpmuldq		%ymm3,%ymm11,%ymm3
vpmuldq		%ymm4,%ymm12,%ymm4
vpmuldq		%ymm5,%ymm13,%ymm5
vpmuldq		%ymm6,%ymm14,%ymm6
vpmuldq		%ymm7,%ymm15,%ymm7

#reduce
vpmuldq		%ymm0,%ymm2,%ymm10
vpmuldq		%ymm0,%ymm3,%ymm11
vpmuldq		%ymm0,%ymm4,%ymm12
vpmuldq		%ymm0,%ymm5,%ymm13
vpmuldq		%ymm0,%ymm6,%ymm14
vpmuldq		%ymm0,%ymm7,%ymm15
vpmuldq		%ymm1,%ymm10,%ymm10
vpmuldq		%ymm1,%ymm11,%ymm11
vpmuldq		%ymm1,%ymm12,%ymm12
vpmuldq		%ymm1,%ymm13,%ymm13
vpmuldq		%ymm1,%ymm14,%ymm14
vpmuldq		%ymm1,%ymm15,%ymm15
vpsubq		%ymm10,%ymm2,%ymm2
vpsubq		%ymm11,%ymm3,%ymm3
vpsubq		%ymm12,%ymm4,%ymm4
vpsubq		%ymm13,%ymm5,%ymm5
vpsubq		%ymm14,%ymm6,%ymm6
vpsubq		%ymm15,%ymm7,%ymm7
vpsrlq		$32,%ymm2,%ymm2
vpsrlq		$32,%ymm4,%ymm4
vmovshdup	%ymm6,%ymm6

#store
vpblendd	$0xAA,%ymm3,%ymm2,%ymm2
vpblendd	$0xAA,%ymm5,%ymm4,%ymm4
vpblendd	$0xAA,%ymm7,%ymm6,%ymm6
vmovdqa		%ymm2,(%rdi)
vmovdqa		%ymm4,32(%rdi)
vmovdqa		%ymm6,64(%rdi)

add		$96,%rdi
add		$96,%rsi
add		$96,%rdx
add		$1,%eax
cmp		$10,%eax
jb 		_looptop1

vmovdqa		(%rsi),%ymm2
vmovdqa		32(%rsi),%ymm4
vmovdqa		(%rdx),%ymm10
vmovdqa		32(%rdx),%ymm12
vpsrlq		$32,%ymm2,%ymm3
vpsrlq		$32,%ymm4,%ymm5
vmovshdup	%ymm10,%ymm11
vmovshdup	%ymm12,%ymm13

#mul
vpmuldq		%ymm2,%ymm10,%ymm2
vpmuldq		%ymm3,%ymm11,%ymm3
vpmuldq		%ymm4,%ymm12,%ymm4
vpmuldq		%ymm5,%ymm13,%ymm5

#reduce
vpmuldq		%ymm0,%ymm2,%ymm10
vpmuldq		%ymm0,%ymm3,%ymm11
vpmuldq		%ymm0,%ymm4,%ymm12
vpmuldq		%ymm0,%ymm5,%ymm13
vpmuldq		%ymm1,%ymm10,%ymm10
vpmuldq		%ymm1,%ymm11,%ymm11
vpmuldq		%ymm1,%ymm12,%ymm12
vpmuldq		%ymm1,%ymm13,%ymm13
vpsubq		%ymm10,%ymm2,%ymm2
vpsubq		%ymm11,%ymm3,%ymm3
vpsubq		%ymm12,%ymm4,%ymm4
vpsubq		%ymm13,%ymm5,%ymm5
vpsrlq		$32,%ymm2,%ymm2
vmovshdup	%ymm4,%ymm4

#store
vpblendd	$0x55,%ymm2,%ymm3,%ymm2
vpblendd	$0x55,%ymm4,%ymm5,%ymm4
vmovdqa		%ymm2,(%rdi)
vmovdqa		%ymm4,32(%rdi)

ret

#endif /* MLD_ARITH_BACKEND_X86_64_DEFAULT && !MLD_CONFIG_MULTILEVEL_NO_SHARED */
