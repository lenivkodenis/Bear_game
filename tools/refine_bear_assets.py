#!/usr/bin/env python3
"""Refine selected bear cub PNGs with a conservative Pillow-based pipeline.

This script intentionally writes only v2 files. It never overwrites source PNGs
or previous *_clean.png processed files.
"""

from __future__ import annotations

from collections import Counter, deque
from dataclasses import dataclass
from pathlib import Path
from statistics import median

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/images/characters/bear_cub/source"
PROCESSED_DIR = ROOT / "assets/images/characters/bear_cub/processed"
PREVIEW_PATH = ROOT / "docs/bear_asset_refinement_preview.png"


@dataclass(frozen=True)
class Candidate:
    name: str
    source: Path
    previous_clean: Path
    output: Path


@dataclass
class RefinementReport:
    candidate: Candidate
    original_size: tuple[int, int]
    output_size: tuple[int, int]
    background_colors: list[tuple[int, int, int]]
    crop_bounds: tuple[int, int, int, int] | None
    method: str
    warnings: list[str]


CANDIDATES = [
    Candidate(
        name="front idle",
        source=SOURCE_DIR / "bear_cub_base_2.png",
        previous_clean=PROCESSED_DIR / "bear_cub_base_2_clean.png",
        output=PROCESSED_DIR / "bear_cub_base_2_clean_v2_conservative.png",
    ),
    Candidate(
        name="side-view gameplay",
        source=SOURCE_DIR / "bear_cub_base_5.png",
        previous_clean=PROCESSED_DIR / "bear_cub_base_5_clean.png",
        output=PROCESSED_DIR / "bear_cub_base_5_clean_v2_conservative.png",
    ),
]


def main() -> None:
    reports = [refine_candidate(candidate) for candidate in CANDIDATES]
    create_preview(reports)
    print_reports(reports)
    print(f"preview: {rel(PREVIEW_PATH)}")


def refine_candidate(candidate: Candidate) -> RefinementReport:
    for path in (candidate.source, candidate.previous_clean):
        if not path.exists():
            raise FileNotFoundError(path)
    if candidate.output.name.endswith("_clean.png"):
        raise ValueError("Refinement output must not overwrite the previous clean file.")

    source = Image.open(candidate.source).convert("RGBA")
    rgb = source.convert("RGB")
    background_colors = detect_background_colors(rgb)
    background_mask = flood_fill_background(rgb, background_colors, tolerance=4)
    alpha = ImageChops.invert(background_mask)
    keep_largest_alpha_component(alpha)

    # Keep the conservative mask crisp, but soften only the immediate alpha edge.
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=0.25))
    alpha = alpha.point(lambda value: 0 if value < 10 else (255 if value > 245 else value))
    ImageDraw.Draw(alpha).rectangle((0, 0, source.width - 1, source.height - 1), outline=0, width=6)
    remove_alpha_regions_touching_border(alpha)

    crop_bounds = alpha.getbbox()
    warnings = [
        "Conservative edge-connected background removal; inspect before game hookup."
    ]
    if crop_bounds is None:
        crop_bounds = (0, 0, source.width, source.height)
        warnings.append("No foreground detected; output kept original canvas.")

    padded_bounds = pad_bounds(crop_bounds, source.size, padding=12)
    output_rgba = source.copy()
    output_rgba.putalpha(alpha)
    output_rgba = output_rgba.crop(padded_bounds)

    alpha_after_crop = output_rgba.getchannel("A")
    alpha_bbox = alpha_after_crop.getbbox()
    if alpha_bbox == (0, 0, output_rgba.width, output_rgba.height):
        warnings.append("Foreground touches crop edge; manual padding check recommended.")

    candidate.output.parent.mkdir(parents=True, exist_ok=True)
    output_rgba.save(candidate.output)

    return RefinementReport(
        candidate=candidate,
        original_size=source.size,
        output_size=output_rgba.size,
        background_colors=background_colors,
        crop_bounds=padded_bounds,
        method="conservative edge-connected flood-fill from image borders + light alpha feather",
        warnings=warnings,
    )


