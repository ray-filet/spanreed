#!/usr/bin/env python3
"""Check a built app launches independently of Xcode and its build directory."""

import argparse
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import time
import uuid


def check_launch(app):
    with tempfile.TemporaryDirectory(prefix="spanreed-launch-") as temporary:
        root = Path(temporary)
        copied_app = root / app.name
        shutil.copytree(app, copied_app, symlinks=True)
        with (copied_app / "Contents/Info.plist").open("rb") as info_file:
            executable_name = plistlib.load(info_file)["CFBundleExecutable"]
        executable = copied_app / "Contents/MacOS" / executable_name
        home_folder = root / "home"
        suite = "com.rayfilet.Spanreed.LaunchCheck." + str(uuid.uuid4())
        environment = {
            key: value for key, value in os.environ.items()
            if not key.startswith("DYLD_")
        }
        environment["SPANREED_DEFAULTS_SUITE"] = suite

        with (root / "stderr.log").open("w+") as errors:
            process = subprocess.Popen(
                [str(executable), "--home-note-folder", str(home_folder),
                 "--config-folder", str(root / "config")],
                env=environment, stdout=subprocess.DEVNULL, stderr=errors,
            )
            try:
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    if process.poll() is not None:
                        errors.seek(0)
                        raise RuntimeError(
                            f"App exited during launch ({process.returncode}):\n"
                            + errors.read()
                        )
                    if (home_folder / "Home.txt").is_file():
                        break
                    time.sleep(0.05)
                else:
                    raise RuntimeError("App did not create the isolated Home Note")

                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    print("PASS: relocated app launches and creates its Home Note")
                else:
                    errors.seek(0)
                    raise RuntimeError("App exited after creating its Home Note:\n"
                                       + errors.read())
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                subprocess.run(["defaults", "delete", suite],
                               stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, check=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path, help="Path to a built Spanreed.app")
    arguments = parser.parse_args()
    try:
        check_launch(arguments.app.resolve())
    except (OSError, RuntimeError) as error:
        parser.exit(1, f"FAIL: {error}\n")
