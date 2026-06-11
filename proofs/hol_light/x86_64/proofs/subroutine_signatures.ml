(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* ML-DSA subroutine signatures for constant-time proofs.                    *)
(* Trimmed version of s2n-bignum's x86/proofs/subroutine_signatures.ml.      *)
(* ========================================================================= *)

let subroutine_signatures = [
("mldsa_polyz_unpack_17_x86",
  ([(*args*)
     ("r", "int32_t[static 256]", (*is const?*)"false");
     ("a", "uint8_t[static 576]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "576"(* num elems *), 1(* elem bytesize *));
   ],
   [(* output buffers *)
    ("r", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);
("mldsa_polyz_unpack_19_x86",
  ([(*args*)
     ("r", "int32_t[static 256]", (*is const?*)"false");
     ("a", "uint8_t[static 640]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "640"(* num elems *), 1(* elem bytesize *));
   ],
   [(* output buffers *)
    ("r", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);
("mldsa_poly_caddq_x86",
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

("mldsa_poly_chknorm_x86",
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

("mldsa_poly_decompose_32_x86",
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

("mldsa_poly_decompose_88_x86",
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

("mldsa_pointwise_x86",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("b", "int32_t[static 256]", (*is const?*)"true");
     ("qdata", "int32_t[static 624]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("b", "256"(* num elems *), 4(* elem bytesize *));
    ("qdata", "624"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_pointwise_acc_l4_x86",
  ([(*args*)
     ("c", "int32_t[static 256]", (*is const?*)"false");
     ("a", "int32_t[static 1024]", (*is const?*)"true");
     ("b", "int32_t[static 1024]", (*is const?*)"true");
     ("qdata", "int32_t[static 624]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "1024"(* num elems *), 4(* elem bytesize *));
    ("b", "1024"(* num elems *), 4(* elem bytesize *));
    ("qdata", "624"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("c", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_pointwise_acc_l5_x86",
  ([(*args*)
     ("c", "int32_t[static 256]", (*is const?*)"false");
     ("a", "int32_t[static 1280]", (*is const?*)"true");
     ("b", "int32_t[static 1280]", (*is const?*)"true");
     ("qdata", "int32_t[static 624]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "1280"(* num elems *), 4(* elem bytesize *));
    ("b", "1280"(* num elems *), 4(* elem bytesize *));
    ("qdata", "624"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("c", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_pointwise_acc_l7_x86",
  ([(*args*)
     ("c", "int32_t[static 256]", (*is const?*)"false");
     ("a", "int32_t[static 1792]", (*is const?*)"true");
     ("b", "int32_t[static 1792]", (*is const?*)"true");
     ("qdata", "int32_t[static 624]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "1792"(* num elems *), 4(* elem bytesize *));
    ("b", "1792"(* num elems *), 4(* elem bytesize *));
    ("qdata", "624"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("c", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);


("mldsa_intt",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("zetas", "int32_t[static 624]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("zetas", "624"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_ntt",
  ([(*args*)
     ("a", "int32_t[static 256]", (*is const?*)"false");
     ("zetas", "int32_t[static 624]", (*is const?*)"true");
   ],
   "void",
   [(* input buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
    ("zetas", "624"(* num elems *), 4(* elem bytesize *));
   ],
   [(* output buffers *)
    ("a", "256"(* num elems *), 4(* elem bytesize *));
   ],
   [(* temporary buffers *)
   ])
);

("mldsa_nttunpack",
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

("keccak_f1600_x4_avx2",
  ([(*args*)
     ("bitstate_in", "uint64_t[static 100]", (*is const?*)"false");
     ("rc_pointer", "const uint64_t[static 24]", (*is const?*)"true");
     ("rho8_ptr", "const uint64_t[static 4]", (*is const?*)"true");
     ("rho56_ptr", "const uint64_t[static 4]", (*is const?*)"true")],
   "void",
   [(* input buffers *)
    ("bitstate_in", "100"(* num elems *), 8(* elem bytesize *));
    ("rc_pointer", "24"(* num elems *), 8(* elem bytesize *));
    ("rho8_ptr", "4"(* num elems *), 8(* elem bytesize *));
    ("rho56_ptr", "4"(* num elems *), 8(* elem bytesize *))],
   [(* output buffers *)
    ("bitstate_in", "100"(* num elems *), 8(* elem bytesize *))],
   [(* temporary buffers *)
   ])
);

];;

