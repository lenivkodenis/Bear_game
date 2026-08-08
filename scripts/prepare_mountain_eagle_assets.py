#!/usr/bin/env python3
"""Prepare transparent, normalized mountain eagle animation frames.

The source files have a baked checkerboard background and no alpha channel.
This script removes only light neutral background pixels connected to the image
border, preserving similar light pixels inside the eagle artwork.
"""

from __future__ import annotations

from collections import Counter, deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = (
    ROOT
    / "assets/images/characters/mountain_eagle/animations/fly_land-takeoff"
)
TARGET_DIR = (
    ROOT
    / "assets/images/characters/mountain_eagle/animations/fly_land_takeoff"
)
EXPECTED_SIZE = (1254, 1254)


@dataclass(frozen=True)
class FrameMap:
    source: str
    role: str
    target: str


FRAME_MAP = (
    FrameMap("mountain_eagle_06_settle.png", "glide", "mountain_eagle_01_glide.png"),
    FrameMap(
        "mountain_eagle_07_stand.png",
        "approach",
        "mountain_eagle_02_approach.png",
    ),
    FrameMap(
        "mountain_eagle_05_touchdown.png",
        "descent",
        "mountain_eagle_03_descent.png",
    ),
    FrameMap("mountain_eagle_04_brake.png", "brake", "mountain_eagle_04_brake.png"),
    FrameMap(
        "mountain_eagle_10_takeoff_upstroke.png",
        "touchdown",
        "mountain_eagle_05_touchdown.png",
    ),
    FrameMap(
        "mountain_eagle_02_approach.png",
        "settle",
        "mountain_eagle_06_settle.png",
    ),
    FrameMap("mountain_eagle_01_glide.png", "stand", "mountain_eagle_07_stand.png"),
    FrameMap(
        "mountain_eagle_09_takeoff_push.png",
        "takeoff_prepare",
        "mountain_eagle_08_takeoff_prepare.png",
    ),
    FrameMap(
        "mountain_eagle_03_descent.png",
        "takeoff_push",
        "mountain_eagle_09_takeoff_push.png",
    ),
    FrameMap(
        "mountain_eagle_11_depart_power.png",
        "takeoff_upstroke",
        "mountain_eagle_10_takeoff_upstroke.png",
    ),
    FrameMap(
        "mountain_eagle_08_takeoff_prepare.png",
        "depart",
        "mountain_eagle_11_depart.png",
    ),
)


def main() -> None:
    validate_sources()
    TARGET_DIR.mkdir(parents=True, exist_ok=True)

    reports = []
    for frame in FRAME_MAP:
        source_path = SOURCE_DIR / frame.source
        target_path = TARGET_DIR / frame.target
        report = prepare_frame(source_path, target_path)
        reports.append((frame, report))

    print(f"source_png_count: {len(list(SOURCE_DIR.glob('*.png')))}")
    print(f"normalized_png_count: {len(list(TARGET_DIR.glob('*.png')))}")
    for frame, report in reports:
        print(
            f"{frame.source} -> {frame.target} "
            f"role={frame.role} mode={report['mode']} size={report['size']} "
            f"transparent_ratio={report['transparent_ratio']:.3f}"
        )


def validate_sources() -> None:
    source_pngs = sorted(SOURCE_DIR.glob("*.png"))
    if len(source_pngs) != len(FRAME_MAP):
        raise RuntimeError(
            f"Expected {len(FRAME_MAP)} source PNGs in {SOURCE_DIR}, "
            f"found {len(source_pngs)}."
        )

    source_names = {path.name for path in source_pngs}
    mapped_names = {frame.source for frame in FRAME_MAP}
    missing = sorted(mapped_names - source_names)
    if missing:
        raise RuntimeError(f"Missing mapped source PNGs: {missing}")

    for path in source_pngs:
        with Image.open(path) as image:
            if image.size != EXPECTED_SIZE:
                raise RuntimeError(f"{path.name}: expected {EXPECTED_SIZE}, got {image.size}.")


