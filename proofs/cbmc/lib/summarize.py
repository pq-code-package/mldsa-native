# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import argparse
import json
import logging
import os
import sys


DESCRIPTION = """Print 2 tables in GitHub-flavored Markdown that summarize
an execution of CBMC proofs."""


def get_args():
    """Parse arguments for summarize script."""
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    for arg in [
        {
            "flags": ["--run-file"],
            "help": "path to the Litani run.json file",
            "required": True,
        },
        {
            "flags": ["--output-result-json"],
            "help": "path to export result JSON",
            "required": False,
        },
    ]:
        flags = arg.pop("flags")
        parser.add_argument(*flags, **arg)
    return parser.parse_args()


def _get_max_length_per_column_list(data):
    ret = [len(item) + 1 for item in data[0]]
    for row in data[1:]:
        for idx, item in enumerate(row):
            ret[idx] = max(ret[idx], len(item) + 1)
    return ret


def _get_table_header_separator(max_length_per_column_list):
    line_sep = ""
    for max_length_of_word_in_col in max_length_per_column_list:
        line_sep += "|" + "-" * (max_length_of_word_in_col + 1)
    line_sep += "|\n"
    return line_sep


def _get_entries(max_length_per_column_list, row_data):
    entries = []
    for row in row_data:
        entry = ""
        for idx, word in enumerate(row):
            max_length_of_word_in_col = max_length_per_column_list[idx]
            space_formatted_word = (max_length_of_word_in_col - len(word)) * " "
            entry += "| " + word + space_formatted_word
        entry += "|\n"
        entries.append(entry)
    return entries


def _get_rendered_table(data):
    table = []
    max_length_per_column_list = _get_max_length_per_column_list(data)
    entries = _get_entries(max_length_per_column_list, data)
    for idx, entry in enumerate(entries):
        if idx == 1:
            line_sep = _get_table_header_separator(max_length_per_column_list)
            table.append(line_sep)
        table.append(entry)
    table.append("\n")
    return "".join(table)


def _split_pipeline_name(pipeline_name):
    """Split a litani pipeline name of the form `<PROOF_UID>__<SOLVER>` back
    into (proof_uid, solver). Returns (None, None) for names that don't carry
    a solver suffix (e.g. the `print_tool_versions` pipeline)."""
    if "__" not in pipeline_name:
        return None, None
    proof_uid, _, solver = pipeline_name.rpartition("__")
    return proof_uid, solver


# Marker emitted by cbmc when the SMT backend returned `unknown` on the
# verification query. cbmc still exits non-zero (cprover-status: ERROR)
# in this case, so the pipeline shows up as `fail` in litani; but no
# property was actually refuted -- the solver simply could not decide.
# We surface this as a distinct "Inconclusive" outcome.
_SOLVER_UNKNOWN_MARKER = 'SMT2 solver returned "unknown"'


def _is_solver_inconclusive(stdout_file):
    """Return True iff the cbmc safety-check job's stdout-file (result.xml)
    contains the cbmc message indicating the SMT backend returned `unknown`.
    """
    if not stdout_file:
        return False
    try:
        with open(stdout_file, encoding="utf-8", errors="replace") as f:
            return _SOLVER_UNKNOWN_MARKER in f.read()
    except OSError:
        return False


def _parse_proof_pipeline(proof_pipeline):
    """Parse a single proof pipeline, returning
    (name, solver, status, duration, has_timeout)."""
    duration = 0
    has_timeout = False
    inconclusive = False
    for stage in proof_pipeline["ci_stages"]:
        for job in stage["jobs"]:
            if job.get("timeout_reached", False):
                has_timeout = True
            if "duration" in job:
                duration += int(job["duration"])
            # Identify the safety-check job by its description suffix.
            # Litani stores both description and stdout_file under
            # wrapper_arguments (the args passed to `litani add-job`).
            wa = job.get("wrapper_arguments") or {}
            desc = wa.get("description") or ""
            if desc.endswith(": checking safety properties") and _is_solver_inconclusive(
                wa.get("stdout_file")
            ):
                inconclusive = True

    if has_timeout:
        status = "Timeout"
    elif inconclusive:
        status = "Inconclusive"
    else:
        status = proof_pipeline["status"].title()
    name, solver = _split_pipeline_name(proof_pipeline["name"])
    return name, solver, status, duration, has_timeout


