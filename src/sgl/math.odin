package sgl

import "core:math"
import "core:math/linalg"

Vec3 :: [3]f32
Vec4 :: [4]f32
Mat4 :: matrix[4,4]f32
Mat3 :: matrix[3,3]f32

// maps objects in camera view onto 2d screen
makePerspectiveMat4 :: #force_inline proc(
    fov: f32,
    aspect_ratio: f32,
    near_frustum, far_frustum: f32,
    flip_z_axis := false, // left-handed
) -> Mat4 {
    return linalg.matrix4_perspective_f32(
        math.to_radians_f32(fov),
        aspect_ratio,
        near_frustum,
        far_frustum,
        flip_z_axis,
    )
}

// moves objects to camera view
makeViewMatrix :: #force_inline proc(pos: Vec3, front, up: Vec3) -> Mat4 {
    return makeLookAtMat4(
        pos,
        pos + front,
        up,
    )
}

makeLookAtMat4 :: proc(eye: Vec3, target: Vec3, up: Vec3) -> Mat4 {
    z := linalg.normalize(target - eye)
    x := linalg.normalize(linalg.cross(up, z))
    y := linalg.cross(z, x)

    return matrix[4, 4]f32{
        x.x, x.y, x.z, -linalg.dot(x, eye), 
        y.x, y.y, y.z, -linalg.dot(y, eye), 
        z.x, z.y, z.z, -linalg.dot(z, eye), 
        0, 0, 0, 1, 
    }
}

// locates object in world
// makeModelMat4 :: #force_inline proc(
//     model_position, rotation_vector: Vec3,
//     rotation_angle, scale: f32,
// ) -> Mat4 {
//     return(
//         linalg.matrix4_translate_f32(model_position) *
//         linalg.matrix4_rotate_f32(
//             math.to_radians_f32(rotation_angle),
//             rotation_vector,
//         ) *
//         linalg.matrix4_scale_f32(scale) \
//     )
// }

makeTranslateMat4 :: proc(v: Vec3) -> Mat4 {
    return {
        1, 0, 0, v.x, 
        0, 1, 0, v.y, 
        0, 0, 1, v.z, 
        0, 0, 0, 1, 
    }
}

@(require_results)
makeRotationMat4 :: #force_inline proc(angle: f32, rotation_vec: Vec3) -> Mat4 {
    return linalg.matrix4_rotate_f32(math.to_radians(angle), rotation_vec)
}
