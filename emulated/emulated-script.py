#!/usr/bin/env python3

import os, time

import requests
from pathlib import Path
from shell import shell

from tempfile import gettempdir


# Check if we are running locally or in Github CI

temp = Path.home()  if  'GITHUB_ACTIONS' in os.environ else Path(gettempdir())  
ci_run_dir =   temp / "ci_run" 
 
os.makedirs(ci_run_dir, exist_ok=True)

ci_steps_dir = ci_run_dir / "steps"
os.makedirs(ci_steps_dir, exist_ok=True)

TERMUX_FDROID_URL = "https://f-droid.org/repo/com.termux_92.apk"
TERMUX_APK = ci_run_dir / "termux_92.apk"

# Currently we sleep for an arbitary amount of time
# Until we find an exact intent? to listen to


def step_install_termux(adb, steps_sleep ):
    print(f" Downloading.....  {TERMUX_FDROID_URL}")
    r = requests.get(TERMUX_FDROID_URL)
    with open(TERMUX_APK, "wb") as f:
        f.write(r.content)
 
    adb.screencap_step(steps_sleep['before_termux_install']  )
    print(" Installing....")

    adb.install(TERMUX_APK)
    adb.screencap_step(steps_sleep['after_termux_install'] )

def step_install_tsu(adb, step_sleep):
 
    adb.start_app("com.termux")
    adb.screencap_step(5)

    adb.input_text("pkg install tsu")
    adb.input_key(23)
    adb.screencap_step(2)
 
    adb.input_text("tsu --dbg")
    adb.input_key(23)
    adb.screencap_step(3)

def step_emulator_info(adb):
    adb.get_emulator_info()
    adb.screencap_step()

def main():
    adb = AdbRunner()
    step_install_termux(adb, {
     'before_termux_install' :  10,
     'after_termux_install' : 5
    })
    step_install_tsu(adb, {} )



"""
We already have an adb connected device from the runner action
"""
class AdbRunner:
    def __init__(self):
        self.scount = 1
 
    def run_cmd(self, cmd):
        print(">>>", cmd)
        c = shell(cmd)
        print(c.output())
        print("\n")

    def shell(self, args):
        shell(f"adb shell {args}")

    def screencap_step(self, steps_sleep):
        time.sleep(steps_sleep)
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
