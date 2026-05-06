(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* ML-DSA subroutine signatures for constant-time proofs.                    *)
(* Trimmed version of s2n-bignum's arm/proofs/subroutine_signatures.ml.      *)
(* ========================================================================= *)

let subroutine_signatures = [
("mldsa_intt_arm",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("z_78", "int32_t[static 384]", (*is const?*)"true");
     ("z_123456", "int32_t[static 160]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("z_78", "384"(* num elems *), 4(* elem bytesize *));
    ("z_123456", "160"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);
("mldsa_ntt_arm",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("z_012345", "int32_t[144]", (*is const?*)"true");
     ("z_67", "int32_t[384]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("z_012345", "144"(* num elems *), 4(* elem bytesize *));
    ("z_67", "384"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);
("mldsa_pointwise",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("b", "int32_t[static 256]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("b", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_poly_caddq",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_poly_chknorm",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"true");
     ("bound", "int32_t", (*is const?*)"false");
   ],
   "uint64_t",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_pointwise_acc_l4",
  ([(*args*)
     ("r", "int32_t[static 256]", (*is const?*)"false");
     ("a", "int32_t[static 1024]", (*is const?*)"true");
     ("b", "int32_t[static 1024]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "1024"(* num elems *), 4(* elem bytesize *));
    ("b", "1024"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("r", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_pointwise_acc_l5",
  ([(*args*)
     ("r", "int32_t[static 256]", (*is const?*)"false");
     ("a", "int32_t[static 1280]", (*is const?*)"true");
     ("b", "int32_t[static 1280]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "1280"(* num elems *), 4(* elem bytesize *));
    ("b", "1280"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("r", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("poly_use_hint_32_aarch64_asm",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("h", "int32_t[static 256]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("h", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("poly_decompose_32_aarch64_asm",
  ([(*args*)
     ("a1", "int32_t[static 256]", (*is const?*)"false");
     ("a0", "int32_t[static 256]", (*is const?*)"false");
   ],
   "void",
   [(* input buffers *)
    ("a0", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a1", "256"(* num elems *), 4(* elem bytesize *));
    ("a0", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("poly_decompose_88_aarch64_asm",
  ([(*args*)
     ("a1", "int32_t[static 256]", (*is const?*)"false");
     ("a0", "int32_t[static 256]", (*is const?*)"false");
   ],
   "void",
   [(* input buffers *)
    ("a0", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a1", "256"(* num elems *), 4(* elem bytesize *));
    ("a0", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("poly_use_hint_88_aarch64_asm",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("h", "int32_t[static 256]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("h", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_pointwise_acc_l7",
  ([(*args*)
     ("r", "int32_t[static 256]", (*is const?*)"false");
     ("a", "int32_t[static 1792]", (*is const?*)"true");
     ("b", "int32_t[static 1792]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "1792"(* num elems *), 4(* elem bytesize *));
    ("b", "1792"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("r", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_polyz_unpack_17",
  ([(*args*)
     ("r", "int32_t[static 256]", (*is const?*)"false");
     ("b", "uint8_t[static 576]", (*is const?*)"true");
     ("t", "uint8_t[static 64]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("b", "576"(* num elems *), 1(* elem bytesize *));
    ("t", "64"(* num elems *), 1(* elem bytesize *));
   ],
   [(* output buffers *)
    ("r", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_polyz_unpack_19",
  ([(*args*)
     ("r", "int32_t[static 256]", (*is const?*)"false");
     ("b", "uint8_t[static 640]", (*is const?*)"true");
     ("t", "uint8_t[static 64]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("b", "640"(* num elems *), 1(* elem bytesize *));
    ("t", "64"(* num elems *), 1(* elem bytesize *));
   ],
   [(* output buffers *)
    ("r", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("sha3_keccak_f1600",
  ([(*args*)
     ("a", "uint64_t[static 25]", (*is const?*)"false");
     ("rc", "uint64_t[static 24]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "25"(* num elems *), 8(* elem bytesize *));
    ("rc", "24"(* num elems *), 8(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "25"(* num elems *), 8(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("sha3_keccak_f1600_alt",
  ([(*args*)
     ("a", "uint64_t[static 25]", (*is const?*)"false");
     ("rc", "uint64_t[static 24]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "25"(* num elems *), 8(* elem bytesize *));
    ("rc", "24"(* num elems *), 8(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "25"(* num elems *), 8(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("sha3_keccak2_f1600",
  ([(*args*)
     ("a", "uint64_t[static 50]", (*is const?*)"false");
     ("rc", "uint64_t[static 24]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "50"(* num elems *), 8(* elem bytesize *));
    ("rc", "24"(* num elems *), 8(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "50"(* num elems *), 8(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("sha3_keccak4_f1600",
  ([(*args*)
     ("a", "uint64_t[static 100]", (*is const?*)"false");
     ("rc", "uint64_t[static 24]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "100"(* num elems *), 8(* elem bytesize *));
    ("rc", "24"(* num elems *), 8(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "100"(* num elems *), 8(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("sha3_keccak4_f1600_alt",
  ([(*args*)
     ("a", "uint64_t[static 100]", (*is const?*)"false");
     ("rc", "uint64_t[static 24]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "100"(* num elems *), 8(* elem bytesize *));
    ("rc", "24"(* num elems *), 8(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "100"(* num elems *), 8(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);
];;
