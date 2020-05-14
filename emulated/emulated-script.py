#!/usr/bin/env python3

import os, time

import requests
from pathlib import Path
from shell import shell


ci_run_dir = Path.home() / "ci_run"
os.makedirs(ci_run_dir, exist_ok=True)

ci_steps_dir = ci_run_dir / "steps"
os.makedirs(ci_steps_dir, exist_ok=True)

TERMUX_FDROID_URL = "https://f-droid.org/repo/com.termux_92.apk"


TERMUX_APK = ci_run_dir / "termux_92.apk"

# Currently we sleep for an arbitary amount of time
# Until we find an exact intent? to listen to

app_sleep_steps = [15, 10]


def main():
    print(f" Downloading.....  {TERMUX_FDROID_URL}")

    r = requests.get(TERMUX_FDROID_URL)
    with open(TERMUX_APK, "wb") as f:
        f.write(r.content)
    adb = AdbRunner(app_sleep_steps)
    adb.get_emulator_info()

    print(" Installing....")
    adb.install(TERMUX_APK)
    adb.start_app("com.termux")

    adb.screencap_step()
    adb.sleep()

    adb.input_text("pkg install tsu")
    adb.input_key(23)
    adb.screencap_step()
    adb.sleep()
    adb.input_text("tsu --dbg")
    adb.input_key(23)


"""
We already have an adb connected device from the runner action
"""


class AdbRunner:
    def __init__(self, wait):
        self.scount = 1
        self.step_wait = wait

    def sleep(self):
        print(self.step_wait)
        s = self.step_wait[self.scount - 2]
        time.sleep(s)

    def run_cmd(self, cmd):
        print(">>>", cmd)
        c = shell(cmd)
        print(c.output())
        print("\n")

    def shell(self, args):
        shell(f"adb shell {args}")

    def screencap_step(self):
        self.run_cmd(f"adbe screenshot  {ci_steps_dir}/step_{self.scount}.png")
        self.scount += 1

    def get_emulator_info(self):
        self.run_cmd("adbe devices")

    def install(self, apk):
        self.run_cmd(f"adb install {apk}")

    def start_app(self, app_name):
        self.run_cmd(f"adbe start {app_name}")

    def input_text(self, str):
        self.run_cmd(f"adbe input-text '{str}' ")

    def input_key(self, keycode):
        self.run_cmd(f"adb shell input keyevent 23")


main()
