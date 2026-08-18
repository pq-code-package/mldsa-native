#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# Wycheproof test client for ML-DSA
# See https://github.com/C2SP/wycheproof
# Invokes `wycheproof_mldsa{lvl}` under the hood.

import argparse
import os
import json
import sys
import subprocess
import time
import urllib.error
import urllib.request
from enum import Enum, auto
from pathlib import Path

exec_prefix = os.environ.get("EXEC_WRAPPER", "")
exec_prefix = exec_prefix.split(" ") if exec_prefix != "" else []

# Pinned to a specific commit (2026-07-07).
WYCHEPROOF_COMMIT = "fc24cd5b787d8e496bff31b0468af693a652b0f2"
WYCHEPROOF_BASE_URL = (
    "https://api.github.com/repos/C2SP/wycheproof/contents/testvectors_v1"
)

WYCHEPROOF_FILES = [
    "mldsa_44_sign_seed_test.json",
    "mldsa_44_sign_noseed_test.json",
    "mldsa_44_verify_test.json",
    "mldsa_65_sign_seed_test.json",
    "mldsa_65_sign_noseed_test.json",
    "mldsa_65_verify_test.json",
    "mldsa_87_sign_seed_test.json",
    "mldsa_87_sign_noseed_test.json",
    "mldsa_87_verify_test.json",
]

ALGORITHM_TO_LEVEL = {
    "ML-DSA-44": 44,
    "ML-DSA-65": 65,
    "ML-DSA-87": 87,
}

# Fields each test-case handler knows how to interpret. If Wycheproof adds a
# new field to a schema, an unrecognized key here means it may carry
# information we are silently failing to check; fail loudly instead.
KNOWN_FIELDS = {
    "sign_seed": {
        "tcId",
        "comment",
        "flags",
        "result",
        "msg",
        "mu",
        "ctx",
        "rnd",
        "sig",
    },
    "sign_noseed": {
        "tcId",
        "comment",
        "flags",
        "result",
        "msg",
        "mu",
        "ctx",
        "rnd",
        "sig",
    },
    "verify": {"tcId", "comment", "flags", "result", "msg", "ctx", "sig"},
}


def err(msg, **kwargs):
    print(msg, file=sys.stderr, **kwargs)


def fail(msg):
    err(msg)
    sys.exit(1)


def require(condition, msg):
    if not condition:
        fail(msg)


def info(msg, **kwargs):
    print(msg, **kwargs)


def download_file(url, dest, token):
    """Fetch url to dest via the authenticated contents API, retrying on failure.

    Using api.github.com with a token raises the rate limit (per-user, not
    per-IP), which avoids throttling when many CI jobs share an egress IP.
    """
    headers = {"Accept": "application/vnd.github.raw"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req) as resp:
                dest.write_bytes(resp.read())
            return
        except Exception as e:
            if attempt == 4:
                raise
            wait = 2**attempt
            if isinstance(e, urllib.error.HTTPError):
                wait = min(int(e.headers.get("Retry-After") or wait), 60)
            print(f"Download failed ({e}); retrying in {wait}s", file=sys.stderr)
            time.sleep(wait)


def check_known_fields(kind, tc):
    unknown = set(tc.keys()) - KNOWN_FIELDS[kind]
    require(
        not unknown,
        f"Unrecognized field(s) {sorted(unknown)} in {kind} tcId={tc['tcId']}; "
        "Wycheproof schema may have grown a new field this client doesn't check",
    )


def get_wycheproof_data_dir(data_dir):
    return Path(data_dir) / WYCHEPROOF_COMMIT


def download_wycheproof_files(data_dir):
    """Download Wycheproof test vector files if not present."""
    data_dir = Path(data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)

    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    auth = "authenticated" if token else "anonymous"
    for filename in WYCHEPROOF_FILES:
        local_file = data_dir / filename
        if not local_file.exists():
            url = f"{WYCHEPROOF_BASE_URL}/{filename}?ref={WYCHEPROOF_COMMIT}"
            print(f"Downloading {filename} ({auth})...", file=sys.stderr)
            try:
                download_file(url, local_file, token)
                with open(local_file, "r", encoding="utf-8") as f:
                    json.load(f)
            except (json.JSONDecodeError, Exception) as e:
                print(f"Error downloading {filename}: {e}", file=sys.stderr)
                if local_file.exists():
                    local_file.unlink()
                return False
    return True


