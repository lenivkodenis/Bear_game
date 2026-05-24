#!/usr/bin/env python3
"""Prepare bear cub PNG assets without modifying source files.

The project environment currently has no Pillow dependency, so this script uses
small stdlib PNG read/write helpers for 8-bit RGB/RGBA PNG files.
"""

from __future__ import annotations

import binascii
import shutil
import struct
import zlib
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from statistics import median


ROOT = Path(__file__).resolve().parents[1]
LEGACY_DIR = ROOT / "assets/images/bear_cub"
BEAR_DIR = ROOT / "assets/images/characters/bear_cub"
SOURCE_DIR = BEAR_DIR / "source"
PROCESSED_DIR = BEAR_DIR / "processed"
ANIMATION_DIRS = [
    BEAR_DIR / "animations/idle",
    BEAR_DIR / "animations/walk",
    BEAR_DIR / "animations/jump",
    BEAR_DIR / "animations/sit",
]
PREVIEW_PATH = ROOT / "docs/bear_asset_processing_preview.png"

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


@dataclass
class PngImage:
    width: int
    height: int
    color_type: int
    pixels: bytearray  # RGBA


@dataclass
class ProcessReport:
    input_path: Path
    output_path: Path
    original_size: tuple[int, int]
    processed_size: tuple[int, int]
    detected_alpha: bool
    crop_bounds: tuple[int, int, int, int] | None
    method: str
    warnings: list[str]


