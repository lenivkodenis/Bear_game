#!/usr/bin/env python3
"""Validate the temporary flat-baseline level geometry."""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
GEOMETRY_PATH = REPO_ROOT / "assets/data/level_geometry.json"

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

    print("level_geometry.json OK: 10 flat baseline levels are stable.")


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

    player_spawn = required_object(level, "playerSpawn", context)
    mentor_position = required_object(level, "mentorPosition", context)
    grounds = read_colliders(level, "groundColliders", context)
    platforms = read_colliders(level, "platformColliders", context)
    obstacles = read_colliders(level, "obstacleColliders", context)
    notes = required_string(level, "notes", context)

    if "flat baseline" not in notes:
        fail(f"{context}: notes must identify the temporary flat baseline.")
    if len(grounds) != 1:
        fail(f"{context}: baseline requires exactly one main ground collider.")
    if platforms:
        fail(f"{context}: baseline platformColliders must be empty.")
    if obstacles:
        fail(f"{context}: baseline obstacleColliders must be empty.")

    ground = grounds[0]
    if ground["id"] != "main_ground":
        fail(f"{context}: baseline ground id must be main_ground.")
    validate_collider_bounds(ground, context, world_width, world_height)
    if ground["x"] != 0 or ground["width"] != world_width:
        fail(f"{context}: main ground must span the full world width.")

    validate_point(player_spawn, context, "playerSpawn", world_width, world_height)
    validate_point(mentor_position, context, "mentorPosition", world_width, world_height)

    player_x = required_number(player_spawn, "x", f"{context}.playerSpawn")
    player_y = required_number(player_spawn, "y", f"{context}.playerSpawn")
    mentor_x = required_number(mentor_position, "x", f"{context}.mentorPosition")
    mentor_y = required_number(mentor_position, "y", f"{context}.mentorPosition")

    if mentor_x <= player_x:
        fail(f"{context}: mentorPosition.x must be greater than playerSpawn.x.")
    if abs(player_y - ground["y"]) > 1:
        fail(f"{context}: playerSpawn must sit on main ground.")
    if abs(mentor_y - ground["y"]) > 1:
        fail(f"{context}: mentorPosition must sit on main ground.")


def validate_point(
    point: dict[str, object],
    context: str,
    key: str,
    world_width: float,
    world_height: float,
) -> None:
    x = required_number(point, "x", f"{context}.{key}")
    y = required_number(point, "y", f"{context}.{key}")
    if x < 0 or x > world_width:
        fail(f"{context}: {key}.x is outside the world.")
    if y < 0 or y > world_height:
        fail(f"{context}: {key}.y is outside the world.")


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
