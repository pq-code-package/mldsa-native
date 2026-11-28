/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */

/*************************************************
 * Shared implementation body for PPC64LE NTT operations
 *
 * This file contains the common NTT algorithm implementation that is
 * instantiated for both POWER8/9 and POWER10 architectures.
 *
 * The includer must define MLD_NTT_SUFFIX before including this file:
 *   - For POWER8/9: #define MLD_NTT_SUFFIX p8p9
 *   - For POWER10:  #define MLD_NTT_SUFFIX p10
 *
 * This approach eliminates code duplication while preserving architecture-
 * specific optimizations (different vector multiply-high implementations).
 *
 * Author: Manoj Kumar
 **************************************************/

#ifndef MLD_NTT_SUFFIX
#error "MLD_NTT_SUFFIX must be defined before including ntt_ppc64le_impl.inc"
#endif

/* Macro concatenation helpers */
#define MLD_NTT_CONCAT_INNER(a, b) a##_##b
#define MLD_NTT_CONCAT(a, b) MLD_NTT_CONCAT_INNER(a, b)
#define MLD_NTT_CONCAT3_INNER(a, b, c) a##_##b##_##c
#define MLD_NTT_CONCAT3(a, b, c) MLD_NTT_CONCAT3_INNER(a, b, c)

/* Generate architecture-specific function and macro names */
#define MLD_NTT_FUNC(name) MLD_NTT_CONCAT3(name, MLD_NTT_SUFFIX, ppc64le)
#define MLD_BUTTERFLY MLD_NTT_CONCAT(mld_butterfly, MLD_NTT_SUFFIX)
#define MLD_BUTTERFLY_INV MLD_NTT_CONCAT(mld_butterfly_inv, MLD_NTT_SUFFIX)
#define MLD_MONTY_RED_F_STAR MLD_NTT_CONCAT(mld_monty_red_f_star, MLD_NTT_SUFFIX)

/*************************************************
 * Name:        ntt
 *
 * Description: Forward NTT, in-place. No modular reduction is performed after
 *              additions or subtractions. Output vector is in bitreversed order.
 *
 * Arguments:   - int32_t r[MLDSA_N]: input/output coefficient array
 **************************************************/