def read_png(path: Path) -> PngImage:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG file")

    pos = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = None
    idat = bytearray()

    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        pos += 4
        chunk_type = data[pos : pos + 4]
        pos += 4
        chunk_data = data[pos : pos + length]
        pos += length + 4  # Skip CRC.

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _, _, _ = struct.unpack(
                ">IIBBBBB", chunk_data
            )
        elif chunk_type == b"IDAT":
            idat.extend(chunk_data)
        elif chunk_type == b"IEND":
            break

    if width is None or height is None or bit_depth != 8 or color_type not in (2, 6):
        raise ValueError(
            f"{path} must be an 8-bit RGB/RGBA PNG; got bit_depth={bit_depth}, "
            f"color_type={color_type}"
        )

    channels = 4 if color_type == 6 else 3
    stride = width * channels
    raw = zlib.decompress(bytes(idat))
    recon = bytearray(height * stride)
    in_pos = 0

    for y in range(height):
        filter_type = raw[in_pos]
        in_pos += 1
        scanline = bytearray(raw[in_pos : in_pos + stride])
        in_pos += stride
        prev_start = (y - 1) * stride
        out_start = y * stride

        for x in range(stride):
            left = recon[out_start + x - channels] if x >= channels else 0
            up = recon[prev_start + x] if y > 0 else 0
            up_left = recon[prev_start + x - channels] if y > 0 and x >= channels else 0

            if filter_type == 0:
                value = scanline[x]
            elif filter_type == 1:
                value = (scanline[x] + left) & 0xFF
            elif filter_type == 2:
                value = (scanline[x] + up) & 0xFF
            elif filter_type == 3:
                value = (scanline[x] + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                value = (scanline[x] + paeth(left, up, up_left)) & 0xFF
            else:
                raise ValueError(f"Unsupported PNG filter {filter_type} in {path}")

            recon[out_start + x] = value

    rgba = bytearray(width * height * 4)
    if color_type == 6:
        rgba[:] = recon
    else:
        for i in range(width * height):
            src = i * 3
            dst = i * 4
            rgba[dst : dst + 4] = recon[src : src + 3] + b"\xff"

    return PngImage(width=width, height=height, color_type=color_type, pixels=rgba)


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def write_png(path: Path, width: int, height: int, rgba: bytearray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rows = bytearray()
    stride = width * 4
    for y in range(height):
        rows.append(0)
        rows.extend(rgba[y * stride : (y + 1) * stride])

    def chunk(kind: bytes, payload: bytes) -> bytes:
        crc = binascii.crc32(kind + payload) & 0xFFFFFFFF
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", crc)

    png = bytearray(PNG_SIGNATURE)
    png.extend(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
    png.extend(chunk(b"IDAT", zlib.compress(bytes(rows), level=6)))
    png.extend(chunk(b"IEND", b""))
    path.write_bytes(bytes(png))


def ensure_directories() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    for path in ANIMATION_DIRS:
        path.mkdir(parents=True, exist_ok=True)


def copy_legacy_sources() -> list[Path]:
    copied_or_existing = []
    for src in sorted(LEGACY_DIR.glob("*.png")):
        dst = SOURCE_DIR / src.name
        if not dst.exists():
            shutil.copy2(src, dst)
        copied_or_existing.append(dst)
    return copied_or_existing


def has_real_alpha(image: PngImage) -> bool:
    return image.color_type == 6 and any(image.pixels[i + 3] < 255 for i in range(0, len(image.pixels), 4))


def estimate_checker_tile(image: PngImage) -> int:
    runs = []
    y = 0
    last = rgb_at(image, 0, y)
    run = 1
    for x in range(1, image.width):
        current = rgb_at(image, x, y)
        if color_distance(current, last) > 18:
            if run >= 8:
                runs.append(run)
            run = 1
            last = current
        else:
            run += 1
    if run >= 8:
        runs.append(run)
    if not runs:
        return 32
    return max(8, min(96, int(round(median(runs)))))


def estimate_checker_colors(image: PngImage, tile: int) -> tuple[tuple[int, int, int], tuple[int, int, int]]:
    samples = [[], []]
    step = max(3, tile // 3)

    for x in range(0, image.width, step):
        samples[(x // tile) % 2].append(rgb_at(image, x, 0))
        samples[((x // tile) + ((image.height - 1) // tile)) % 2].append(
            rgb_at(image, x, image.height - 1)
        )
    for y in range(0, image.height, step):
        samples[(y // tile) % 2].append(rgb_at(image, 0, y))
        samples[(((image.width - 1) // tile) + (y // tile)) % 2].append(
            rgb_at(image, image.width - 1, y)
        )

    return tuple(channel_median(samples[0])), tuple(channel_median(samples[1]))


def channel_median(values: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    if not values:
        return (255, 255, 255)
    return (
        int(median(v[0] for v in values)),
        int(median(v[1] for v in values)),
        int(median(v[2] for v in values)),
    )


def rgb_at(image: PngImage, x: int, y: int) -> tuple[int, int, int]:
    pos = (y * image.width + x) * 4
    return image.pixels[pos], image.pixels[pos + 1], image.pixels[pos + 2]


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def is_checker_background(
    image: PngImage,
    x: int,
    y: int,
    tile: int,
    colors: tuple[tuple[int, int, int], tuple[int, int, int]],
) -> bool:
    expected = colors[((x // tile) + (y // tile)) % 2]
    rgb = rgb_at(image, x, y)
    nearest_bg = min(color_distance(rgb, colors[0]), color_distance(rgb, colors[1]))
    channel_spread = max(rgb) - min(rgb)
    return color_distance(rgb, expected) <= 16 or (
        nearest_bg <= 10 and channel_spread <= 4
    )


def remove_checkerboard_background(image: PngImage) -> tuple[bytearray, str, list[str]]:
    tile = estimate_checker_tile(image)
    colors = estimate_checker_colors(image, tile)
    alpha = bytearray(b"\xff" * (image.width * image.height))
    visited = bytearray(image.width * image.height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        idx = y * image.width + x
        if visited[idx]:
            return
        visited[idx] = 1
        if is_checker_background(image, x, y, tile, colors):
            queue.append((x, y))

    for x in range(image.width):
        enqueue(x, 0)
        enqueue(x, image.height - 1)
    for y in range(image.height):
        enqueue(0, y)
        enqueue(image.width - 1, y)

    while queue:
        x, y = queue.popleft()
        idx = y * image.width + x
        alpha[idx] = 0
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if nx < 0 or ny < 0 or nx >= image.width or ny >= image.height:
                continue
            nidx = ny * image.width + nx
            if visited[nidx]:
                continue
            visited[nidx] = 1
            if is_checker_background(image, nx, ny, tile, colors):
                queue.append((nx, ny))

    rgba = bytearray(image.pixels)
    transparent = 0
    for i, a in enumerate(alpha):
        rgba[i * 4 + 3] = a
        if a == 0:
            transparent += 1

    removed_ratio = transparent / (image.width * image.height)
    warnings = [
        "Best-effort checkerboard removal; inspect edges manually before game hookup."
    ]
    if removed_ratio < 0.10:
        warnings.append("Only a small background area was removed; cleanup may be incomplete.")
    method = f"edge-connected checkerboard removal, tile={tile}, colors={colors}"
    return rgba, method, warnings


def alpha_bbox(width: int, height: int, rgba: bytearray, threshold: int = 0) -> tuple[int, int, int, int] | None:
    left, top = width, height
    right, bottom = -1, -1
    for y in range(height):
        row = y * width * 4
        for x in range(width):
            if rgba[row + x * 4 + 3] > threshold:
                left = min(left, x)
                top = min(top, y)
                right = max(right, x)
                bottom = max(bottom, y)
    if right < left or bottom < top:
        return None
    return left, top, right + 1, bottom + 1


def crop_rgba(
    width: int,
    height: int,
    rgba: bytearray,
    bbox: tuple[int, int, int, int],
    padding: int = 8,
) -> tuple[int, int, bytearray, tuple[int, int, int, int]]:
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(width, right + padding)
    bottom = min(height, bottom + padding)
    new_width = right - left
    new_height = bottom - top
    cropped = bytearray(new_width * new_height * 4)
    for y in range(new_height):
        src_start = ((top + y) * width + left) * 4
        dst_start = y * new_width * 4
        cropped[dst_start : dst_start + new_width * 4] = rgba[
            src_start : src_start + new_width * 4
        ]
    return new_width, new_height, cropped, (left, top, right, bottom)


def process_one(path: Path) -> ProcessReport:
    image = read_png(path)
    detected_alpha = has_real_alpha(image)
    warnings: list[str] = []

    if detected_alpha:
        rgba = image.pixels
        method = "crop by existing alpha"
    else:
        rgba, method, warnings = remove_checkerboard_background(image)

    bbox = alpha_bbox(image.width, image.height, rgba)
    if bbox is None:
        warnings.append("No visible pixels after processing; kept original canvas.")
        out_width, out_height, out_pixels, crop_bounds = image.width, image.height, rgba, None
    else:
        out_width, out_height, out_pixels, crop_bounds = crop_rgba(
            image.width, image.height, rgba, bbox
        )

    output_name = f"{path.stem}_clean.png"
    output_path = PROCESSED_DIR / output_name
    write_png(output_path, out_width, out_height, out_pixels)

    return ProcessReport(
        input_path=path,
        output_path=output_path,
        original_size=(image.width, image.height),
        processed_size=(out_width, out_height),
        detected_alpha=detected_alpha,
        crop_bounds=crop_bounds,
        method=method,
        warnings=warnings,
    )


def draw_preview(reports: list[ProcessReport]) -> None:
    cell_w = 900
    row_h = 260
    label_h = 28
    width = cell_w
    height = max(1, len(reports)) * row_h
    canvas = bytearray([248, 248, 248, 255] * width * height)

    for row, report in enumerate(reports):
        y0 = row * row_h
        draw_text(canvas, width, height, 16, y0 + 8, report.input_path.name)
        draw_text(canvas, width, height, 16, y0 + 28, "source")
        draw_text(canvas, width, height, 466, y0 + 28, "processed")
        source = read_png(report.input_path)
        processed = read_png(report.output_path)
        paste_thumb(canvas, width, height, source, 16, y0 + label_h + 26, 400, 195)
        paste_thumb(canvas, width, height, processed, 466, y0 + label_h + 26, 400, 195)
        draw_line(canvas, width, height, 0, y0 + row_h - 1, width - 1, y0 + row_h - 1, (210, 210, 210, 255))

    write_png(PREVIEW_PATH, width, height, canvas)


def paste_thumb(
    canvas: bytearray,
    canvas_w: int,
    canvas_h: int,
    image: PngImage,
    x: int,
    y: int,
    box_w: int,
    box_h: int,
) -> None:
    scale = min(box_w / image.width, box_h / image.height)
    thumb_w = max(1, int(image.width * scale))
    thumb_h = max(1, int(image.height * scale))
    px = x + (box_w - thumb_w) // 2
    py = y + (box_h - thumb_h) // 2

    for ty in range(thumb_h):
        sy = min(image.height - 1, int(ty / scale))
        for tx in range(thumb_w):
            sx = min(image.width - 1, int(tx / scale))
            src = (sy * image.width + sx) * 4
            alpha = image.pixels[src + 3] / 255
            bg = checker_color(px + tx, py + ty)
            rgb = tuple(
                int(image.pixels[src + channel] * alpha + bg[channel] * (1 - alpha))
                for channel in range(3)
            )
            set_pixel(canvas, canvas_w, canvas_h, px + tx, py + ty, (*rgb, 255))


def checker_color(x: int, y: int) -> tuple[int, int, int, int]:
    return (238, 238, 238, 255) if ((x // 12) + (y // 12)) % 2 else (255, 255, 255, 255)


FONT = {
    "a": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "b": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "c": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
    "d": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "e": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "f": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "g": ["01111", "10000", "10000", "10011", "10001", "10001", "01111"],
    "h": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "i": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "j": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
    "k": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "l": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "m": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "n": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "o": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "p": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    "r": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "s": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "t": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "u": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "v": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "w": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
    "x": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
    "6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
    "_": ["00000", "00000", "00000", "00000", "00000", "00000", "11111"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "01100", "01100"],
    " ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
}


def draw_text(canvas: bytearray, width: int, height: int, x: int, y: int, text: str) -> None:
    cursor = x
    for char in text.lower():
        glyph = FONT.get(char, FONT[" "])
        for gy, row in enumerate(glyph):
            for gx, value in enumerate(row):
                if value == "1":
                    for sy in range(2):
                        for sx in range(2):
                            set_pixel(canvas, width, height, cursor + gx * 2 + sx, y + gy * 2 + sy, (35, 35, 35, 255))
        cursor += 12


def draw_line(
    canvas: bytearray,
    width: int,
    height: int,
    x1: int,
    y1: int,
    x2: int,
    y2: int,
    color: tuple[int, int, int, int],
) -> None:
    if y1 == y2:
        for x in range(min(x1, x2), max(x1, x2) + 1):
            set_pixel(canvas, width, height, x, y1, color)


def set_pixel(
    canvas: bytearray,
    width: int,
    height: int,
    x: int,
    y: int,
    color: tuple[int, int, int, int],
) -> None:
    if x < 0 or y < 0 or x >= width or y >= height:
        return
    pos = (y * width + x) * 4
    canvas[pos : pos + 4] = bytes(color)


def print_report(reports: list[ProcessReport]) -> None:
    for report in reports:
        print(f"input: {relative(report.input_path)}")
        print(f"output: {relative(report.output_path)}")
        print(f"original size: {report.original_size[0]}x{report.original_size[1]}")
        print(f"processed size: {report.processed_size[0]}x{report.processed_size[1]}")
        print(f"detected alpha: {'yes' if report.detected_alpha else 'no'}")
        print(f"crop bounds: {report.crop_bounds}")
        print(f"method used: {report.method}")
        if report.warnings:
            print("warnings:")
            for warning in report.warnings:
                print(f"  - {warning}")
        else:
            print("warnings: none")
        print()


def relative(path: Path) -> str:
    return str(path.relative_to(ROOT))


def main() -> None:
    ensure_directories()
    sources = copy_legacy_sources()
    if not sources:
        raise SystemExit("No bear cub PNG files found.")

    reports = [process_one(path) for path in sources]
    draw_preview(reports)
    print_report(reports)
    print(f"preview: {relative(PREVIEW_PATH)}")


if __name__ == "__main__":
    main()