def get_binary(level):
    basedir = f"./test/build/mldsa{level}/bin"
    return f"{basedir}/wycheproof_mldsa{level}"


def detect_supported_modes():
    """Run wycheproof_mldsa44 --info to detect which modes are supported."""
    wycheproof_bin = "./test/build/mldsa44/bin/wycheproof_mldsa44"
    wycheproof_call = exec_prefix + [wycheproof_bin, "--info"]
    try:
        result = subprocess.run(wycheproof_call, encoding="utf-8", capture_output=True)
        if result.returncode != 0:
            err(
                f"Warning: {wycheproof_call} failed (rc={result.returncode}), assuming all modes supported"
            )
            return {"keyGen", "sigGen", "sigVer", "pkFromSk"}
        modes = set()
        for line in result.stdout.splitlines():
            line = line.strip()
            if line in ("keyGen", "sigGen", "sigVer", "pkFromSk"):
                modes.add(line)
        return modes
    except FileNotFoundError:
        err(f"Warning: {wycheproof_bin} not found, assuming all modes supported")
        return {"keyGen", "sigGen", "sigVer", "pkFromSk"}


# File-type → set of modes the binary must support to run those tests.
FILE_REQUIRED_MODES = {
    "sign_seed_test": {"keyGen", "sigGen"},
    "sign_noseed_test": {"sigGen"},
    "verify_test": {"sigVer"},
}


def run_binary(args_list):
    result = subprocess.run(
        exec_prefix + args_list, encoding="utf-8", capture_output=True
    )
    if result.returncode != 0:
        return {"_error": str(result.returncode)}
    out = {}
    for line in result.stdout.strip().splitlines():
        k, v = line.split("=", 1)
        out[k] = v
    return out


def append_optional_rnd(args_list, tc):
    rnd = tc.get("rnd")
    if rnd is not None:
        args_list.append(f"rnd={rnd}")
    return args_list


class TestResult(Enum):
    OK = auto()
    SKIPPED = auto()


def check_sign_result(tc, out):
    if tc["result"] == "invalid":
        flags = tc.get("flags", [])
        # FIPS 204 does not require signing to validate serialized private keys.
        # Checking only s1/s2 would be incomplete: full validation also checks
        # t0 and tr and is exposed through pk_from_sk. These InvalidPrivateKey
        # vectors are skipped for signing and still tested through pkFromSk.
        if "InvalidPrivateKey" in flags:
            return TestResult.SKIPPED
        # If new invalid-flag classes appear, fail loudly so we can handle them.
        require(
            "IncorrectPrivateKeyLength" in flags or "InvalidContext" in flags,
            f"unhandled invalid flag(s) {flags} for tcId={tc['tcId']}",
        )
        require(
            "decode_error" in out,
            f"expected decode_error on invalid tcId={tc['tcId']}",
        )
    elif tc["result"] == "valid":
        require("signature" in out, f"missing signature for tcId={tc['tcId']}")
        require(
            out["signature"].upper() == tc["sig"].upper(),
            f"signature mismatch tcId={tc['tcId']}",
        )
    else:
        fail(f"Unsupported test result '{tc['result']}' for tcId={tc['tcId']}")
    return TestResult.OK