def detect_background_colors(rgb: Image.Image) -> list[tuple[int, int, int]]:
    w, h = rgb.size
    samples = []
    for x in range(w):
        samples.append(rgb.getpixel((x, 0)))
        samples.append(rgb.getpixel((x, h - 1)))
    for y in range(h):
        samples.append(rgb.getpixel((0, y)))
        samples.append(rgb.getpixel((w - 1, y)))

    neutral_light = [
        color
        for color in samples
        if min(color) >= 235 and max(color) - min(color) <= 8
    ]
    if not neutral_light:
        neutral_light = samples

    rounded = [
        tuple(min(255, int(round(channel / 2) * 2)) for channel in color)
        for color in neutral_light
    ]
    frequent = [color for color, _ in Counter(rounded).most_common(8)]

    colors: list[tuple[int, int, int]] = []
    for color in frequent:
        if not any(color_distance(color, existing) <= 5 for existing in colors):
            colors.append(color)
        if len(colors) == 3:
            break

    return colors or [(252, 252, 252), (244, 244, 244)]


def flood_fill_background(
    rgb: Image.Image,
    background_colors: list[tuple[int, int, int]],
    tolerance: int,
) -> Image.Image:
    w, h = rgb.size
    pixels = rgb.load()
    visited = bytearray(w * h)
    mask = Image.new("L", (w, h), 0)
    mask_pixels = mask.load()
    queue: deque[tuple[int, int]] = deque()

    def try_add(x: int, y: int) -> None:
        idx = y * w + x
        if visited[idx]:
            return
        visited[idx] = 1
        if is_background_pixel(rgb, pixels, x, y, background_colors, tolerance):
            queue.append((x, y))

    for x in range(w):
        try_add(x, 0)
        try_add(x, h - 1)
    for y in range(h):
        try_add(0, y)
        try_add(w - 1, y)

    while queue:
        x, y = queue.popleft()
        mask_pixels[x, y] = 255

        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h:
                continue
            try_add(nx, ny)

    return mask


def is_background_pixel(
    rgb: Image.Image,
    pixels,
    x: int,
    y: int,
    background_colors: list[tuple[int, int, int]],
    tolerance: int,
) -> bool:
    color = pixels[x, y]
    # The baked checkerboard is very light and almost perfectly neutral.
    if min(color) < 238 or max(color) - min(color) > 7:
        return False
    if not any(color_distance(color, bg) <= tolerance for bg in background_colors):
        return False
    w, h = rgb.size
    if x == 0 or y == 0 or x == w - 1 or y == h - 1:
        return True

    # Background squares are flat. White fur is also bright, but usually has
    # local texture; requiring nearby pixels to look like background helps keep
    # the flood-fill from walking into the bear.
    candidate_neighbors = 0
    checked_neighbors = 0
    for ny in range(max(0, y - 1), min(h, y + 2)):
        for nx in range(max(0, x - 1), min(w, x + 2)):
            if nx == x and ny == y:
                continue
            checked_neighbors += 1
            neighbor = pixels[nx, ny]
            if (
                min(neighbor) >= 238
                and max(neighbor) - min(neighbor) <= 7
                and any(color_distance(neighbor, bg) <= tolerance + 1 for bg in background_colors)
            ):
                candidate_neighbors += 1

    return checked_neighbors == 0 or candidate_neighbors >= 3


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def remove_alpha_regions_touching_border(alpha: Image.Image) -> None:
    w, h = alpha.size
    pixels = alpha.load()
    visited = bytearray(w * h)
    queue: deque[tuple[int, int]] = deque()

    def add(x: int, y: int) -> None:
        idx = y * w + x
        if visited[idx]:
            return
        visited[idx] = 1
        if pixels[x, y] > 0:
            queue.append((x, y))

    for x in range(w):
        add(x, 0)
        add(x, h - 1)
    for y in range(h):
        add(0, y)
        add(w - 1, y)

    while queue:
        x, y = queue.popleft()
        pixels[x, y] = 0
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h:
                continue
            idx = ny * w + nx
            if visited[idx]:
                continue
            visited[idx] = 1
            if pixels[nx, ny] > 0:
                queue.append((nx, ny))


