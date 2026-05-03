#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

WVKBD_PID="$1"
[ -n "${WVKBD_PID}" ] || exit 1
command -v python3 >/dev/null 2>&1 || exit 0

python3 - "${WVKBD_PID}" << 'PY'
import fcntl
import glob
import os
import select
import signal
import struct
import sys
import time

EVIOCGBIT = 0x80000000 | (64 << 16) | (ord("E") << 8) | 0x20
EVIOCGBIT_KEY = 0x80000000 | (128 << 16) | (ord("E") << 8) | 0x21
EV_FMT = "llHHI"
EV_SIZE = struct.calcsize(EV_FMT)
EV_KEY = 0x01
BTN_THUMBR = 318
DEBOUNCE_SEC = 0.15


def has_bit(buf, bit):
    idx = bit // 8
    return idx < len(buf) and (buf[idx] & (1 << (bit % 8))) != 0


def find_event_device():
    for dev in sorted(glob.glob("/dev/input/event*")):
        try:
            fd = os.open(dev, os.O_RDONLY | os.O_NONBLOCK)
        except OSError:
            continue
        try:
            ev_bits = bytearray(64)
            fcntl.ioctl(fd, EVIOCGBIT, ev_bits, True)
            if not has_bit(ev_bits, EV_KEY):
                continue
            key_bits = bytearray(128)
            fcntl.ioctl(fd, EVIOCGBIT_KEY, key_bits, True)
            if has_bit(key_bits, BTN_THUMBR):
                return dev
        except OSError:
            pass
        finally:
            os.close(fd)
    return ""


def main():
    try:
        wvkbd_pid = int(sys.argv[1])
    except (IndexError, ValueError):
        return 1

    dev_path = find_event_device()
    if not dev_path or not os.access(dev_path, os.R_OK):
        return 0

    last = 0.0
    r3_down = False
    visible = False

    try:
        fd = os.open(dev_path, os.O_RDONLY | os.O_NONBLOCK)
    except OSError:
        return 0

    try:
        while True:
            if not os.path.exists(f"/proc/{wvkbd_pid}"):
                return 0
            ready, _, _ = select.select([fd], [], [], 1.0)
            if not ready:
                continue
            while True:
                try:
                    data = os.read(fd, EV_SIZE)
                except BlockingIOError:
                    break
                if len(data) != EV_SIZE:
                    break
                _, _, event_type, code, value = struct.unpack(EV_FMT, data)
                if event_type != EV_KEY:
                    continue
                if code != BTN_THUMBR:
                    continue
                if value == 0:
                    r3_down = False
                    continue
                if value != 1 or r3_down:
                    continue
                r3_down = True
                if code == BTN_THUMBR and value == 1:
                    now = time.monotonic()
                    if now - last < DEBOUNCE_SEC:
                        continue
                    try:
                        if visible:
                            os.kill(wvkbd_pid, signal.SIGUSR1)
                            visible = False
                        else:
                            os.kill(wvkbd_pid, signal.SIGRTMIN)
                            time.sleep(0.03)
                            os.kill(wvkbd_pid, signal.SIGUSR2)
                            visible = True
                    except ProcessLookupError:
                        return 0
                    last = now
    finally:
        os.close(fd)


if __name__ == "__main__":
    raise SystemExit(main())
PY
