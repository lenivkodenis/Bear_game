#!/usr/bin/env python3
"""Basic safety checks for playable level geometry."""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
GEOMETRY_PATH = REPO_ROOT / "assets/data/level_geometry.json"

PLAYER_HITBOX_WIDTH = 78
PLAYER_HITBOX_HEIGHT = 92
MENTOR_WIDTH = 56
MENTOR_HEIGHT = 64

MAX_SAFE_OBSTACLE_HEIGHT = 48
MAX_SAFE_PLATFORM_CLIMB = 60
MAX_SAFE_PLATFORM_GAP = 130
MIN_LANDING_WIDTH = 96

EXPECTED_BACKGROUNDS = {
    1: "assets/images/levels/level_01_ice_floe/background.png",
    2: "assets/images/levels/level_02_icy_river/background.png",
    3: "assets/images/levels/level_03_snowy_shore/background.png",
    4: "assets/images/levels/level_04_northern_forest/background.png",
    5: "assets/images/levels/level_05_ice_cave/background.png",
    6: "assets/images/levels/level_06_snowy_valley/background.png",
    7: "assets/images/levels/level_07_mountain_pass/background.png",
    8: "assets/images/levels/level_08_polar_night/background.png",
    9: "assets/images/levels/level_09_northern_lights/background.png",
    10: "assets/images/levels/level_10_northern_ocean/background.png",
}


class GeometryError(Exception):
    pass


def main() -> None:
    data = json.loads(GEOMETRY_PATH.read_text(encoding="utf-8"))
    world = required_object(data, "world", "root")
    world_width = required_number(world, "width", "world")
    world_height = required_number(world, "height", "world")
    levels = required_list(data, "levels", "root")

    if len(levels) != 10:
        fail(f"Expected 10 levels, found {len(levels)}.")

    seen_ids: set[int] = set()
    for raw_level in levels:
        level = as_object(raw_level, "level entry")
        level_id = required_int(level, "levelId", "level")
        if level_id in seen_ids:
            fail(f"Duplicate levelId {level_id}.")
        seen_ids.add(level_id)
        validate_level(level, level_id, world_width, world_height)

    missing = set(EXPECTED_BACKGROUNDS) - seen_ids
    if missing:
        fail(f"Missing geometry for levels: {sorted(missing)}.")

    print("level_geometry.json OK: 10 playable routes passed basic checks.")


def validate_level(
    level: dict[str, object],
    level_id: int,
    world_width: float,
    world_height: float,
) -> None:
    context = f"level {level_id}"
    background = required_string(level, "backgroundAsset", context)
    if background != EXPECTED_BACKGROUNDS.get(level_id):
        fail(f"{context}: unexpected background asset {background!r}.")
    if not (REPO_ROOT / background).exists():
        fail(f"{context}: background asset does not exist: {background}.")

    notes = required_string(level, "notes", context)
    if len(notes) < 16:
        fail(f"{context}: route notes are too short.")

    player_spawn = required_object(level, "playerSpawn", context)
    mentor_position = required_object(level, "mentorPosition", context)
    ground = read_colliders(level, "groundColliders", context)
    platforms = read_colliders(level, "platformColliders", context)
    obstacles = read_colliders(level, "obstacleColliders", context)
    walkables = ground + platforms

    if not ground:
        fail(f"{context}: at least one ground collider is required.")
    if not platforms and not obstacles:
        fail(f"{context}: at least one obstacle or platform is required.")
    if level_id == 5 and len(walkables) < 5:
        fail(f"{context}: ice cave must have at least five walkable surfaces.")

    for collider in walkables + obstacles:
        validate_collider_bounds(collider, context, world_width, world_height)

    assert_supported_point(
        player_spawn,
        PLAYER_HITBOX_WIDTH,
        walkables,
        f"{context}: playerSpawn",
    )
    assert_supported_point(
        mentor_position,
        MENTOR_WIDTH,
        walkables,
        f"{context}: mentorPosition",
    )

    for obstacle in obstacles:
        if obstacle["height"] > MAX_SAFE_OBSTACLE_HEIGHT:
            fail(
                f"{context}: obstacle {obstacle['id']} is too tall "
                f"({obstacle['height']} > {MAX_SAFE_OBSTACLE_HEIGHT})."
            )
        assert_obstacle_sits_on_surface(obstacle, walkables, context)

    validate_platform_route(walkables, context)