void MLD_NTT_FUNC(mld_ntt)(int32_t r[MLDSA_N])
{
	/* Constants: Broadcast scalar values to all 4 lanes of vector registers
	 * Each vector holds 4 x int32_t elements (VINT32_WIDTH=4) */

	const vector signed int _qinvx4 = vec_splats((int32_t) MLD_QINV); /*{QINV, QINV, QINV, QINV}*/
	const vector signed int _qx4 = vec_splats((int32_t) MLDSA_Q);	  /* {Q, Q, Q, Q} */

	/* cast input array to vector pointer for SIMD access
	Treats r[256] as 64 vectors of 4 int32_t elements each */
	vector signed int *pr = (vector signed int *) r;

	vector signed int vzeta0, vzeta1, vzeta2, vzeta3;	    /* zeta constants (4 copies each)  */
	vector signed int vp4, vp5, vp6, vp7, vp8, vp9, vp10, vp11; /* polynomial coefficient vectors */
	vector signed int vt1, vt2, vt3;			    /* temporary vectors for permutations */

	/*
	 * We group the first 3 rounds and the last 5 rounds.
	 * In both parts, we use 4-way SIMD, operate on 8 vectors (4*8=32 elements) at a time,
	 * and 8 passes through the for-loop to cover all 256 elements.
	 *
	 * -> rounds 0-2 are done in for-loop
	 */
	int i;
	for (i = 0; i < 8; i++) {
		/* load 8 vectors (32 coefficients) from memory
		 * each vector load fetches 4 consecutive int32_t values */
		/* Load vector at offset i (4 coefficients)*/
		vp4 = *(pr + i);       /* (i+0*8)*4 = (0,1,2,3), (4-7), (8-11), ...(28-31)*/
		vp5 = *(pr + i + 8);   /* (i+8)*4 = (32-35), (36-39), ... (60-63) */
		vp6 = *(pr + i + 16);  /* (i+16)*4 = (64-67), (68-71), ... (92-95) */
		vp7 = *(pr + i + 24);  /* (i+24)*4 = (96-99), (100-103), ... (124-127) */
		vp8 = *(pr + i + 32);  /* (i+32)*4 =(128-131), (132-135), ... (154-159) */
		vp9 = *(pr + i + 40);  /* (i+40)*4 = (160-163), (164-167), ... (188-191)*/
		vp10 = *(pr + i + 48); /* (i+48)*4 = (192-195), (196-199), ... (220-223)*/
		vp11 = *(pr + i + 56); /* (i+56)*4 = (224-227), (228-231), ... (252-255)*/

		/* Round 0: combining elements with distance 128
		 * This means (p(0), p(128)), (p(1), p(129)) …. (p(127), p(255))
		 * Same zeta(1) for all elements/
		 * so we broadcast zeta constant to all 4 lanes
		 * vec_splats creates {mld_zetas_[1], mld_zetas_[1], mld_zetas_[1], mld_zetas_[1]} */
		vzeta0 = vec_splats(mld_zetas_[1]);

		/* Apply butterfly operation:
		 * processes 4 coefficients in parallel per vector
		 * butterfly macro expands to -> Montgomery multiplication + addition/subtraction */
		MLD_BUTTERFLY(vp4, vp8, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp5, vp9, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp6, vp10, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp7, vp11, vzeta0, vt1, vt2, _qinvx4, _qx4);

		/* Round 1: distance 64:
		 * combines vp4-vp6, vp5-vp7
		 * (p(0), p(64)), (p(1), p(65)), ...;  2 x 64-element groups
		 * Two zeta values, zeta(2), zeta(3), one per 64-element group
		 * load two different zeta constants for different vector pairs */
		vzeta0 = vec_splats(mld_zetas_[2]); /* broadcast mld_zetas_[2] to all 4 lanes */
		vzeta1 = vec_splats(mld_zetas_[3]); /* broadcast mld_zetas_[3] to all 4 lanes */

		MLD_BUTTERFLY(vp4, vp6, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp5, vp7, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp8, vp10, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp9, vp11, vzeta1, vt1, vt2, _qinvx4, _qx4);

		/* Round 2: distance 32:
		 * combines vp4-vp5, vp6-vp7
		 * (p(0), p(32), (p(1), p(33)), ...; 4 x 32-element groups
		 *  4 zeta values (4-7), one per 32-element group
		 * four different zeta constants for four vector pairs */
		vzeta0 = vec_splats(mld_zetas_[4]);
		vzeta1 = vec_splats(mld_zetas_[5]);
		vzeta2 = vec_splats(mld_zetas_[6]);
		vzeta3 = vec_splats(mld_zetas_[7]);

		MLD_BUTTERFLY(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* store 8 vectors (32 coefficients) back to memory */
		*(pr + i) = vp4;
		*(pr + i + 16) = vp6;
		*(pr + i + 8) = vp5;
		*(pr + i + 40) = vp9;
		*(pr + i + 32) = vp8;
		*(pr + i + 24) = vp7;
		*(pr + i + 48) = vp10;
		*(pr + i + 56) = vp11;
	}

	for (i = 0; i < 8; i++) {
		/* load */
		vp4 = *(pr + i * 8 + 0);  /* (i*8+0)*4 = (0-3), (32-35), ... (224-227)*/
		vp5 = *(pr + i * 8 + 1);  /* (i*8+1)*4 = (4-7), (36-39), ... (228-231) */
		vp6 = *(pr + i * 8 + 2);  /* (i*8+2)*4 = (8-11), (40-43), ...(232-235)*/
		vp7 = *(pr + i * 8 + 3);  /* (i*8+3)*4 = (12-15), (44-47), ... (236-239)*/
		vp8 = *(pr + i * 8 + 4);  /* (i*8+4)*4 = (16-19), (48-51), ... (240-243) */
		vp9 = *(pr + i * 8 + 5);  /* (i*8+5)*4 = (20-23), (52-55), ... (244-247)*/
		vp10 = *(pr + i * 8 + 6); /* (i*8+6)*4 = (24-27), (56-59), ... (248-251)*/
		vp11 = *(pr + i * 8 + 7); /* (i*8+7)*4= (28-31), (60-63), ... (252-255)*/

		/* Round 3: distance 16: (p(0), P(16)), (p(1), p(16)), ...;
		 * combines vp4-vp8, vp5-vp9
		 * 8x 16-element groups, 8 zeta values (8-15), one per group
		 * -> a different zeta for each iteration i of the for-loop, total of 8 zetas*/
		vzeta0 = vec_splats(mld_zetas_[8 + i + 0]);

		MLD_BUTTERFLY(vp4, vp8, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp5, vp9, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp6, vp10, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp7, vp11, vzeta0, vt1, vt2, _qinvx4, _qx4);

		/* Round 4: distance 8: (p(0), p(8)), (p(1), p(9)), ...
		 * combines vp4-vp6, vp5-vp7
		 * 16x 8-element groups, one zeta value per group, zeta(16-31)
		 * 2 zeta values per iteration of the for-loop, one per half of the pairs */
		vzeta0 = vec_splats(mld_zetas_[16 + i * 2 + 0]);
		vzeta1 = vec_splats(mld_zetas_[16 + i * 2 + 1]);

		MLD_BUTTERFLY(vp4, vp6, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp5, vp7, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp8, vp10, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp9, vp11, vzeta1, vt1, vt2, _qinvx4, _qx4);

		/* Round 5: distance 4: (p(0), p(4)), (p(1), p(5)), ...
		 * combines vp4-vp5, vp6-vp7,
		 * 32x 4-element groups, one zeta value per group, zeta(32-63)
		 * -> 4 zeta values per iteration of the loop */
		vzeta0 = vec_splats(mld_zetas_[32 + i * 4 + 0]);
		vzeta1 = vec_splats(mld_zetas_[32 + i * 4 + 1]);
		vzeta2 = vec_splats(mld_zetas_[32 + i * 4 + 2]);
		vzeta3 = vec_splats(mld_zetas_[32 + i * 4 + 3]);

		MLD_BUTTERFLY(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* Round 6: distance 2: (p(0), p(2)), (p(1), p(3)), (p(4), p(6)), (p(5),p(7))
		 * 64x 2-element groups, one zeta value per group, zeta(64-127)
		 * vec_ld loads 16 bytes (4 int32_t values) from aligned address */
		vt1 = vec_ld(256 + i * 32, mld_zetas_); /* Load 4 zeta constants */
		vt2 = vec_ld(272 + i * 32, mld_zetas_); /* Load 4 more zeta constants */

		const vector unsigned char z0perm = { 0x00, 0x01, 0x02, 0x03,
			0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x04, 0x05, 0x06, 0x07 };
		const vector unsigned char z1perm = { 0x08, 0x09, 0x0A, 0x0B,
			0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x0C, 0x0D, 0x0E, 0x0F };

		/* use vec_perm to rearrange zeta constants for butterfly operations */
		vzeta0 = (vector signed int) vec_perm((vector unsigned char) vt1, (vector unsigned char) vt1, z0perm);
		vzeta1 = (vector signed int) vec_perm((vector unsigned char) vt1, (vector unsigned char) vt1, z1perm);
		vzeta2 = (vector signed int) vec_perm((vector unsigned char) vt2, (vector unsigned char) vt2, z0perm);
		vzeta3 = (vector signed int) vec_perm((vector unsigned char) vt2, (vector unsigned char) vt2, z1perm);

		/* interleave elements from two vectors
		 * l1permb: takes elements {0,1} from first vector, {0,1} from second vector
		 * l2permb: takes elements {2,3} from first vector, {2,3} from second vector
		 * this prepares data layout for processing pairs of coefficients */

		const vector unsigned char l1permb = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
			0x06, 0x07, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17 };
		const vector unsigned char l2permb = { 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d,
			0x0e, 0x0f, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f };

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l1permb);
		vp5 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l2permb);
		vp4 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l1permb);
		vp7 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l2permb);
		vp6 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l1permb);
		vp9 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l2permb);
		vp8 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l1permb);
		vp11 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l2permb);
		vp10 = vt3;

		MLD_BUTTERFLY(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* Round 7: distance 1: (p(0), p(1)), (p(2), p(3)), (p(4),p(5)), …
		 * Each pair has its own zeta(128-255) */
		/* load 16 zeta constants (4 vectors × 4 elements each) */
		vzeta0 = vec_ld(512 + i * 64, mld_zetas_);
		vzeta1 = vec_ld(528 + i * 64, mld_zetas_);
		vzeta2 = vec_ld(544 + i * 64, mld_zetas_);
		vzeta3 = vec_ld(560 + i * 64, mld_zetas_);

		/* permutation masks for len=1 butterflies: interleave individual elements
		 * l3permb: {elem0_v1, elem0_v2, elem2_v1, elem2_v2} - even elements
		 * l4permb: {elem1_v1, elem1_v2, elem3_v1, elem3_v2} - odd elements */
		const vector unsigned char l3permb = { 0x00, 0x01, 0x02, 0x03, 0x10, 0x11,
			0x12, 0x13, 0x08, 0x09, 0x0A, 0x0B, 0x18, 0x19, 0x1A, 0x1B };
		const vector unsigned char l4permb = { 0x04, 0x05, 0x06, 0x07, 0x14, 0x15,
			0x16, 0x17, 0x0C, 0x0D, 0x0E, 0x0F, 0x1C, 0x1D, 0x1E, 0x1F };

		/* reorganize adjacent element pairs */
		vt3 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l3permb);
		vp5 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l4permb);
		vp4 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l3permb);
		vp7 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l4permb);
		vp6 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l3permb);
		vp9 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l4permb);
		vp8 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l3permb);
		vp11 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l4permb);
		vp10 = vt3;

		/* apply final butterflies with unique zeta constants for each vector */
		MLD_BUTTERFLY(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* output permutation */
		/* before we can store the data to memory, we must revert the permutes.*/
		const vector unsigned char l1opermb = { 0x00, 0x01, 0x02, 0x03, 0x10, 0x11, 0x12, 0x13,
			0x04, 0x05, 0x06, 0x07, 0x14, 0x15, 0x16, 0x17 };
		const vector unsigned char l2opermb = { 0x08, 0x09, 0x0a, 0x0b, 0x18, 0x19, 0x1a, 0x1b,
			0x0c, 0x0d, 0x0e, 0x0f, 0x1c, 0x1d, 0x1e, 0x1f };

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l1opermb);
		vp5 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l2opermb);
		vp4 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l1opermb);
		vp7 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l2opermb);
		vp6 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l1opermb);
		vp9 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l2opermb);
		vp8 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l1opermb);
		vp11 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l2opermb);
		vp10 = vt3;

		/* store 8 vectors (32 coefficients) back to memory in sequential order */
		*(pr + i * 8) = vp4;
		*(pr + i * 8 + 1) = vp5;
		*(pr + i * 8 + 2) = vp6;
		*(pr + i * 8 + 3) = vp7;
		*(pr + i * 8 + 4) = vp8;
		*(pr + i * 8 + 5) = vp9;
		*(pr + i * 8 + 6) = vp10;
		*(pr + i * 8 + 7) = vp11;
	}
}

