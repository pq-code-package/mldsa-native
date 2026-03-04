#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

# Wycheproof test client for ML-DSA
# Invokes `wycheproof_mldsa{lvl}` under the hood.

import argparse
import os
import json
import sys
import subprocess
import urllib.request
from pathlib import Path

exec_prefix = os.environ.get("EXEC_WRAPPER", "")
exec_prefix = exec_prefix.split(" ") if exec_prefix != "" else []

WYCHEPROOF_BASE_URL = (
    "https://raw.githubusercontent.com/C2SP/wycheproof/main/testvectors_v1"
)

WYCHEPROOF_FILES = [
    "mldsa_44_sign_noseed_test.json",
    "mldsa_44_sign_seed_test.json",
    "mldsa_44_verify_test.json",
    "mldsa_65_sign_noseed_test.json",
    "mldsa_65_sign_seed_test.json",
    "mldsa_65_verify_test.json",
    "mldsa_87_sign_noseed_test.json",
    "mldsa_87_sign_seed_test.json",
    "mldsa_87_verify_test.json",
]

PARAMETER_SET_TO_LEVEL = {
    "ML-DSA-44": 44,
    "ML-DSA-65": 65,
    "ML-DSA-87": 87,
}


def err(msg, **kwargs):
    print(msg, file=sys.stderr, **kwargs)


def info(msg, **kwargs):
    print(msg, **kwargs)


def download_wycheproof_files(data_dir):
    data_dir = Path(data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)
    for filename in WYCHEPROOF_FILES:
        local_file = data_dir / filename
        if not local_file.exists():
            url = f"{WYCHEPROOF_BASE_URL}/{filename}"
            print(f"Downloading {filename}...", file=sys.stderr)
            try:
                urllib.request.urlretrieve(url, local_file)
                with open(local_file, "r", encoding="utf-8") as f:
                    json.load(f)
            except Exception as e:
                print(f"Error downloading {filename}: {e}", file=sys.stderr)
                local_file.unlink(missing_ok=True)
                return False
    return True


def get_binary(level):
    basedir = f"./test/build/mldsa{level}/bin"
    return f"{basedir}/wycheproof_mldsa{level}"


def run_binary(args_list):
    result = subprocess.run(
        exec_prefix + args_list, encoding="utf-8", capture_output=True
    )
    if result.returncode != 0:
        return {"_error": str(result.returncode)}
    out = {}
    for line in result.stdout.strip().splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            out[k] = v
    return out


def run_sign_tests(data_file, has_seed=False):
    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    info(f"Running sign tests from {data_file}")
    count = 0

    # Extract algorithm from the root JSON object, not the test group
    level = PARAMETER_SET_TO_LEVEL[data["algorithm"]]
    binary = get_binary(level)

    for tg in data["testGroups"]:
        sk = tg.get("privateKey", "")
        if has_seed and "privateSeed" in tg:
            keygen_out = run_binary(
                [binary, "keygen_seed", f"seed={tg['privateSeed']}"]
            )
            if "_error" not in keygen_out and "decode_error" not in keygen_out:
                sk = keygen_out.get("sk", "")

        for tc in tg["tests"]:
            info(f"Running sigGen test case {tc['tcId']} ... ", end="", flush=True)
            is_internal = "Internal" in tc.get("flags", [])

            if is_internal:
                out = run_binary(
                    [binary, "sign_internal", f"mu={tc.get('mu', '')}", f"sk={sk}"]
                )
            else:
                out = run_binary(
                    [
                        binary,
                        "sign",
                        f"msg={tc.get('msg', '')}",
                        f"sk={sk}",
                        f"ctx={tc.get('ctx', '')}",
                    ]
                )

            if "_error" in out or "decode_error" in out:
                assert (
                    tc["result"] == "invalid"
                ), f"binary error on non-invalid tcId={tc['tcId']}"
            elif tc["result"] in ("valid", "acceptable"):
                assert (
                    out["sig"].upper() == tc["sig"].upper()
                ), f"signature mismatch tcId={tc['tcId']}"
            elif tc["result"] == "invalid":
                assert (
                    out.get("sig", "").upper() != tc["sig"].upper()
                ), f"invalid signature matched tcId={tc['tcId']}"

            info("done")
            count += 1
    info(f"  {count} sign tests passed")


def run_verify_tests(data_file):
    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    info(f"Running verify tests from {data_file}")
    count = 0

    # Extract algorithm from the root JSON object
    level = PARAMETER_SET_TO_LEVEL[data["algorithm"]]
    binary = get_binary(level)

    for tg in data["testGroups"]:
        pk = tg.get("publicKey", "")

        for tc in tg["tests"]:
            info(f"Running sigVer test case {tc['tcId']} ... ", end="", flush=True)
            is_internal = "Internal" in tc.get("flags", [])

            if is_internal:
                out = run_binary(
                    [
                        binary,
                        "verify_internal",
                        f"mu={tc.get('mu', '')}",
                        f"sig={tc.get('sig', '')}",
                        f"pk={pk}",
                    ]
                )
            else:
                out = run_binary(
                    [
                        binary,
                        "verify",
                        f"msg={tc.get('msg', '')}",
                        f"ctx={tc.get('ctx', '')}",
                        f"sig={tc.get('sig', '')}",
                        f"pk={pk}",
                    ]
                )

            if "_error" in out or "decode_error" in out:
                assert (
                    tc["result"] == "invalid"
                ), f"binary error on non-invalid tcId={tc['tcId']}"
            elif tc["result"] in ("valid", "acceptable"):
                assert out.get("testPassed") == "1", f"verify failed tcId={tc['tcId']}"
            elif tc["result"] == "invalid":
                assert (
                    out.get("testPassed") == "0"
                ), f"verify passed but expected invalid tcId={tc['tcId']}"

            info("done")
            count += 1
    info(f"  {count} verify tests passed")


def run_all(data_dir):
    data_dir = Path(data_dir)
    for filename in WYCHEPROOF_FILES:
        filepath = data_dir / filename
        if "sign_seed_test" in filename:
            run_sign_tests(filepath, has_seed=True)
        elif "sign_noseed_test" in filename:
            run_sign_tests(filepath, has_seed=False)
        elif "verify_test" in filename:
            run_verify_tests(filepath)
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
    help="Directory for downloaded test vectors",
)
args = parser.parse_args()

if args.file:
    filename = os.path.basename(args.file)
    if "sign_seed_test" in filename:
        run_sign_tests(args.file, has_seed=True)
    elif "sign_noseed_test" in filename:
        run_sign_tests(args.file, has_seed=False)
    elif "verify_test" in filename:
        run_verify_tests(args.file)
    else:
        err(f"Unknown test file type: {filename}")
        sys.exit(1)
    info("ALL GOOD!")
else:
    if not download_wycheproof_files(args.data_dir):
        err("Failed to download Wycheproof test files")
        sys.exit(1)
    run_all(args.data_dir)