def validate_platform_route(
    walkables: list[dict[str, float | str]],
    context: str,
) -> None:
    ordered = sorted(walkables, key=lambda collider: collider["x"])

    for index, platform in enumerate(ordered):
        if platform["width"] < MIN_LANDING_WIDTH:
            fail(
                f"{context}: walkable surface {platform['id']} is too narrow "
                f"({platform['width']} < {MIN_LANDING_WIDTH})."
            )

        if index == 0:
            continue

        previous = ordered[index - 1]
        upward_climb = previous["y"] - platform["y"]
        if upward_climb > MAX_SAFE_PLATFORM_CLIMB:
            fail(
                f"{context}: route climbs too high from {previous['id']} "
                f"to {platform['id']} ({upward_climb})."
            )

        horizontal_gap = platform["x"] - (previous["x"] + previous["width"])
        if horizontal_gap > MAX_SAFE_PLATFORM_GAP:
            fail(
                f"{context}: route gap is too wide from {previous['id']} "
                f"to {platform['id']} ({horizontal_gap})."
            )


def assert_supported_point(
    point: dict[str, object],
    body_width: float,
    walkables: list[dict[str, float | str]],
    context: str,
) -> None:
    x = required_number(point, "x", context)
    y = required_number(point, "y", context)
    body_center_x = x + body_width / 2

    for surface in walkables:
        if (
            surface["x"] <= body_center_x <= surface["x"] + surface["width"]
            and abs(y - surface["y"]) <= 1
        ):
            return

    fail(f"{context}: point is not on a walkable surface.")


def assert_obstacle_sits_on_surface(
    obstacle: dict[str, float | str],
    walkables: list[dict[str, float | str]],
    context: str,
) -> None:
    obstacle_center_x = obstacle["x"] + obstacle["width"] / 2
    obstacle_bottom = obstacle["y"] + obstacle["height"]

    for surface in walkables:
        if (
            surface["x"] <= obstacle_center_x <= surface["x"] + surface["width"]
            and abs(obstacle_bottom - surface["y"]) <= 1
        ):
            return

    fail(f"{context}: obstacle {obstacle['id']} is not sitting on a surface.")


def validate_collider_bounds(
    collider: dict[str, float | str],
    context: str,
    world_width: float,
    world_height: float,
) -> None:
    if collider["width"] <= 0 or collider["height"] <= 0:
        fail(f"{context}: collider {collider['id']} must have positive size.")
    if collider["x"] < 0 or collider["y"] < 0:
        fail(f"{context}: collider {collider['id']} starts outside the world.")
    if collider["x"] + collider["width"] > world_width:
        fail(f"{context}: collider {collider['id']} exceeds world width.")
    if collider["y"] + collider["height"] > world_height:
        fail(f"{context}: collider {collider['id']} exceeds world height.")


def read_colliders(
    level: dict[str, object],
    key: str,
    context: str,
) -> list[dict[str, float | str]]:
    colliders = []
    for index, raw_collider in enumerate(required_list(level, key, context)):
        collider_context = f"{context} {key}[{index}]"
        collider = as_object(raw_collider, collider_context)
        colliders.append(
            {
                "id": required_string(collider, "id", collider_context),
                "x": required_number(collider, "x", collider_context),
                "y": required_number(collider, "y", collider_context),
                "width": required_number(collider, "width", collider_context),
                "height": required_number(collider, "height", collider_context),
            }
        )
    return colliders


def required_object(
    data: dict[str, object],
    key: str,
    context: str,
) -> dict[str, object]:
    return as_object(data.get(key), f"{context}.{key}")


def required_list(
    data: dict[str, object],
    key: str,
    context: str,
) -> list[object]:
    value = data.get(key)
    if isinstance(value, list):
        return value
    fail(f"{context}: missing list {key!r}.")


def required_string(data: dict[str, object], key: str, context: str) -> str:
    value = data.get(key)
    if isinstance(value, str) and value.strip():
        return value
    fail(f"{context}: missing non-empty string {key!r}.")


def required_int(data: dict[str, object], key: str, context: str) -> int:
    value = data.get(key)
    if isinstance(value, int):
        return value
    fail(f"{context}: missing integer {key!r}.")


def required_number(data: dict[str, object], key: str, context: str) -> float:
    value = data.get(key)
    if isinstance(value, (int, float)):
        return float(value)
    fail(f"{context}: missing number {key!r}.")


def as_object(value: object, context: str) -> dict[str, object]:
    if isinstance(value, dict):
        return value
    fail(f"{context}: expected object.")


def fail(message: str) -> None:
    raise GeometryError(message)


if __name__ == "__main__":
    main()
