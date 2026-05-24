#!/usr/bin/env python3
"""Diagnose and normalize bear cub walk-cycle frames.

The script does not modify the original walk frames. It writes diagnostics
previews and normalized copies with aligned silhouette center and baseline.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WALK_DIR = ROOT / "assets/images/characters/bear_cub/animations/walk"
NORMALIZED_DIR = ROOT / "assets/images/characters/bear_cub/animations/walk_normalized"
DIAGNOSTICS_PATH = ROOT / "docs/bear_walk_cycle_diagnostics.png"
NORMALIZATION_PREVIEW_PATH = ROOT / "docs/bear_walk_cycle_normalization_preview.png"
FRAME_NAMES = [f"walk_{index:02d}.png" for index in range(1, 7)]
PREVIEW_SCALE = 2
LABEL_HEIGHT = 30


@dataclass(frozen=True)
class FrameMetrics:
    path: Path
    size: tuple[int, int]
    mode: str
    has_alpha: bool
    bbox: tuple[int, int, int, int] | None

    @property
    def visible_width(self) -> int:
        return 0 if self.bbox is None else self.bbox[2] - self.bbox[0]

    @property
    def visible_height(self) -> int:
        return 0 if self.bbox is None else self.bbox[3] - self.bbox[1]

    @property
    def bottom_alpha_y(self) -> int | None:
        return None if self.bbox is None else self.bbox[3] - 1

    @property
    def center_x(self) -> float | None:
        return None if self.bbox is None else (self.bbox[0] + self.bbox[2] - 1) / 2

    @property
    def margins(self) -> tuple[int, int, int, int] | None:
        if self.bbox is None:
            return None
        width, height = self.size
        left, top, right, bottom = self.bbox
        return left, width - right, top, height - bottom


def main() -> int:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Pillow is not available in the current Python environment.")
        print("Install tool dependencies with:")
        print(".venv-tools/bin/python -m pip install -r tools/requirements.txt")
        return 2

    frames = load_frames(Image)
    metrics = [inspect_frame(path, image) for path, image in frames]
    print_report(metrics)

    target_center_x = round(sum(metric.center_x or 0 for metric in metrics) / len(metrics))
    target_bottom_y = max(metric.bottom_alpha_y or 0 for metric in metrics)
    normalized_frames = normalize_frames(Image, frames, metrics, target_center_x, target_bottom_y)

    create_diagnostics_preview(Image, ImageDraw, ImageFont, frames, metrics, DIAGNOSTICS_PATH)
    normalized_metrics = [
        inspect_frame(path, image)
        for path, image in normalized_frames
    ]
    create_before_after_preview(
        Image,
        ImageDraw,
        ImageFont,
        frames,
        metrics,
        normalized_frames,
        normalized_metrics,
        NORMALIZATION_PREVIEW_PATH,
    )

    print()
    print(f"target center x: {target_center_x}")
    print(f"target bottom alpha y: {target_bottom_y}")
    print(f"diagnostics preview: {relative(DIAGNOSTICS_PATH)}")
    print(f"normalization preview: {relative(NORMALIZATION_PREVIEW_PATH)}")
    print(f"normalized frames: {relative(NORMALIZED_DIR)}")
    return 0


def load_frames(image_module):
    frames = []
    for name in FRAME_NAMES:
        path = WALK_DIR / name
        if not path.exists():
            raise FileNotFoundError(path)
        frames.append((path, image_module.open(path).convert("RGBA")))
    return frames


def inspect_frame(path: Path, image) -> FrameMetrics:
    alpha = image.getchannel("A")
    return FrameMetrics(
        path=path,
        size=image.size,
        mode=image.mode,
        has_alpha=image.mode == "RGBA",
        bbox=alpha.getbbox(),
    )


def normalize_frames(image_module, frames, metrics, target_center_x: int, target_bottom_y: int):
    NORMALIZED_DIR.mkdir(parents=True, exist_ok=True)
    normalized = []

    for (path, image), metric in zip(frames, metrics):
        output = image_module.new("RGBA", image.size, (255, 255, 255, 0))
        if metric.bbox is None or metric.center_x is None or metric.bottom_alpha_y is None:
            dx = 0
            dy = 0
        else:
            dx = round(target_center_x - metric.center_x)
            dy = target_bottom_y - metric.bottom_alpha_y
        output.alpha_composite(image, (dx, dy))
        out_path = NORMALIZED_DIR / path.name.replace(".png", "_normalized.png")
        output.save(out_path)
        normalized.append((out_path, output))

    return normalized


def create_diagnostics_preview(image_module, draw_module, font_module, frames, metrics, path: Path) -> None:
    target_bottom_y = max(metric.bottom_alpha_y or 0 for metric in metrics)
    target_center_x = round(sum(metric.center_x or 0 for metric in metrics) / len(metrics))
    preview = compose_row_preview(
        image_module,
        draw_module,
        font_module,
        frames,
        metrics,
        target_bottom_y,
        target_center_x,
        row_label="original",
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(path)


def create_before_after_preview(
    image_module,
    draw_module,
    font_module,
    original_frames,
    original_metrics,
    normalized_frames,
    normalized_metrics,
    path: Path,
) -> None:
    target_bottom_y = max(metric.bottom_alpha_y or 0 for metric in normalized_metrics)
    target_center_x = round(
        sum(metric.center_x or 0 for metric in normalized_metrics) / len(normalized_metrics)
    )
    original_row = compose_row_preview(
        image_module,
        draw_module,
        font_module,
        original_frames,
        original_metrics,
        target_bottom_y,
        target_center_x,
        row_label="original",
    )
    normalized_row = compose_row_preview(
        image_module,
        draw_module,
        font_module,
        normalized_frames,
        normalized_metrics,
        target_bottom_y,
        target_center_x,
        row_label="normalized",
    )
    preview = image_module.new(
        "RGBA",
        (max(original_row.width, normalized_row.width), original_row.height + normalized_row.height),
        (255, 255, 255, 255),
    )
    preview.alpha_composite(original_row, (0, 0))
    preview.alpha_composite(normalized_row, (0, original_row.height))
    path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(path)


def compose_row_preview(
    image_module,
    draw_module,
    font_module,
    frames,
    metrics,
    target_bottom_y: int,
    target_center_x: int,
    row_label: str,
):
    width, height = frames[0][1].size
    cell_width = width * PREVIEW_SCALE
    cell_height = height * PREVIEW_SCALE + LABEL_HEIGHT
    label_width = 120
    preview = image_module.new(
        "RGBA",
        (label_width + cell_width * len(frames), cell_height),
        (255, 255, 255, 255),
    )
    draw = draw_module.Draw(preview)
    font = font_module.load_default()
    draw.text((10, 10), row_label, fill=(20, 20, 20, 255), font=font)

    for index, ((path, image), metric) in enumerate(zip(frames, metrics)):
        origin_x = label_width + index * cell_width
        draw_checkerboard(draw, origin_x, LABEL_HEIGHT, cell_width, height * PREVIEW_SCALE)
        scaled = image.resize((cell_width, height * PREVIEW_SCALE), image_module.Resampling.NEAREST)
        preview.alpha_composite(scaled, (origin_x, LABEL_HEIGHT))

        ground_y = LABEL_HEIGHT + target_bottom_y * PREVIEW_SCALE
        center_x = origin_x + target_center_x * PREVIEW_SCALE
        draw.line((origin_x, ground_y, origin_x + cell_width, ground_y), fill=(220, 0, 0, 255), width=2)
        draw.line((center_x, LABEL_HEIGHT, center_x, LABEL_HEIGHT + height * PREVIEW_SCALE), fill=(0, 120, 255, 255), width=2)

        if metric.bbox is not None and metric.bottom_alpha_y is not None:
            left, top, right, bottom = metric.bbox
            bbox = (
                origin_x + left * PREVIEW_SCALE,
                LABEL_HEIGHT + top * PREVIEW_SCALE,
                origin_x + right * PREVIEW_SCALE,
                LABEL_HEIGHT + bottom * PREVIEW_SCALE,
            )
            bottom_y = LABEL_HEIGHT + metric.bottom_alpha_y * PREVIEW_SCALE
            draw.rectangle(bbox, outline=(255, 170, 0, 255), width=2)
            draw.line((origin_x, bottom_y, origin_x + cell_width, bottom_y), fill=(0, 70, 220, 255), width=2)

        draw.rectangle(
            (origin_x, LABEL_HEIGHT, origin_x + cell_width - 1, LABEL_HEIGHT + height * PREVIEW_SCALE - 1),
            outline=(160, 160, 160, 255),
            width=1,
        )
        draw.text((origin_x + 6, 8), path.name, fill=(20, 20, 20, 255), font=font)

    return preview


def draw_checkerboard(draw, x: int, y: int, width: int, height: int) -> None:
    square = 16
    for cy in range(y, y + height, square):
        for cx in range(x, x + width, square):
            color = (238, 238, 238, 255) if ((cx - x) // square + (cy - y) // square) % 2 else (255, 255, 255, 255)
            draw.rectangle((cx, cy, min(cx + square - 1, x + width), min(cy + square - 1, y + height)), fill=color)


def print_report(metrics: list[FrameMetrics]) -> None:
    print("Bear walk-cycle diagnostics")
    print()
    for metric in metrics:
        margins = metric.margins
        print(f"file: {relative(metric.path)}")
        print(f"  image size: {metric.size[0]}x{metric.size[1]}")
        print(f"  alpha exists: {'yes' if metric.has_alpha else 'no'}")
        print(f"  visible bbox: {metric.bbox}")
        print(f"  visible width: {metric.visible_width}")
        print(f"  visible height: {metric.visible_height}")
        print(f"  bottom alpha y: {metric.bottom_alpha_y}")
        print(f"  center x: {metric.center_x}")
        if margins is None:
            print("  margins left/right/top/bottom: none")
        else:
            print(
                "  margins left/right/top/bottom: "
                f"{margins[0]}/{margins[1]}/{margins[2]}/{margins[3]}"
            )
        print()


def relative(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


if __name__ == "__main__":
    raise SystemExit(main())
