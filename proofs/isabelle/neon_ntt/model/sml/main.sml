(* Copyright (c) The mldsa-native project authors
   SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT *)

(* SML CLI harness wrapping the exported Isabelle model.

   Two modes:
   * One-shot:  model_exec MNEMONIC BITWIDTH ARG0 [ARG1 ...]
                  -> prints one hex result, exits.
   * Streaming: model_exec --stream
                  reads one space-separated case per line on stdin
                  ("MNEMONIC BITWIDTH ARG0 [ARG1 ...]"), writes the hex
                  result on stdout per line (or "ERROR <msg>" without
                  exiting). Output is line-buffered.

   Inputs accept hex (0x...) or decimal (incl. negative). Inputs are
   reduced mod 2^bw to unsigned. Output is 0x-prefixed lowercase hex
   padded to bw/4 nibbles. *)

use "export/NeonNTT.Word_Ops_Export/code/model.ML";

fun die msg =
  (TextIO.output (TextIO.stdErr, msg ^ "\n");
   OS.Process.exit OS.Process.failure)

(* Parse signed integer in decimal or 0x-prefixed hex *)
exception ParseFail of string
fun parse_int_opt s =
  let
    val (neg, body) =
      if size s > 0 andalso String.sub (s, 0) = #"-"
      then (true, String.extract (s, 1, NONE))
      else (false, s)
    val (radix, digits) =
      if size body >= 2
         andalso String.sub (body, 0) = #"0"
         andalso (String.sub (body, 1) = #"x" orelse String.sub (body, 1) = #"X")
      then (StringCvt.HEX, String.extract (body, 2, NONE))
      else (StringCvt.DEC, body)
  in
    case StringCvt.scanString (IntInf.scan radix) digits of
      SOME v => SOME (if neg then IntInf.~ v else v)
    | NONE   => NONE
  end

fun parse_int s =
  case parse_int_opt s of
    SOME v => v
  | NONE   => raise ParseFail ("not an integer: " ^ s)

(* Validate a parsed bitwidth: must fit in a small int and be in [1, 64].
   Without this, a malicious caller could request bw = 2^60, causing the
   `1 << bw` below to allocate or trap. *)
fun parse_bw bw_str =
  let
    val v = parse_int bw_str
  in
    if IntInf.< (v, 1) orelse IntInf.> (v, 64)
    then raise ParseFail ("bitwidth out of range [1,64]: " ^ bw_str)
    else IntInf.toInt v
  end

(* Reduce x mod 2^bw to the unsigned range [0, 2^bw). bw is a small int. *)
fun mod_unsigned bw x =
  let
    val m = IntInf.<< (1, Word.fromInt bw)
    val r = IntInf.mod (x, m)
  in if IntInf.< (r, 0) then IntInf.+ (r, m) else r end

(* Pad unsigned hex string to bw/4 nibbles, lowercase, 0x-prefixed. *)
fun fmt_hex bw x =
  let
    val nibbles = (bw + 3) div 4
    val raw = IntInf.fmt StringCvt.HEX x
    val lower = String.translate (fn c => str (Char.toLower c)) raw
    val pad = nibbles - size lower
    val padded = if pad > 0 then String.implode (List.tabulate (pad, fn _ => #"0")) ^ lower else lower
  in "0x" ^ padded end

(* Run one case from a token list. Returns the formatted hex line, or
   raises ParseFail with a message. *)
fun run_case (mn :: bw_str :: arg_strs) =
      let
        val bw_int = parse_bw bw_str
        val bw = IntInf.fromInt bw_int
        val xs = map parse_int arg_strs
        val xs_u = map (mod_unsigned bw_int) xs
      in
        case Model.model_exec mn bw xs_u of
          SOME r => fmt_hex bw_int r
        | NONE   => raise ParseFail ("unsupported: " ^ mn ^ " " ^ IntInf.toString bw
                                     ^ " arity=" ^ Int.toString (length xs))
      end
  | run_case _ = raise ParseFail "expected: MNEMONIC BITWIDTH ARG..."

fun tokens s =
  String.tokens (fn c => c = #" " orelse c = #"\t" orelse c = #"\r") s

fun stream_loop () =
  case TextIO.inputLine TextIO.stdIn of
    NONE => ()
  | SOME line =>
      let
        val toks = tokens line
      in
        if toks = [] then stream_loop ()
        else
          let
            val result =
              SOME (run_case toks)
              handle ParseFail m =>
                       (TextIO.output (TextIO.stdErr,
                                       "model_exec: " ^ m ^ "\n  input: " ^ line);
                        OS.Process.exit OS.Process.failure)
                   | exn =>
                       (TextIO.output (TextIO.stdErr,
                                       "model_exec: exception: " ^ exnMessage exn
                                       ^ "\n  input: " ^ line);
                        OS.Process.exit OS.Process.failure)
          in
            case result of
              SOME s =>
                (print s; print "\n"; TextIO.flushOut TextIO.stdOut;
                 stream_loop ())
            | NONE => ()  (* unreachable: handlers above call exit *)
          end
      end

(* Split off args after the first "--", if present. Lets us be invoked
   either directly (compiled binary) or via `poly --use ... -- USER_ARGS`. *)
fun user_args () =
  let
    fun split [] acc = (rev acc, [])
      | split ("--" :: rest) acc = (rev acc, rest)
      | split (x :: xs) acc = split xs (x :: acc)
    val all = CommandLine.arguments ()
    val (_, after) = split all []
  in
    if after = [] andalso List.exists (fn x => x = "--") all = false
    then all  (* no `--` at all: assume direct invocation *)
    else after
  end

fun main () =
  case user_args () of
    ["--stream"] => stream_loop ()
  | (mn :: bw_str :: args) =>
      (print (run_case (mn :: bw_str :: args) ^ "\n")
       handle ParseFail m => die m)
  | _ => die "usage: model_exec MNEMONIC BITWIDTH ARG... | model_exec --stream"
