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
];;