def run_sign_seed_test(data_file):
    """Run mldsa_*_sign_seed_test.json tests."""
    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    info(f"Running sign_seed tests from {data_file}")
    binary = get_binary(ALGORITHM_TO_LEVEL[data["algorithm"]])
    count = 0
    for tg in data["testGroups"]:
        seed_hex = tg["privateSeed"]
        for tc in tg["tests"]:
            check_known_fields("sign_seed", tc)
            info(f"  tcId={tc['tcId']} ... ", end="")
            if "Internal" in tc.get("flags", []):
                out = run_binary(
                    append_optional_rnd(
                        [
                            binary,
                            "sigGenSeedDeterministic",
                            f"seed={seed_hex}",
                            f"message={tc['mu']}",
                            "context=",
                            "externalMu=1",
                        ],
                        tc,
                    )
                )
            else:
                out = run_binary(
                    append_optional_rnd(
                        [
                            binary,
                            "sigGenSeedDeterministic",
                            f"seed={seed_hex}",
                            f"message={tc['msg']}",
                            f"context={tc.get('ctx', '')}",
                            "externalMu=0",
                        ],
                        tc,
                    )
                )
            result = check_sign_result(tc, out)
            info("skipped" if result == TestResult.SKIPPED else "ok")
            count += 1
    info(f"  {count} sign_seed tests passed")


def run_sign_noseed_test(data_file):
    """Run mldsa_*_sign_noseed_test.json tests."""
    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    info(f"Running sign_noseed tests from {data_file}")
    binary = get_binary(ALGORITHM_TO_LEVEL[data["algorithm"]])
    count = 0
    for tg in data["testGroups"]:
        sk_hex = tg["privateKey"]
        for tc in tg["tests"]:
            check_known_fields("sign_noseed", tc)
            info(f"  tcId={tc['tcId']} ... ", end="")
            if "Internal" in tc.get("flags", []):
                out = run_binary(
                    append_optional_rnd(
                        [
                            binary,
                            "sigGenInternalDeterministic",
                            f"message={tc['mu']}",
                            f"sk={sk_hex}",
                            "externalMu=1",
                        ],
                        tc,
                    )
                )
            else:
                out = run_binary(
                    append_optional_rnd(
                        [
                            binary,
                            "sigGenDeterministic",
                            f"message={tc['msg']}",
                            f"context={tc.get('ctx', '')}",
                            f"sk={sk_hex}",
                        ],
                        tc,
                    )
                )
            result = check_sign_result(tc, out)
            info("skipped" if result == TestResult.SKIPPED else "ok")
            count += 1
    info(f"  {count} sign_noseed tests passed")


def run_verify_test(data_file):
    """Run mldsa_*_verify_test.json tests."""
    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    info(f"Running verify tests from {data_file}")
    binary = get_binary(ALGORITHM_TO_LEVEL[data["algorithm"]])
    count = 0
    for tg in data["testGroups"]:
        pk_hex = tg["publicKey"]
        for tc in tg["tests"]:
            check_known_fields("verify", tc)
            info(f"  tcId={tc['tcId']} ... ", end="")
            out = run_binary(
                [
                    binary,
                    "sigVer",
                    f"message={tc['msg']}",
                    f"context={tc.get('ctx', '')}",
                    f"signature={tc['sig']}",
                    f"pk={pk_hex}",
                ]
            )
            if tc["result"] == "invalid":
                # _error: non-zero exit code; decode_error: explicit validation failure
                require(
                    "_error" in out or "decode_error" in out,
                    f"binary success on invalid tcId={tc['tcId']}",
                )
            elif tc["result"] == "valid":
                require(
                    "_error" not in out and "decode_error" not in out,
                    f"binary failure on valid tcId={tc['tcId']}",
                )
            else:
                fail(f"Unsupported test result '{tc['result']}' for tcId={tc['tcId']}")
            info("ok")
            count += 1
    info(f"  {count} verify tests passed")


def check_pk_from_sk_result(tc, tg, out):
    flags = tc.get("flags", [])
    if "IncorrectPrivateKeyLength" in flags:
        require(
            "decode_error" in out,
            f"expected decode_error for IncorrectPrivateKeyLength tcId={tc['tcId']}",
        )
    elif "InvalidPrivateKey" in flags:
        require(
            "_error" in out, f"pk_from_sk accepted invalid SK for tcId={tc['tcId']}"
        )
    else:
        require("pk" in out, f"pk_from_sk failed on valid SK for tcId={tc['tcId']}")
        require(
            out["pk"].upper() == tg["publicKey"].upper(),
            f"pk_from_sk derived wrong PK for tcId={tc['tcId']}",
        )