def _get_status_and_proof_summaries(run_dict, omitted_pairs=None):
    """Parse a dict representing a Litani run and create lists summarizing the
    proof results.

    Parameters
    ----------
    run_dict
        A dictionary representing a Litani run.
    omitted_pairs
        Optional iterable of (proof_uid, solver) tuples corresponding to
        (harness, solver) pairs that were intentionally not run because the
        harness disables that solver. They render as blank rows so they
        remain visible.


    Returns
    -------
    A list of 2 lists.
    The first sub-list maps a status to the number of proofs with that status.
    The second sub-list maps each (proof, solver) to its status.
    """
    count_statuses = {}
    proofs = [["Proof", "Solver", "Status", "Duration (in s)"]]
    for proof_pipeline in run_dict["pipelines"]:
        if proof_pipeline["name"] == "print_tool_versions":
            continue

        name, solver, status, duration, has_timeout = _parse_proof_pipeline(
            proof_pipeline
        )
        if name is None:
            # Pipelines that don't follow the <PROOF_UID>__<SOLVER> convention
            # (e.g. legacy or other-purpose entries) are surfaced as-is.
            name, solver = proof_pipeline["name"], "-"
        status_pretty = status.replace("_", " ")
        duration_str = "TIMEOUT" if has_timeout else str(duration)

        count_statuses[status_pretty] = count_statuses.get(status_pretty, 0) + 1
        proofs.append([name, solver, status_pretty, duration_str])

    if omitted_pairs:
        for proof_uid, solver in omitted_pairs:
            count_statuses["Omitted"] = count_statuses.get("Omitted", 0) + 1
            proofs.append([proof_uid, solver, "-", ""])

    # Sort body rows by (proof, solver) so paired rows are adjacent.
    body = proofs[1:]
    body.sort(key=lambda r: (r[0], r[1]))
    proofs = [proofs[0]] + body

    statuses = [["Status", "Count"]]
    for status, count in count_statuses.items():
        statuses.append([status, str(count)])
    return [statuses, proofs]


def export_result_json(output_path, run_file, omitted_pairs=None):
    """Export JSON with summary, failures, and runtimes."""
    if output_path is None:
        return

    with open(run_file, encoding="utf-8") as f:
        run_dict = json.load(f)

    _, proof_table = _get_status_and_proof_summaries(run_dict, omitted_pairs)
    # proof_table rows are [name, solver, status, duration_str].

    failures, runtimes = [], []
    for name, solver, status, duration_str in proof_table[1:]:  # skip header
        is_success = status == "Success"
        is_omitted = status == "-"
        is_inconclusive = status == "Inconclusive"

        if is_omitted:
            runtimes.append({"name": name, "solver": solver, "status": "omitted"})
            continue

        if is_inconclusive:
            runtimes.append(
                {
                    "name": name,
                    "solver": solver,
                    "status": "inconclusive",
                    "duration": duration_str,
                }
            )
            continue

        if not is_success:
            failures.append(
                {
                    "name": name,
                    "solver": solver,
                    "status": status,
                    "duration": duration_str,
                }
            )

        runtime = {"name": name, "solver": solver, "unit": "seconds"}
        if is_success:
            runtime["value"] = int(duration_str)
        else:
            runtime["status"] = "failed"
        runtimes.append(runtime)

    total = len(runtimes)
    failed = sum(1 for f in failures if f["status"] != "Timeout")
    timeout = sum(1 for f in failures if f["status"] == "Timeout")
    omitted = sum(1 for r in runtimes if r.get("status") == "omitted")
    inconclusive = sum(1 for r in runtimes if r.get("status") == "inconclusive")

    result = {
        "mldsa_parameter_set": os.getenv("MLD_CONFIG_PARAMETER_SET", "unknown"),
        "summary": {
            "total": total,
            "success": total - failed - timeout - omitted - inconclusive,
            "failed": failed,
            "timeout": timeout,
            "omitted": omitted,
            "inconclusive": inconclusive,
        },
        "failures": failures,
        "runtimes": runtimes,
    }

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)


def print_proof_results(out_file, omitted_pairs=None):
    """
    Print 2 strings that summarize the proof results.
    When printing, each string will render as a GitHub flavored Markdown table.
    """
    output = "## Summary of CBMC proof results\n\n"
    with open(out_file, encoding="utf-8") as run_json:
        run_dict = json.load(run_json)
    status_table, proof_table = _get_status_and_proof_summaries(run_dict, omitted_pairs)
    for summary in (status_table, proof_table):
        output += _get_rendered_table(summary)

    print(output)
    sys.stdout.flush()

    github_summary_file = os.getenv("GITHUB_STEP_SUMMARY")
    if github_summary_file:
        with open(github_summary_file, "a") as handle:
            print(output, file=handle)
            handle.flush()
    else:
        logging.warning("$GITHUB_STEP_SUMMARY not set, not writing summary file")

    msg = (
        "Click the 'Summary' button to view a Markdown table "
        "summarizing all proof results"
    )

    # Check for timeouts and real failures. "Inconclusive" rows count as
    # neither: the solver could not decide, but no property was refuted.
    proof_statuses = [row[2] for row in proof_table[1:]]  # status column
    has_timeout = any(s == "Timeout" for s in proof_statuses)
    has_real_failure = any(s == "Fail" for s in proof_statuses)
    has_inconclusive = any(s == "Inconclusive" for s in proof_statuses)

    if has_timeout or has_real_failure:
        logging.error("Not all proofs passed.")
        if has_timeout:
            logging.error("Some proofs timed out.")
        logging.error(msg)
        sys.exit(1)
    if has_inconclusive:
        logging.warning(
            "Some (proof, solver) pairs were inconclusive (solver returned 'unknown')."
        )
    logging.info(msg)


if __name__ == "__main__":
    args = get_args()
    logging.basicConfig(format="%(levelname)s: %(message)s")
    try:
        export_result_json(args.output_result_json, args.run_file)
        print_proof_results(args.run_file)
    except Exception as ex:  # pylint: disable=broad-except
        logging.critical("Could not print results. Exception: %s", str(ex))
