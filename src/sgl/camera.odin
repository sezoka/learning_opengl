package sgl

import "core:fmt"
import "core:math"
import "core:math/linalg"

DEFAULT_YAW: f32 : 90

DEFAULT_PITCH: f32 : 0
DEFAULT_SPEED :: 3
DEFAULT_FOV :: 90

Direction3D :: enum {
    Forward,
    Backward,
    Left,
    Right,
    Up,
    Down,
}

Direction3DSet :: bit_set[Direction3D]

Camera :: struct {
    fov:          f32,
    pos:          Vec3,
    front:        Vec3,
    up:           Vec3,
    near_frustum: f32,
    far_frustum:  f32,
    right:          Vec3,
    world_up:       Vec3,
    yaw:            f32,
    pitch:          f32,
    ctx: ^Context,
}

updateFPSCameraPosition :: proc(
    c: ^FPSCamera,
    dt: f32,
    direction: Direction3DSet,
) {
    dir: Vec3
    flat_front := linalg.normalize(Vec3{c.base.front.x, 0, c.base.front.z})
    if .Forward in direction do dir += flat_front
    if .Backward in direction do dir -= flat_front
    if .Left in direction do dir -= c.base.right
    if .Right in direction do dir += c.base.right
    if .Up in direction do dir.y += 1
    if .Down in direction do dir.y -= 1
    if dir != {} {
        c.base.pos += DEFAULT_SPEED * dt * linalg.normalize(dir)
    }
}

updateFPSCameraRotation :: proc(c: ^FPSCamera, xoffs, yoffs: f32) {
    xoffs, yoffs := xoffs, yoffs

    xoffs *= c.mouse_sens
    yoffs *= c.mouse_sens

    c.base.yaw -= xoffs
    c.base.pitch -= yoffs

    if c.base.pitch > 89.0 do c.base.pitch = 89.0
    if c.base.pitch < -89.0 do c.base.pitch = -89.0
}

updateCamera :: proc(c: ^Camera) {
    // calculate the new Front vector
    c.front = calculateCameraFront(c)
    // also re-calculate the Right and Up vector
    c.right = linalg.normalize(linalg.cross(c.world_up, c.front)) // normalize the vectors, because their length gets closer to 0 the more you look up or down which results in slower movement.
    c.up = linalg.normalize(linalg.cross(c.front, c.right))
}

updateFPSCamera :: proc(c: ^FPSCamera) {
    updateCamera(&c.base)
}

calculateCameraFront :: proc(c: ^Camera) -> Vec3 {
    front := linalg.normalize(
        Vec3 {
            math.cos(math.to_radians(c.yaw)) *
            math.cos(math.to_radians(c.pitch)),
            math.sin(math.to_radians(c.pitch)),
            math.sin(math.to_radians(c.yaw)) *
            math.cos(math.to_radians(c.pitch)),
        },
    )
    return front
}

FPSCamera :: struct {
    base:     Camera,
    movement_speed: f32,
    mouse_sens:     f32,
    speed:          f32,
}

makeFPSCamera :: proc(
    ctx: ^Context,
    pos := Vec3{0, 0, 0},
    world_up := Vec3{0, 1, 0},
    yaw := DEFAULT_YAW,
    pitch := DEFAULT_PITCH,
    near_frustum: f32 = 0.01,
    far_frustum: f32 = 100,
    fov: f32 = DEFAULT_FOV,
    mouse_sensitivity: f32 = 0.1,
) -> (
    camera: FPSCamera,
) {
    camera = FPSCamera {
        base = {
            pos          = pos,
            world_up     = world_up,
            yaw          = yaw,
            pitch        = pitch,
            fov          = fov,
            near_frustum = near_frustum,
            far_frustum  = far_frustum,
            ctx = ctx,
        },
        mouse_sens   = mouse_sensitivity,
    }
    updateFPSCamera(&camera)
    return camera
}

updateFPSCameraDefault :: proc(camera: ^FPSCamera) {
    ctx := camera.base.ctx^
    dir : Direction3DSet
    if isKeyDown(ctx, .W) do dir += { .Forward }
    if isKeyDown(ctx, .S) do dir += { .Backward }
    if isKeyDown(ctx, .A) do dir += { .Left }
    if isKeyDown(ctx, .D) do dir += { .Right }
    if isKeyDown(ctx, .SPACE) do dir += { .Up }
    if isKeyDown(ctx, .LSHIFT) do dir += { .Down }
    updateFPSCameraPosition(camera, getDelta(ctx), dir)
    updateFPSCameraRotation(camera, getMouseDeltaX(ctx), getMouseDeltaY(ctx))
    updateFPSCamera(camera)
}

makeViewMatrixForCamera :: proc(camera: Camera) -> Mat4 {
    return makeViewMatrix(camera.pos, camera.front, camera.up)
}