def run_pk_from_sk_noseed_test(data_file):
    """Run pk_from_sk on all noseed signing test groups."""
    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    info(f"Running pk_from_sk tests from {data_file}")
    binary = get_binary(ALGORITHM_TO_LEVEL[data["algorithm"]])
    count = 0
    for tg in data["testGroups"]:
        sk_hex = tg["privateKey"]
        for tc in tg["tests"]:
            check_known_fields("sign_noseed", tc)
            info(f"  tcId={tc['tcId']} ... ", end="")
            out = run_binary([binary, "pkFromSk", f"sk={sk_hex}"])
            check_pk_from_sk_result(tc, tg, out)
            info("ok")
            count += 1
    info(f"  {count} pk_from_sk tests passed")


def run_all(data_dir, supported_modes):
    """Run all Wycheproof test vector files."""
    data_dir = Path(data_dir)
    for filename in WYCHEPROOF_FILES:
        filepath = data_dir / filename
        for kind, runner in (
            ("sign_seed_test", run_sign_seed_test),
            ("sign_noseed_test", run_sign_noseed_test),
            ("verify_test", run_verify_test),
        ):
            if kind not in filename:
                continue
            if not FILE_REQUIRED_MODES[kind].issubset(supported_modes):
                info(f"Skipping {filename} (modes not supported in this build)")
                break
            runner(filepath)
            break

        if "sign_noseed_test" in filename and "pkFromSk" in supported_modes:
            run_pk_from_sk_noseed_test(filepath)

    info("ALL GOOD!")


parser = argparse.ArgumentParser(description="Wycheproof ML-DSA test client")
parser.add_argument(
    "-f",
    "--file",
    help="Path to a specific Wycheproof test vector JSON file",
    required=False,
)
parser.add_argument(
    "--data-dir",
    default="test/wycheproof/.wycheproof-data",
    help="Directory for downloaded test vectors (default: test/wycheproof/.wycheproof-data)",
)
parser.add_argument(
    "--no-keygen",
    action="store_true",
    help="Skip tests requiring keyGen",
)
parser.add_argument(
    "--no-sign",
    action="store_true",
    help="Skip tests requiring sigGen",
)
parser.add_argument(
    "--no-verify",
    action="store_true",
    help="Skip tests requiring sigVer",
)
parser.add_argument(
    "--no-pkfromsk",
    action="store_true",
    help="Skip tests requiring pkFromSk",
)
parser.add_argument(
    "--auto-detect",
    action="store_true",
    default=True,
    help="Auto-detect supported modes by running wycheproof_mldsa44 --info (default: True)",
)
args = parser.parse_args()

# Determine supported modes
if args.auto_detect and args.file is None:
    supported_modes = detect_supported_modes()
    info(f"Auto-detected supported modes: {sorted(supported_modes)}")
else:
    supported_modes = {"keyGen", "sigGen", "sigVer", "pkFromSk"}

# Apply explicit --no-* flags
if args.no_keygen:
    supported_modes.discard("keyGen")
if args.no_sign:
    supported_modes.discard("sigGen")
if args.no_verify:
    supported_modes.discard("sigVer")
if args.no_pkfromsk:
    supported_modes.discard("pkFromSk")

if args.file:
    # Run a single file
    filename = os.path.basename(args.file)
    if "sign_seed_test" in filename:
        run_sign_seed_test(args.file)
    elif "sign_noseed_test" in filename:
        run_sign_noseed_test(args.file)
        if "pkFromSk" in supported_modes:
            run_pk_from_sk_noseed_test(args.file)
    elif "verify_test" in filename:
        run_verify_test(args.file)
    else:
        err(f"Unknown test file type: {filename}")
        sys.exit(1)
    info("ALL GOOD!")
else:
    # Download and run all
    data_dir = get_wycheproof_data_dir(args.data_dir)
    if not download_wycheproof_files(data_dir):
        err("Failed to download Wycheproof test files")
        sys.exit(1)
    run_all(data_dir, supported_modes)
