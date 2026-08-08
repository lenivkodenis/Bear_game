#!/usr/bin/env python3
"""Validate future bear cub sprite animation frames without modifying images."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANIMATION_ROOT = ROOT / "assets/images/characters/bear_cub/animations"
STATE_REQUIREMENTS = {
    "idle": 2,
    "walk": 6,
    "jump": 1,
    "sit": 1,
}
SNAKE_CASE_PNG = re.compile(r"^[a-z0-9]+(?:_[a-z0-9]+)*\.png$")


@dataclass(frozen=True)
class FrameInfo:
    path: Path
    size: tuple[int, int]
    mode: str
    has_alpha_channel: bool
    has_transparent_pixels: bool


def main() -> int:
    try:
        from PIL import Image
    except ImportError:
        print("Pillow is not available in the current Python environment.")
        print("Install tool dependencies with:")
        print(".venv-tools/bin/python -m pip install -r tools/requirements.txt")
        return 2

    errors: list[str] = []
    warnings: list[str] = []
    frames_by_state: dict[str, list[FrameInfo]] = {}

    print("Bear cub animation frame check")
    print(f"root: {relative(ANIMATION_ROOT)}")
    print()

    for state, minimum_count in STATE_REQUIREMENTS.items():
        state_dir = ANIMATION_ROOT / state
        if not state_dir.is_dir():
            errors.append(f"Missing folder: {relative(state_dir)}")
            frames_by_state[state] = []
            continue

        png_paths = sorted(state_dir.glob("*.png"))
        frames: list[FrameInfo] = []
        for path in png_paths:
            validate_filename(path, errors)
            info = inspect_png(path, Image, errors)
            if info is not None:
                frames.append(info)

        frames_by_state[state] = frames
        if len(frames) < minimum_count:
            warnings.append(
                f"{state}: {len(frames)} PNG frame(s), minimum for readiness is {minimum_count}."
            )

    for state, frames in frames_by_state.items():
        validate_state_sizes(state, frames, errors)

    walk_frames = frames_by_state.get("walk", [])
    validate_walk_sizes(walk_frames, errors)

    print_report(frames_by_state, warnings, errors)
    return 1 if errors else 0


def validate_filename(path: Path, errors: list[str]) -> None:
    if not SNAKE_CASE_PNG.fullmatch(path.name):
        errors.append(
            f"Invalid filename: {relative(path)}. Use lowercase snake_case PNG names only."
        )


def inspect_png(path: Path, image_module, errors: list[str]) -> FrameInfo | None:
    try:
        with image_module.open(path) as image:
            image.load()
            has_alpha_channel = image.mode in {"LA", "RGBA"} or (
                image.mode == "P" and "transparency" in image.info
            )
            has_transparent_pixels = False
            if has_alpha_channel:
                alpha = image.convert("RGBA").getchannel("A")
                has_transparent_pixels = alpha.getextrema()[0] < 255

            if not has_alpha_channel:
                errors.append(f"No alpha channel: {relative(path)}")
            elif not has_transparent_pixels:
                errors.append(f"No transparent pixels: {relative(path)}")

            return FrameInfo(
                path=path,
                size=image.size,
                mode=image.mode,
                has_alpha_channel=has_alpha_channel,
                has_transparent_pixels=has_transparent_pixels,
            )
    except Exception as exc:
        errors.append(f"Cannot read PNG: {relative(path)} ({exc})")
        return None


def validate_state_sizes(
    state: str,
    frames: list[FrameInfo],
    errors: list[str],
) -> None:
    if len(frames) < 2:
        return

    expected_size = frames[0].size
    for frame in frames[1:]:
        if frame.size != expected_size:
            errors.append(
                f"{state}: frame size mismatch. "
                f"{relative(frame.path)} is {format_size(frame.size)}, "
                f"expected {format_size(expected_size)}."
            )


def validate_walk_sizes(frames: list[FrameInfo], errors: list[str]) -> None:
    if len(frames) < 2:
        return

    walk_sizes = {frame.size for frame in frames}
    if len(walk_sizes) > 1:
        formatted_sizes = ", ".join(sorted(format_size(size) for size in walk_sizes))
        errors.append(f"walk: all frames must have one canvas size. Found: {formatted_sizes}.")


def print_report(
    frames_by_state: dict[str, list[FrameInfo]],
    warnings: list[str],
    errors: list[str],
) -> None:
    for state in STATE_REQUIREMENTS:
        frames = frames_by_state.get(state, [])
        print(f"{state}: {len(frames)} PNG frame(s)")
        if not frames:
            print("  no frames yet")
            continue

        for frame in frames:
            alpha_status = (
                "alpha+transparent"
                if frame.has_alpha_channel and frame.has_transparent_pixels
                else "alpha problem"
            )
            print(
                f"  {frame.path.name}: {format_size(frame.size)}, "
                f"mode={frame.mode}, {alpha_status}"
            )
        print()

    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
        print()

    if errors:
        print("Errors:")
        for error in errors:
            print(f"  - {error}")
        print()
        print("Result: FAILED")
        return

    print("Result: OK")
    if any(not frames for frames in frames_by_state.values()):
        print("Note: folders are ready, but real animation frames are not ready yet.")


def relative(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def format_size(size: tuple[int, int]) -> str:
    return f"{size[0]}x{size[1]}"


if __name__ == "__main__":
    raise SystemExit(main())