/*************************************************
 * Name:        invntt_tomont
 *
 * Description: Inverse NTT and multiplication by Montgomery factor 2^32.
 *              In-place. No modular reductions after additions or
 *              subtractions; input coefficients need to be smaller than
 *              Q in absolute value. Output coefficient are smaller than Q in
 *              absolute value.
 *
 * Arguments:   - int32_t r[MLDSA_N]: input/output coefficient array
 **************************************************/

void MLD_NTT_FUNC(mld_intt)(int32_t r[MLDSA_N])
{
	/* Broadcast scalar values to all 4 lanes of vector registers */
	const vector signed int _qinvx4 = vec_splats((int32_t) MLD_QINV);
	const vector signed int _qx4 = vec_splats((int32_t) MLDSA_Q);

	/* check-magic: 41978 == ((1ULL << 32) * (1ULL << 32) * inverse(256)) % MLDSA_Q */
	const vector signed int f = vec_splats(41978);

	/* Treats r[256] as 64 vectors of 4 int32_t elements each */
	vector signed int *pr = (vector signed int *) r;

	/* Working registers */
	vector signed int vzeta0, vzeta1, vzeta2, vzeta3;
	vector signed int vp4, vp5, vp6, vp7, vp8, vp9, vp10, vp11;
	vector signed int vt1, vt2, vt3;

	int i;
	for (i = 0; i < 8; i++) {	  /* Stage 0:3 */
					  /* load      */
		vp4 = *(pr + i * 8);	  /* r[j]      */
		vp5 = *(pr + i * 8 + 1);  /* r[j]      */
		vp6 = *(pr + i * 8 + 2);  /* r[j]      */
		vp7 = *(pr + i * 8 + 3);  /* r[j]      */
		vp8 = *(pr + i * 8 + 4);  /* r[j+len]  */
		vp9 = *(pr + i * 8 + 5);  /* r[j+len]  */
		vp10 = *(pr + i * 8 + 6); /* r[j+len]  */
		vp11 = *(pr + i * 8 + 7); /* r[j+len]  */

		/* round 0 (len=1) */

		vzeta0 = vec_ld(i * 64, mld_zetas_inv_al);
		vzeta1 = vec_ld(16 + i * 64, mld_zetas_inv_al);
		vzeta2 = vec_ld(32 + i * 64, mld_zetas_inv_al);
		vzeta3 = vec_ld(48 + i * 64, mld_zetas_inv_al);

		const vector unsigned char l3permb = { 0x00, 0x01, 0x02, 0x03, 0x08, 0x09,
			0x0A, 0x0B, 0x10, 0x11, 0x12, 0x13, 0x18, 0x19, 0x1A, 0x1B };
		const vector unsigned char l4permb = { 0x04, 0x05, 0x06, 0x07, 0x0C, 0x0D,
			0x0E, 0x0F, 0x14, 0x15, 0x16, 0x17, 0x1C, 0x1D, 0x1E, 0x1F };

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l3permb);
		vp5 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l4permb);
		vp4 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l3permb);
		vp7 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l4permb);
		vp6 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l3permb);
		vp9 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l4permb);
		vp8 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l3permb);
		vp11 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l4permb);
		vp10 = vt3;

		MLD_BUTTERFLY_INV(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* round 1 (len=2) */

		vt1 = vec_ld(512 + i * 32, mld_zetas_inv_al);
		vt2 = vec_ld(528 + i * 32, mld_zetas_inv_al);

		const vector unsigned char z0perm = { 0x00, 0x01, 0x02, 0x03,
			0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x04, 0x05, 0x06, 0x07 };
		const vector unsigned char z1perm = { 0x08, 0x09, 0x0A, 0x0B,
			0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x0C, 0x0D, 0x0E, 0x0F };

		vzeta0 = (vector signed int) vec_perm((vector unsigned char) vt1, (vector unsigned char) vt1, z0perm);
		vzeta1 = (vector signed int) vec_perm((vector unsigned char) vt1, (vector unsigned char) vt1, z1perm);
		vzeta2 = (vector signed int) vec_perm((vector unsigned char) vt2, (vector unsigned char) vt2, z0perm);
		vzeta3 = (vector signed int) vec_perm((vector unsigned char) vt2, (vector unsigned char) vt2, z1perm);

		const vector unsigned char l1permb = { 0x00, 0x01, 0x02, 0x03, 0x10, 0x11,
			0x12, 0x13, 0x08, 0x09, 0x0A, 0x0B, 0x18, 0x19, 0x1A, 0x1B };
		const vector unsigned char l2permb = { 0x04, 0x05, 0x06, 0x07, 0x14, 0x15,
			0x16, 0x17, 0x0C, 0x0D, 0x0E, 0x0F, 0x1c, 0x1d, 0x1e, 0x1f };

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l1permb);
		vp5 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l2permb);
		vp4 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l1permb);
		vp7 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l2permb);
		vp6 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l1permb);
		vp9 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l2permb);
		vp8 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l1permb);
		vp11 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l2permb);
		vp10 = vt3;

		MLD_BUTTERFLY_INV(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* output permutation */
		const vector unsigned char l1opermb = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
			0x06, 0x07, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17 };
		const vector unsigned char l2opermb = { 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
			0x0E, 0x0F, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f };

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l1opermb);
		vp5 = (vector signed int) vec_perm((vector unsigned char) vp4, (vector unsigned char) vp5, l2opermb);
		vp4 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l1opermb);
		vp7 = (vector signed int) vec_perm((vector unsigned char) vp6, (vector unsigned char) vp7, l2opermb);
		vp6 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l1opermb);
		vp9 = (vector signed int) vec_perm((vector unsigned char) vp8, (vector unsigned char) vp9, l2opermb);
		vp8 = vt3;

		vt3 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l1opermb);
		vp11 = (vector signed int) vec_perm((vector unsigned char) vp10, (vector unsigned char) vp11, l2opermb);
		vp10 = vt3;

		/* round 2 (len=4) */
		vzeta0 = vec_splats(mld_zetas_inv_al[192 + i * 4]);
		vzeta1 = vec_splats(mld_zetas_inv_al[192 + i * 4 + 1]);
		vzeta2 = vec_splats(mld_zetas_inv_al[192 + i * 4 + 2]);
		vzeta3 = vec_splats(mld_zetas_inv_al[192 + i * 4 + 3]);

		MLD_BUTTERFLY_INV(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* round 3 (len=8) */
		vzeta0 = vec_splats(mld_zetas_inv_al[224 + i * 2 + 0]);
		vzeta1 = vec_splats(mld_zetas_inv_al[224 + i * 2 + 1]);

		MLD_BUTTERFLY_INV(vp4, vp6, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp5, vp7, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp8, vp10, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp9, vp11, vzeta1, vt1, vt2, _qinvx4, _qx4);

		/* round 4  (len=16) */
		vzeta0 = vec_splats(mld_zetas_inv_al[240 + i]);

		MLD_BUTTERFLY_INV(vp4, vp8, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp5, vp9, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp6, vp10, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp7, vp11, vzeta0, vt1, vt2, _qinvx4, _qx4);

		/* store back */
		*(pr + 8 * i) = vp4;
		*(pr + 8 * i + 2) = vp6;
		*(pr + 8 * i + 1) = vp5;
		*(pr + 8 * i + 5) = vp9;
		*(pr + 8 * i + 4) = vp8;
		*(pr + 8 * i + 3) = vp7;
		*(pr + 8 * i + 6) = vp10;
		*(pr + 8 * i + 7) = vp11;
	}

	for (i = 0; i < 8; i++) {
		/* load */
		vp4 = *(pr + i + 0);   /* r[j]              */
		vp5 = *(pr + i + 8);   /* r[j]              */
		vp6 = *(pr + i + 16);  /* r[j+len]          */
		vp7 = *(pr + i + 24);  /* r[j+len]          */
		vp8 = *(pr + i + 32);  /* r[j]              */
		vp9 = *(pr + i + 40);  /* r[j]              */
		vp10 = *(pr + i + 48); /* r[j+len]          */
		vp11 = *(pr + i + 56); /* r[j+len]          */
				       /* round 5  (len=32) */
		vzeta0 = vec_splats(mld_zetas_inv_al[248]);
		vzeta1 = vec_splats(mld_zetas_inv_al[249]);
		vzeta2 = vec_splats(mld_zetas_inv_al[250]);
		vzeta3 = vec_splats(mld_zetas_inv_al[251]);

		MLD_BUTTERFLY_INV(vp4, vp5, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp6, vp7, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp8, vp9, vzeta2, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp10, vp11, vzeta3, vt1, vt2, _qinvx4, _qx4);

		/* round 6  (len=64) */
		vzeta0 = vec_splats(mld_zetas_inv_al[252]);
		vzeta1 = vec_splats(mld_zetas_inv_al[253]);

		MLD_BUTTERFLY_INV(vp4, vp6, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp5, vp7, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp8, vp10, vzeta1, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp9, vp11, vzeta1, vt1, vt2, _qinvx4, _qx4);

		/* round 7  (len=128) */
		vzeta0 = vec_splats(mld_zetas_inv_al[254]);

		MLD_BUTTERFLY_INV(vp4, vp8, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp5, vp9, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp6, vp10, vzeta0, vt1, vt2, _qinvx4, _qx4);
		MLD_BUTTERFLY_INV(vp7, vp11, vzeta0, vt1, vt2, _qinvx4, _qx4);

		/* monty_red_f_star: multiplies by f (mont^2/256) and reduces mod Q */
		/* processes 4 coefficients in parallel per vector using SIMD multiply */
		MLD_MONTY_RED_F_STAR(vp4, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i) = vp4;
		MLD_MONTY_RED_F_STAR(vp5, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i + 8) = vp5;
		MLD_MONTY_RED_F_STAR(vp6, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i + 16) = vp6;
		MLD_MONTY_RED_F_STAR(vp7, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i + 24) = vp7;
		MLD_MONTY_RED_F_STAR(vp8, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i + 32) = vp8;
		MLD_MONTY_RED_F_STAR(vp9, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i + 40) = vp9;
		MLD_MONTY_RED_F_STAR(vp10, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i + 48) = vp10;
		MLD_MONTY_RED_F_STAR(vp11, vt1, vt2, f, _qinvx4, _qx4);
		*(pr + i + 56) = vp11;
	}
}

/* Undefine macros to allow re-inclusion with different suffix */
#undef MLD_NTT_SUFFIX
#undef MLD_NTT_CONCAT_INNER
#undef MLD_NTT_CONCAT
#undef MLD_NTT_CONCAT3_INNER
#undef MLD_NTT_CONCAT3
#undef MLD_NTT_FUNC
#undef MLD_BUTTERFLY
#undef MLD_BUTTERFLY_INV
#undef MLD_MONTY_RED_F_STAR