def prepare_frame(source_path: Path, target_path: Path) -> dict[str, object]:
    source = Image.open(source_path).convert("RGBA")
    rgb = source.convert("RGB")
    background_colors = detect_background_colors(rgb)
    background_mask = flood_fill_background(rgb, background_colors)
    alpha = ImageChops.invert(background_mask)

    # Feather only the alpha transition; keep confirmed background fully clear.
    softened = alpha.filter(ImageFilter.GaussianBlur(radius=0.35))
    alpha_pixels = alpha.load()
    softened_pixels = softened.load()
    background_pixels = background_mask.load()
    for y in range(alpha.height):
        for x in range(alpha.width):
            if background_pixels[x, y] == 255:
                softened_pixels[x, y] = 0
            elif softened_pixels[x, y] < 245:
                softened_pixels[x, y] = max(softened_pixels[x, y], alpha_pixels[x, y])

    output = source.copy()
    output.putalpha(softened)
    output.save(target_path)

    with Image.open(target_path) as result:
        result_rgba = result.convert("RGBA")
        result_alpha = result_rgba.getchannel("A")
        transparent = result_alpha.histogram()[0]
        total = result.width * result.height
        return {
            "mode": result.mode,
            "size": f"{result.width}x{result.height}",
            "transparent_ratio": transparent / total,
        }


def detect_background_colors(rgb: Image.Image) -> list[tuple[int, int, int]]:
    width, height = rgb.size
    samples: list[tuple[int, int, int]] = []
    for x in range(width):
        samples.append(rgb.getpixel((x, 0)))
        samples.append(rgb.getpixel((x, height - 1)))
    for y in range(height):
        samples.append(rgb.getpixel((0, y)))
        samples.append(rgb.getpixel((width - 1, y)))

    neutral = [color for color in samples if is_light_neutral(color, minimum=235)]
    if not neutral:
        neutral = samples

    rounded = [
        tuple(min(255, int(round(channel / 2) * 2)) for channel in color)
        for color in neutral
    ]
    colors: list[tuple[int, int, int]] = []
    for color, _ in Counter(rounded).most_common(10):
        if not any(color_distance(color, existing) <= 4 for existing in colors):
            colors.append(color)
        if len(colors) == 5:
            break

    return colors


def flood_fill_background(
    rgb: Image.Image,
    background_colors: list[tuple[int, int, int]],
) -> Image.Image:
    width, height = rgb.size
    pixels = rgb.load()
    visited = bytearray(width * height)
    mask = Image.new("L", (width, height), 0)
    mask_pixels = mask.load()
    queue: deque[tuple[int, int]] = deque()

    def add_if_background(x: int, y: int) -> None:
        index = y * width + x
        if visited[index]:
            return
        visited[index] = 1
        if is_background_pixel(pixels[x, y], background_colors):
            queue.append((x, y))

    for x in range(width):
        add_if_background(x, 0)
        add_if_background(x, height - 1)
    for y in range(height):
        add_if_background(0, y)
        add_if_background(width - 1, y)

    while queue:
        x, y = queue.popleft()
        mask_pixels[x, y] = 255
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if nx < 0 or ny < 0 or nx >= width or ny >= height:
                continue
            add_if_background(nx, ny)

    return mask


def is_background_pixel(
    color: tuple[int, int, int],
    background_colors: list[tuple[int, int, int]],
) -> bool:
    if not is_light_neutral(color, minimum=236):
        return False

    if any(color_distance(color, background) <= 18 for background in background_colors):
        return True

    return min(color) >= 244 and color_chroma(color) <= 10


def is_light_neutral(color: tuple[int, int, int], *, minimum: int) -> bool:
    return min(color) >= minimum and color_chroma(color) <= 12


def color_chroma(color: tuple[int, int, int]) -> int:
    return max(color) - min(color)


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


if __name__ == "__main__":
    main()
