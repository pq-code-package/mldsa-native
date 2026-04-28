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
];;
