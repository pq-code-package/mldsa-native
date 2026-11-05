#!/usr/bin/env python3
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT

"""
Run one test image (UF2, see link.py) on a Dabao board over USB.

The board must be in the boot1 console with bootwait enabled, which is how
it ships and where every run leaves it. The wrapper writes the image through
boot1's `uf2` command, boots it, starts the test with the image's `mldsa`
command, forwards the test output to stdout, and exits with the test's return
code from the `DABAO_EXIT <rc>` line. The image then resets back into boot1.

Environment:
  DABAO_SERIAL   USB serial number of the board to use, if several are attached
  DABAO_TIMEOUT  seconds to wait for the test to finish (default: 900)
"""

import base64
import glob
import os
import re
import select
import sys
import termios
import time
import tty

UF2_BLOCK_SIZE = 512
UF2_RETRIES = 5
# Longer than it takes the image's watchdog to reset a hung test
BOOT1_WAIT = 240
# /dev/serial/by-id names of the two firmware stages
BOOT1_PORT = "usb-Baochip_Baochip-1x_{}-if00"
IMAGE_PORT = "usb-Baochip_Dabao-Baremetal_{}-if00"
EXIT_RE = re.compile(rb"DABAO_EXIT (-?\d+)")
ECHO_RE = re.compile(rb"mldsa[^\n]*\n")


def fail(msg):
    sys.stderr.write(f"exec_wrapper: {msg}\n")
    sys.exit(1)


def port_paths(name):
    serial = os.environ.get("DABAO_SERIAL", "*")
    return glob.glob("/dev/serial/by-id/" + name.format(serial))


def find_port(name, timeout):
    """Open the serial device of the firmware stage `name` once it appears."""
    deadline = time.time() + timeout
    denied = None
    while time.time() < deadline:
        ports = port_paths(name)
        if len(ports) > 1:
            fail(f"several boards found, set DABAO_SERIAL: {ports}")
        if ports:
            try:
                return Port(ports[0])
            except PermissionError:
                # udev applies permissions shortly after the node appears
                denied = ports[0]
            except OSError:
                pass
        time.sleep(0.2)
    if denied:
        fail(f"no access to {denied}; see README.md for the udev rule")
    fail(f"no Dabao board found as {name.format('*')}")


def enter_boot1():
    """
    Return the boot1 console. A previous run that was interrupted may have
    left an image running: ask it to reset, or wait for it to finish or for
    its watchdog to reset it.
    """
    if not port_paths(BOOT1_PORT):
        for path in port_paths(IMAGE_PORT):
            try:
                port = Port(path)
                port.write(b"\rreset\r")
                port.close()
            except OSError:
                pass
    return find_port(BOOT1_PORT, BOOT1_WAIT)


class Port:
    def __init__(self, path):
        self.fd = os.open(path, os.O_RDWR | os.O_NOCTTY)
        tty.setraw(self.fd)
        attrs = termios.tcgetattr(self.fd)
        attrs[2] |= termios.CLOCAL
        termios.tcsetattr(self.fd, termios.TCSANOW, attrs)
        termios.tcflush(self.fd, termios.TCIOFLUSH)

    def close(self):
        try:
            os.close(self.fd)
        except OSError:
            pass

    def write(self, data):
        while data:
            n = os.write(self.fd, data)
            data = data[n:]

    def read(self, timeout):
        """Return the bytes available within `timeout`; b"" on timeout."""
        r, _, _ = select.select([self.fd], [], [], timeout)
        if not r:
            return b""
        try:
            data = os.read(self.fd, 4096)
        except OSError:
            raise EOFError
        if not data:
            raise EOFError
        return data

    def drain(self, quiet=0.2):
        """Discard input until the line has been quiet for `quiet` seconds."""
        while self.read(quiet):
            pass

    def expect(self, pattern, timeout):
        """Read until `pattern` (bytes regex) matches; return all data read."""
        buf = b""
        deadline = time.time() + timeout
        while time.time() < deadline:
            buf += self.read(min(0.1, max(0.0, deadline - time.time())))
            if re.search(pattern, buf):
                return buf
        raise TimeoutError(buf)

    def command(self, cmd, pattern, timeout=3.0):
        self.write(cmd.encode() + b"\r")
        return self.expect(pattern, timeout)


def flash(port, image):
    if len(image) % UF2_BLOCK_SIZE != 0:
        fail("image is not a UF2 file")
    for off in range(0, len(image), UF2_BLOCK_SIZE):
        b64 = base64.b64encode(image[off : off + UF2_BLOCK_SIZE]).decode()
        # boot1 occasionally loses part of a command line; writing a block
        # again is harmless, so retry until it is acknowledged.
        for _ in range(UF2_RETRIES):
            try:
                resp = port.command(
                    f"uf2 {b64}", rb"Wrote|Invalid|rror|Commands include"
                )
            except TimeoutError as e:
                resp = e.args[0]
            if b"Wrote" in resp:
                break
            sys.stderr.write(f"exec_wrapper: retrying uf2 block at offset {off}\n")
            port.drain()
        else:
            fail(f"uf2 block at offset {off} not accepted: {resp!r}")


def start_test(port, timeout):
    """Run the image's `mldsa` command; return the output after its echo."""
    # The image drops input until its USB console is up, shortly after it
    # enumerates; its banner does not reach the host.
    time.sleep(10)
    port.write(b"mldsa\r")
    # The echo is only sent along with the test's first line of output.
    try:
        buf = port.expect(ECHO_RE, timeout)
    except TimeoutError:
        fail("the image does not respond to the mldsa command")
    return buf[ECHO_RE.search(buf).end() :]


def main():
    if len(sys.argv) < 2:
        fail("usage: exec_wrapper.py <image.uf2> [args...]")
    with open(sys.argv[1], "rb") as f:
        image = f.read()
    timeout = float(os.environ.get("DABAO_TIMEOUT", "900"))

    port = enter_boot1()
    try:
        port.command("", rb"Commands include")
    except TimeoutError as e:
        fail(f"board is not in the boot1 console: {e.args[0]!r}")
    # keep the uf2 payloads from being echoed back
    port.command("localecho off", rb"\n")
    flash(port, image)
    # a reset must return to boot1 for the next run
    port.command("bootwait enable", rb"\n")
    try:
        port.command("bootwait check", rb"bootwait is Enable")
    except TimeoutError as e:
        fail(f"could not enable bootwait: {e.args[0]!r}")
    port.write(b"boot\r")
    port.close()

    # boot1 drops off USB and the image enumerates in its place.
    port = find_port(IMAGE_PORT, 20)
    buf = start_test(port, timeout)

    out = sys.stdout.buffer
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            buf += port.read(0.5)
        except EOFError:
            fail("board disconnected before the test finished")
        m = EXIT_RE.search(buf)
        if m:
            out.write(buf[: m.start()].replace(b"\r\n", b"\n"))
            out.flush()
            port.close()
            sys.exit(int(m.group(1)) & 0xFF)
        # forward complete lines, keep a possible partial DABAO_EXIT marker
        k = buf.rfind(b"\n")
        if k >= 0:
            out.write(buf[: k + 1].replace(b"\r\n", b"\n"))
            out.flush()
            buf = buf[k + 1 :]
    fail(f"timed out after {timeout:.0f}s")


if __name__ == "__main__":
    main()