def keep_largest_alpha_component(alpha: Image.Image) -> None:
    w, h = alpha.size
    pixels = alpha.load()
    visited = bytearray(w * h)
    largest: list[tuple[int, int]] = []

    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if visited[idx] or pixels[x, y] == 0:
                continue

            component: list[tuple[int, int]] = []
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[idx] = 1

            while queue:
                cx, cy = queue.popleft()
                component.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    nidx = ny * w + nx
                    if visited[nidx] or pixels[nx, ny] == 0:
                        continue
                    visited[nidx] = 1
                    queue.append((nx, ny))

            if len(component) > len(largest):
                largest = component

    cleaned = Image.new("L", (w, h), 0)
    cleaned_pixels = cleaned.load()
    for x, y in largest:
        cleaned_pixels[x, y] = 255
    alpha.paste(cleaned)


def pad_bounds(
    bounds: tuple[int, int, int, int],
    size: tuple[int, int],
    padding: int,
) -> tuple[int, int, int, int]:
    left, top, right, bottom = bounds
    width, height = size
    return (
        max(0, left - padding),
        max(0, top - padding),
        min(width, right + padding),
        min(height, bottom + padding),
    )


def create_preview(reports: list[RefinementReport]) -> None:
    columns = ["source", "previous clean", "v2 conservative"]
    thumb_w, thumb_h = 360, 310
    label_h = 60
    margin = 18
    gap = 18
    row_h = label_h + thumb_h + margin
    width = margin * 2 + len(columns) * thumb_w + (len(columns) - 1) * gap
    height = margin + len(reports) * row_h

    preview = Image.new("RGB", (width, height), (248, 248, 248))
    draw = ImageDraw.Draw(preview)
    font = load_font(14)
    title_font = load_font(16)

    for row, report in enumerate(reports):
        y = margin + row * row_h
        files = [
            report.candidate.source,
            report.candidate.previous_clean,
            report.candidate.output,
        ]
        draw.text((margin, y), report.candidate.name, fill=(30, 30, 30), font=title_font)

        for col, (label, path) in enumerate(zip(columns, files)):
            x = margin + col * (thumb_w + gap)
            draw.text((x, y + 22), label, fill=(45, 45, 45), font=font)
            draw.text((x, y + 38), path.name, fill=(45, 45, 45), font=font)
            image = Image.open(path).convert("RGBA")
            thumb = render_on_checker(image, (thumb_w, thumb_h))
            preview.paste(thumb, (x, y + label_h))

        draw.line(
            (0, y + row_h - 1, width, y + row_h - 1),
            fill=(215, 215, 215),
            width=1,
        )

    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_PATH)


def render_on_checker(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    box_w, box_h = box
    checker = Image.new("RGB", box, (255, 255, 255))
    draw = ImageDraw.Draw(checker)
    square = 14
    for y in range(0, box_h, square):
        for x in range(0, box_w, square):
            if ((x // square) + (y // square)) % 2:
                draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(232, 232, 232))

    thumb = image.copy()
    thumb.thumbnail((box_w, box_h), Image.Resampling.LANCZOS)
    x = (box_w - thumb.width) // 2
    y = (box_h - thumb.height) // 2
    checker.paste(thumb, (x, y), thumb)
    return checker


def load_font(size: int) -> ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ):
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def print_reports(reports: list[RefinementReport]) -> None:
    for report in reports:
        print(f"candidate: {report.candidate.name}")
        print(f"input: {rel(report.candidate.source)}")
        print(f"previous clean: {rel(report.candidate.previous_clean)}")
        print(f"output: {rel(report.candidate.output)}")
        print(f"original size: {report.original_size[0]}x{report.original_size[1]}")
        print(f"output size: {report.output_size[0]}x{report.output_size[1]}")
        print(f"detected background colors: {report.background_colors}")
        print(f"crop bounds: {report.crop_bounds}")
        print(f"method: {report.method}")
        if report.warnings:
            print("warnings:")
            for warning in report.warnings:
                print(f"  - {warning}")
        else:
            print("warnings: none")
        print()


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


if __name__ == "__main__":
    main()
