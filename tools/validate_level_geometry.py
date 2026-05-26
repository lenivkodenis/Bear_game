#!/usr/bin/env python3
"""Validate production per-level geometry and the first active obstacle."""

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

EXPECTED_GROUND_Y = {
    1: 489,
    2: 460,
    3: 460,
    4: 498,
    5: 409,
    6: 506,
    7: 464,
    8: 485,
    9: 477,
    10: 519,
}

MIN_PREVIEW_WIDTH = 50
MAX_PREVIEW_WIDTH = 160
MIN_PREVIEW_HEIGHT = 20
MAX_PREVIEW_HEIGHT = 70
EXPECTED_LEVEL_ONE_OBSTACLE = {
    "id": "ice_ridge_1",
    "x": 537.70,
    "y": 459,
    "width": 90,
    "height": 30,
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
    ground_y_values: list[float] = []
    for raw_level in levels:
        level = as_object(raw_level, "level entry")
        level_id = required_int(level, "levelId", "level")
        if level_id in seen_ids:
            fail(f"Duplicate levelId {level_id}.")
        seen_ids.add(level_id)
        ground_y_values.append(
            validate_level(level, level_id, world_width, world_height)
        )

    missing = set(EXPECTED_BACKGROUNDS) - seen_ids
    if missing:
        fail(f"Missing geometry for levels: {sorted(missing)}.")
    if len(set(ground_y_values)) <= 1:
        fail("Expected per-level groundY values, found one shared baseline.")

    assert_no_forbidden_keys(data)

    print(
        "level_geometry.json OK: 10 per-level calibrated levels, "
        "one active level 1 obstacle, no platforms."
    )


def validate_level(
    level: dict[str, object],
    level_id: int,
    world_width: float,
    world_height: float,
) -> float:
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
    calibration_obstacles = read_calibration_obstacles(level, context)
    notes = required_string(level, "notes", context)

    if "flat baseline" not in notes:
        fail(f"{context}: notes must identify the temporary flat baseline.")
    if len(grounds) != 1:
        fail(f"{context}: baseline requires exactly one main ground collider.")
    if platforms:
        fail(f"{context}: baseline platformColliders must be empty.")
    if level_id == 1:
        validate_level_one_obstacle(
            obstacles,
            context=context,
            ground=grounds[0],
            player_spawn=player_spawn,
            mentor_position=mentor_position,
            world_width=world_width,
            world_height=world_height,
        )
    elif obstacles:
        fail(f"{context}: baseline obstacleColliders must be empty.")
    if calibration_obstacles:
        fail(f"{context}: calibration previews must be removed after activation.")

    ground = grounds[0]
    if ground["id"] != "main_ground":
        fail(f"{context}: baseline ground id must be main_ground.")
    validate_collider_bounds(ground, context, world_width, world_height)
    if ground["x"] != 0 or ground["width"] != world_width:
        fail(f"{context}: main ground must span the full world width.")

    expected_ground_y = EXPECTED_GROUND_Y.get(level_id)
    if expected_ground_y is None:
        fail(f"{context}: missing expected per-level groundY.")
    if not same_number(ground["y"], expected_ground_y):
        fail(
            f"{context}: main_ground.y must equal approved per-level "
            f"groundY {expected_ground_y}."
        )

    expected_ground_height = world_height - ground["y"]
    if not same_number(ground["height"], expected_ground_height):
        fail(
            f"{context}: main_ground.height must keep the ground rectangle "
            f"ending at the bottom of the design world."
        )

    validate_point(player_spawn, context, "playerSpawn", world_width, world_height)
    validate_point(mentor_position, context, "mentorPosition", world_width, world_height)

    player_x = required_number(player_spawn, "x", f"{context}.playerSpawn")
    player_y = required_number(player_spawn, "y", f"{context}.playerSpawn")
    mentor_x = required_number(mentor_position, "x", f"{context}.mentorPosition")
    mentor_y = required_number(mentor_position, "y", f"{context}.mentorPosition")

    if mentor_x <= player_x:
        fail(f"{context}: mentorPosition.x must be greater than playerSpawn.x.")
    if not same_number(player_y, ground["y"]):
        fail(f"{context}: playerSpawn.y must equal main_ground.y.")
    if not same_number(mentor_y, ground["y"]):
        fail(f"{context}: mentorPosition.y must equal main_ground.y.")

    validate_calibration_obstacles(
        calibration_obstacles,
        level_id=level_id,
        context=context,
        ground=ground,
        player_x=player_x,
        player_y=player_y,
        mentor_x=mentor_x,
        mentor_y=mentor_y,
        world_width=world_width,
        world_height=world_height,
    )

    return ground["y"]


def validate_level_one_obstacle(
    obstacles: list[dict[str, float | str]],
    *,
    context: str,
    ground: dict[str, float | str],
    player_spawn: dict[str, object],
    mentor_position: dict[str, object],
    world_width: float,
    world_height: float,
) -> None:
    if len(obstacles) != 1:
        fail(f"{context}: level 1 must contain exactly one obstacleCollider.")

    obstacle = obstacles[0]
    obstacle_context = f"{context} obstacle"
    if obstacle["id"] != EXPECTED_LEVEL_ONE_OBSTACLE["id"]:
        fail(f"{obstacle_context}: id must be ice_ridge_1.")
    for key in ("x", "y", "width", "height"):
        if not same_number(float(obstacle[key]), EXPECTED_LEVEL_ONE_OBSTACLE[key]):
            fail(
                f"{obstacle_context}: {key} must equal "
                f"{EXPECTED_LEVEL_ONE_OBSTACLE[key]}."
            )

    validate_collider_bounds(obstacle, obstacle_context, world_width, world_height)
    expected_y = float(ground["y"]) - float(obstacle["height"])
    if not same_number(float(obstacle["y"]), expected_y):
        fail(f"{obstacle_context}: y must equal main_ground.y - height.")

    player_x = required_number(player_spawn, "x", f"{context}.playerSpawn")
    player_y = required_number(player_spawn, "y", f"{context}.playerSpawn")
    mentor_x = required_number(mentor_position, "x", f"{context}.mentorPosition")
    mentor_y = required_number(mentor_position, "y", f"{context}.mentorPosition")

    obstacle_left = float(obstacle["x"])
    obstacle_right = obstacle_left + float(obstacle["width"])
    if obstacle_left <= player_x or obstacle_right >= mentor_x:
        fail(f"{obstacle_context}: obstacle must be between spawn and mentor.")
    if point_intersects_rect(player_x, player_y, obstacle):
        fail(f"{obstacle_context}: obstacle must not intersect playerSpawn.")
    if point_intersects_rect(mentor_x, mentor_y, obstacle):
        fail(f"{obstacle_context}: obstacle must not intersect mentorPosition.")


def validate_calibration_obstacles(
    calibration_obstacles: list[dict[str, float | str]],
    *,
    level_id: int,
    context: str,
    ground: dict[str, float | str],
    player_x: float,
    player_y: float,
    mentor_x: float,
    mentor_y: float,
    world_width: float,
    world_height: float,
) -> None:
    for index, preview in enumerate(calibration_obstacles):
        preview_context = f"{context} calibration preview {index + 1}"
        if preview["notes"] != "Preview only. Not used for collision.":
            fail(
                f"{preview_context}: notes must mark the preview "
                "as non-collision."
            )

        validate_collider_bounds(preview, preview_context, world_width, world_height)
        if not (MIN_PREVIEW_WIDTH <= preview["width"] <= MAX_PREVIEW_WIDTH):
            fail(
                f"{preview_context}: width must be "
                f"{MIN_PREVIEW_WIDTH}-{MAX_PREVIEW_WIDTH}."
            )
        if not (MIN_PREVIEW_HEIGHT <= preview["height"] <= MAX_PREVIEW_HEIGHT):
            fail(
                f"{preview_context}: height must be "
                f"{MIN_PREVIEW_HEIGHT}-{MAX_PREVIEW_HEIGHT}."
            )

        expected_y = float(ground["y"]) - float(preview["height"])
        if not same_number(float(preview["y"]), expected_y):
            fail(f"{preview_context}: y must equal main_ground.y - height.")

        preview_left = float(preview["x"])
        preview_right = preview_left + float(preview["width"])
        if preview_left <= player_x or preview_right >= mentor_x:
            fail(
                f"{preview_context}: preview must be between playerSpawn "
                "and mentorPosition."
            )
        if point_intersects_rect(player_x, player_y, preview):
            fail(f"{preview_context}: preview must not intersect playerSpawn.")
        if point_intersects_rect(mentor_x, mentor_y, preview):
            fail(f"{preview_context}: preview must not intersect mentorPosition.")


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


def assert_no_forbidden_keys(value: object) -> None:
    forbidden = {"wrap", "worldWrap", "teleport", "resetPosition", "fallReset"}
    if isinstance(value, dict):
        for key, child in value.items():
            if key in forbidden:
                fail(f"Forbidden teleport/world-wrap config key found: {key}.")
            assert_no_forbidden_keys(child)
    elif isinstance(value, list):
        for child in value:
            assert_no_forbidden_keys(child)


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


def read_calibration_obstacles(
    level: dict[str, object],
    context: str,
) -> list[dict[str, float | str]]:
    if "calibrationObstacles" not in level:
        return []

    obstacles = []
    for index, raw_obstacle in enumerate(
        required_list(level, "calibrationObstacles", context)
    ):
        obstacle_context = f"{context} calibrationObstacles[{index}]"
        obstacle = as_object(raw_obstacle, obstacle_context)
        obstacles.append(
            {
                "id": required_string(obstacle, "id", obstacle_context),
                "x": required_number(obstacle, "x", obstacle_context),
                "y": required_number(obstacle, "y", obstacle_context),
                "width": required_number(obstacle, "width", obstacle_context),
                "height": required_number(obstacle, "height", obstacle_context),
                "notes": required_string(obstacle, "notes", obstacle_context),
            }
        )
    return obstacles


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


def same_number(left: float, right: float) -> bool:
    return abs(left - right) < 0.001


def point_intersects_rect(
    point_x: float,
    point_y: float,
    rect: dict[str, float | str],
) -> bool:
    return (
        float(rect["x"]) <= point_x <= float(rect["x"]) + float(rect["width"])
        and float(rect["y"]) <= point_y <= float(rect["y"]) + float(rect["height"])
    )


def as_object(value: object, context: str) -> dict[str, object]:
    if isinstance(value, dict):
        return value
    fail(f"{context}: expected object.")


def fail(message: str) -> None:
    raise GeometryError(message)


if __name__ == "__main__":
    main()
