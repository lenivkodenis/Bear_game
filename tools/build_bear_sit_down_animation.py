#!/usr/bin/env python3
"""Build aligned sit-down frames from a generated sprite sheet."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
VERSION = "v4"
SOURCE_SHEET = (
    ROOT / f"assets/_incoming/bear_cub/sit_down_{VERSION}/source_sheet_alpha_contract1.png"
)
OUTPUT_DIR = ROOT / f"assets/images/characters/bear_cub/animations/sit_down_{VERSION}"
PREVIEW_PATH = ROOT / f"docs/bear_sit_down_{VERSION}_preview.png"
MOTION_GIF_PATH = ROOT / f"docs/bear_sit_down_{VERSION}_motion.gif"

SOURCE_COLUMNS = 4
SOURCE_ROWS = 3
PREVIEW_COLUMNS = 3
FRAME_SELECTION = (1, 2, 3, 5, 6, 7, 9, 10, 11)
ALPHA_THRESHOLD = 14
CONTACT_BAND_PX = 28
LEFT_PAD = 24
RIGHT_PAD = 24
TOP_PAD = 24
BOTTOM_PAD = 18
MIN_COMPONENT_AREA = 3200


@dataclass(frozen=True)
class FrameCut:
    index: int
    image: Image.Image
    bbox: tuple[int, int, int, int]
    bottom_y: int
    anchor_x: float
    crop: Image.Image

    @property
    def anchor_offset(self) -> float:
        return self.anchor_x - self.bbox[0]

    @property
    def bottom_offset(self) -> int:
        return self.bottom_y - self.bbox[1]


def main() -> None:
    if not SOURCE_SHEET.exists():
        raise FileNotFoundError(SOURCE_SHEET)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SOURCE_SHEET).convert("RGBA")
    frames = cut_frames(sheet)
    canvas_width, canvas_height, anchor_x, baseline_y = plan_canvas(frames)
    outputs = place_frames(
        frames,
        canvas_width=canvas_width,
        canvas_height=canvas_height,
        anchor_x=anchor_x,
        baseline_y=baseline_y,
    )

    for path in sorted(OUTPUT_DIR.glob(f"bear_sit_down_{VERSION}_*.png")):
        path.unlink()

    for index, frame in enumerate(outputs, start=1):
        frame.save(OUTPUT_DIR / f"bear_sit_down_{VERSION}_{index:02d}.png")

    create_preview(outputs, anchor_x=anchor_x, baseline_y=baseline_y)
    create_motion_gif(outputs)

    print(f"Built bear sit-down {VERSION} frames")
    print(f"source: {rel(SOURCE_SHEET)}")
    print(f"output: {rel(OUTPUT_DIR)}")
    print(f"frame_size: {canvas_width}x{canvas_height}")
    print(f"front_paw_anchor_x: {anchor_x:.1f}")
    print(f"baseline_y: {baseline_y:.1f}")
    for frame in frames:
        print(
            f"  {frame.index:02d}: bbox={frame.bbox}, "
            f"anchor_offset={frame.anchor_offset:.1f}, "
            f"bottom_offset={frame.bottom_offset}"
        )
    print(f"preview: {rel(PREVIEW_PATH)}")
    print(f"motion_gif: {rel(MOTION_GIF_PATH)}")


def cut_frames(sheet: Image.Image) -> list[FrameCut]:
    component_images = extract_frame_components(sheet)
    frames: list[FrameCut] = []

    for index, cell in enumerate(component_images, start=1):
        bbox = alpha_bbox(cell)
        if bbox is None:
            raise ValueError(f"Frame {index} has no visible alpha.")

        bottom_y = visible_bottom_y(cell, bbox)
        anchor_x = front_paw_anchor_x(cell, bbox, bottom_y)
        crop = cell.crop(bbox)
        crop = neutralize_edge_spill(crop)

        frames.append(
            FrameCut(
                index=index,
                image=cell,
                bbox=bbox,
                bottom_y=bottom_y,
                anchor_x=anchor_x,
                crop=crop,
            )
        )

    return frames


def extract_frame_components(sheet: Image.Image) -> list[Image.Image]:
    width, height = sheet.size
    alpha = sheet.getchannel("A")
    alpha_pixels = alpha.load()
    source_pixels = sheet.load()
    visited = bytearray(width * height)
    components: list[tuple[int, tuple[int, int, int, int], list[int]]] = []

    for start_y in range(height):
        for start_x in range(width):
            start_index = start_y * width + start_x
            if visited[start_index] or alpha_pixels[start_x, start_y] <= ALPHA_THRESHOLD:
                continue

            stack = [(start_x, start_y)]
            visited[start_index] = 1
            indices: list[int] = []
            min_x = max_x = start_x
            min_y = max_y = start_y

            while stack:
                x, y = stack.pop()
                index = y * width + x
                indices.append(index)
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)

                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    neighbor_index = ny * width + nx
                    if visited[neighbor_index]:
                        continue
                    visited[neighbor_index] = 1
                    if alpha_pixels[nx, ny] > ALPHA_THRESHOLD:
                        stack.append((nx, ny))

            if len(indices) >= MIN_COMPONENT_AREA:
                components.append((len(indices), (min_x, min_y, max_x + 1, max_y + 1), indices))

    expected_component_count = SOURCE_COLUMNS * SOURCE_ROWS
    if len(components) < expected_component_count:
        raise ValueError(
            f"Expected {expected_component_count} bear components, found {len(components)}."
        )

    components = sorted(components, key=lambda item: item[0], reverse=True)[
        :expected_component_count
    ]
    components.sort(key=lambda item: ((item[1][1] + item[1][3]) / 2, item[1][0]))

    ordered: list[tuple[int, tuple[int, int, int, int], list[int]]] = []
    for row_start in range(0, len(components), SOURCE_COLUMNS):
        row = components[row_start : row_start + SOURCE_COLUMNS]
        ordered.extend(sorted(row, key=lambda item: item[1][0]))

    all_images: list[Image.Image] = []
    for _, bbox, indices in ordered:
        left, top, right, bottom = bbox
        component = Image.new("RGBA", (right - left, bottom - top), (0, 0, 0, 0))
        component_pixels = component.load()
        for index in indices:
            x = index % width
            y = index // width
            if left <= x < right and top <= y < bottom:
                component_pixels[x - left, y - top] = source_pixels[x, y]
        all_images.append(component)

    return [all_images[index - 1] for index in FRAME_SELECTION]


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > ALPHA_THRESHOLD else 0)
    return mask.getbbox()


def visible_bottom_y(image: Image.Image, bbox: tuple[int, int, int, int]) -> int:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    left, top, right, bottom = bbox

    for y in range(bottom - 1, top - 1, -1):
        for x in range(left, right):
            if pixels[x, y] > ALPHA_THRESHOLD:
                return y

    return bottom - 1


def front_paw_anchor_x(
    image: Image.Image,
    bbox: tuple[int, int, int, int],
    bottom_y: int,
) -> float:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    left, top, right, _ = bbox
    band_top = max(top, bottom_y - CONTACT_BAND_PX)
    contact_xs: list[int] = []

    for y in range(band_top, bottom_y + 1):
        for x in range(left, right):
            if pixels[x, y] > 72:
                contact_xs.append(x)

    if not contact_xs:
        return (left + right) / 2

    contact_xs.sort()
    right_cluster_start = contact_xs[int(len(contact_xs) * 0.64)]
    right_cluster = [x for x in contact_xs if x >= right_cluster_start]
    return float(median(right_cluster or contact_xs))


def neutralize_edge_spill(image: Image.Image) -> Image.Image:
    output = image.copy()
    pixels = output.load()
    alpha = output.getchannel("A")
    alpha_pixels = alpha.load()
    width, height = output.size

    for y in range(height):
        for x in range(width):
            a = alpha_pixels[x, y]
            if a == 0:
                continue

            edge = a < 250 or touches_transparency(alpha_pixels, width, height, x, y)
            if not edge:
                continue

            r, g, b, _ = pixels[x, y]
            if g <= r + 6 and b <= r + 10:
                continue

            gray = int(round((r + g + b) / 3))
            strength = 0.72 if a < 230 else 0.42
            pixels[x, y] = (
                int(round(r * (1 - strength) + gray * strength)),
                int(round(g * (1 - strength) + gray * strength)),
                int(round(b * (1 - strength) + gray * strength)),
                a,
            )

    return output


def touches_transparency(alpha_pixels, width: int, height: int, x: int, y: int) -> bool:
    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
        if nx < 0 or ny < 0 or nx >= width or ny >= height:
            return True
        if alpha_pixels[nx, ny] == 0:
            return True
    return False


def plan_canvas(frames: list[FrameCut]) -> tuple[int, int, float, float]:
    left_span = max(frame.anchor_offset for frame in frames)
    right_span = max(frame.crop.width - frame.anchor_offset for frame in frames)
    top_span = max(frame.bottom_offset for frame in frames)

    canvas_width = int(round(LEFT_PAD + left_span + right_span + RIGHT_PAD))
    canvas_height = int(round(TOP_PAD + top_span + BOTTOM_PAD))
    anchor_x = LEFT_PAD + left_span
    baseline_y = TOP_PAD + top_span
    return canvas_width, canvas_height, anchor_x, baseline_y


def place_frames(
    frames: list[FrameCut],
    *,
    canvas_width: int,
    canvas_height: int,
    anchor_x: float,
    baseline_y: float,
) -> list[Image.Image]:
    outputs: list[Image.Image] = []

    for frame in frames:
        output = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
        paste_x = int(round(anchor_x - frame.anchor_offset))
        paste_y = int(round(baseline_y - frame.bottom_offset))
        output.alpha_composite(frame.crop, (paste_x, paste_y))
        outputs.append(output)

    return outputs


def create_preview(
    frames: list[Image.Image],
    *,
    anchor_x: float,
    baseline_y: float,
) -> None:
    cell_width, cell_height = frames[0].size
    label_height = 28
    preview = Image.new(
        "RGBA",
        (
            PREVIEW_COLUMNS * cell_width,
            preview_rows(len(frames)) * (cell_height + label_height),
        ),
        (235, 242, 246, 255),
    )
    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default()

    for index, frame in enumerate(frames, start=1):
        row = (index - 1) // PREVIEW_COLUMNS
        column = (index - 1) % PREVIEW_COLUMNS
        x = column * cell_width
        y = row * (cell_height + label_height)
        draw_checkerboard(preview, (x, y, x + cell_width, y + cell_height))
        preview.alpha_composite(frame, (x, y))
        draw.line(
            (x, y + baseline_y, x + cell_width, y + baseline_y),
            fill=(235, 64, 52, 220),
            width=2,
        )
        draw.line(
            (x + anchor_x, y, x + anchor_x, y + cell_height),
            fill=(45, 108, 223, 180),
            width=2,
        )
        draw.text(
            (x + 8, y + cell_height + 8),
            f"bear_sit_down_{VERSION}_{index:02d}",
            fill=(24, 35, 45, 255),
            font=font,
        )

    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(PREVIEW_PATH)


def preview_rows(frame_count: int) -> int:
    return (frame_count + PREVIEW_COLUMNS - 1) // PREVIEW_COLUMNS


def draw_checkerboard(
    image: Image.Image,
    box: tuple[int, int, int, int],
    *,
    tile: int = 18,
) -> None:
    draw = ImageDraw.Draw(image)
    left, top, right, bottom = box
    colors = ((242, 246, 249, 255), (224, 232, 238, 255))

    for y in range(top, bottom, tile):
        for x in range(left, right, tile):
            color = colors[((x - left) // tile + (y - top) // tile) % 2]
            draw.rectangle((x, y, min(x + tile, right), min(y + tile, bottom)), fill=color)


def create_motion_gif(frames: list[Image.Image]) -> None:
    checker_frames = []
    for frame in frames:
        background = Image.new("RGBA", frame.size, (235, 242, 246, 255))
        draw_checkerboard(background, (0, 0, frame.width, frame.height), tile=16)
        background.alpha_composite(frame)
        checker_frames.append(background.convert("P", palette=Image.Palette.ADAPTIVE))

    MOTION_GIF_PATH.parent.mkdir(parents=True, exist_ok=True)
    checker_frames[0].save(
        MOTION_GIF_PATH,
        save_all=True,
        append_images=checker_frames[1:] + list(reversed(checker_frames[1:-1])),
        duration=85,
        loop=0,
        disposal=2,
    )


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


if __name__ == "__main__":
    main()
