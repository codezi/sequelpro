#!/usr/bin/env python3
"""Install rebuilt bundles, normalize public headers, and ad-hoc sign them."""
import pathlib
import shutil
import subprocess
import sys

cache, output = map(pathlib.Path, sys.argv[1:])
for name in ("FeedbackReporter", "ShortcutRecorder", "UniversalDetector", "Growl", "OCMock", "Sparkle"):
    source = cache / ("sparkle" if name == "Sparkle" else "products") / (name + ".framework")
    destination = output / source.name
    if not (source / name).is_file():
        raise SystemExit(f"Missing built binary: {source / name}")
    subprocess.run(["xcrun", "lipo", "-verify_arch", "arm64", str(source / name)], check=True)
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source, destination, symlinks=True)
    if name == "Sparkle":
        # Preserve the official release and its Developer ID signature verbatim.
        continue
    for header in (destination / "Versions").rglob("*.h"):
        text = header.read_text()
        header.write_text("\n".join(line.rstrip() for line in text.splitlines()).rstrip() + "\n")
    subprocess.run(["codesign", "--force", "--sign", "-", str(destination)], check=True)
