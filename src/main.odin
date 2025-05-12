package main

import "./sgl"
import "core:log"
import "core:fmt"
import "core:os"
import "core:mem"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

ODIN_DEBUG :: true

Game :: struct {
    camera: sgl.FPSCamera,
    sgl: sgl.Context,
}
g : Game

cube_verts := [?]f32 {
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 

    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,

    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,

     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,

    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,

    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0
}

cube_positions := [?]Vec3 {
    { 0.0,  0.0,  0.0 }, 
    { 2.0,  5.0, -15.0 }, 
    {-1.5, -2.2, -2.5 },  
    {-3.8, -2.0, -12.3 },  
    { 2.4, -0.4, -3.5 },  
    {-1.7,  3.0, -7.5 },  
    { 1.3, -2.0, -2.5 },  
    { 1.5,  2.0, -2.5 }, 
    { 1.5,  0.2, -1.5 }, 
    {-1.3,  1.0, -1.5 } ,
}
 
run :: proc() {
    g.sgl = sgl.init(800, 600, "learn opengl")
    defer sgl.deinit(&g.sgl)

    simple_shader := sgl.loadShaderFromFile("./shaders/object_vert.glsl", "./shaders/object_frag.glsl")
    light_shader := sgl.loadShaderFromFile("./shaders/light_vert.glsl", "./shaders/light_frag.glsl")

    // container_tex := sgl.loadTexture2D("./assets/container.jpg")
    // face_tex := sgl.loadTexture2D("./assets/awesomeface.png")

    vbo: u32
    vao: u32
    cube_stride : i32 = 6 * size_of(f32)
    // ebo: u32
    { // CUBE INIT
        gl.GenBuffers(1, &vbo)
        gl.GenVertexArrays(1, &vao)

        gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
        gl.BufferData(gl.ARRAY_BUFFER, size_of(cube_verts), &cube_verts, gl.STATIC_DRAW)

        gl.BindVertexArray(vao);
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, cube_stride, 0);
        gl.EnableVertexAttribArray(0)  
        gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, cube_stride, 3 * size_of(f32))
        gl.EnableVertexAttribArray(1)
    }

    light_vao: u32
    { // LIGHT INIT
        gl.GenVertexArrays(1, &light_vao)

        gl.BindVertexArray(light_vao)
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, cube_stride, 0);
        gl.EnableVertexAttribArray(0)  
    }

    g.camera = sgl.makeFPSCamera(
        sgl.getScreenWidth(g.sgl),
        sgl.getScreenHeight(g.sgl),
        fov = 45,
    )

    box_color : Vec3 = {0.4, 0.4, 0.4}
    light_color : Vec3 = {0.8, 1, 0.8}
    light_pos : Vec3 = {0, 0, 5}

    for !sgl.isWindowShouldClose(g.sgl) {
        defer sgl.finishFrame(&g.sgl)

        // input handling
        updateFPSCamera()

        // update simulation
        light_color.r = f32(math.sin(sgl.getTime()) / 2 + 0.5)
        background_color := light_color * 0.1
        light_pos.z = f32(math.sin(sgl.getTime()) * 5)
        light_pos.x = f32(math.cos(sgl.getTime()) * 5)
        // light_pos = g.camera.base.pos

        // drawing
        sgl.clearScreen(background_color.r, background_color.g, background_color.b, 1)


        projection := sgl.makePerspectiveMat4(
            g.camera.base.fov,
            f32(sgl.getScreenWidth(g.sgl)) / f32(sgl.getScreenHeight(g.sgl)),
            g.camera.base.near_frustum,
            g.camera.base.far_frustum,
        );
        view := sgl.makeViewMatrix(g.camera.base.pos, g.camera.base.front, g.camera.base.up);
        
        { // DRAW CUBES
            sgl.useShader(simple_shader)

            sgl.setUniformVec3(simple_shader, "light_color", light_color)
            sgl.setUniformVec3(simple_shader, "light_pos", light_pos)
            sgl.setUniformVec3(simple_shader, "object_color", box_color)

            gl.BindVertexArray(vao)
            for pos, i in cube_positions {
                angle := f32(i) * 20.0
                model := sgl.makeTranslateMat4({pos.x, pos.y, -pos.z}) * sgl.makeRotationMat4(angle, {-1, -0.3, 0.5}) 
                transform := projection * view * model
                normal_mat := Mat3(linalg.transpose(linalg.inverse(model)));  
                sgl.setUniformMat4(simple_shader, "transform", transform)
                sgl.setUniformMat4(simple_shader, "model", model)
                sgl.setUniformMat3(simple_shader, "u_normal", normal_mat)
                sgl.setUniformVec3(simple_shader, "u_view_pos", g.camera.base.pos)
                gl.DrawArrays(gl.TRIANGLES, 0, 36)
            }
            gl.BindVertexArray(0)
        }

        { // DRAW LIGHT
            sgl.useShader(light_shader)
            model := sgl.makeTranslateMat4(light_pos) 
            transform := projection * view * model
            sgl.setUniformMat4(light_shader, "transform", transform)
            sgl.setUniformVec3(light_shader, "light_color", light_color)
            gl.BindVertexArray(vao)
            gl.DrawArrays(gl.TRIANGLES, 0, 36)
            gl.BindVertexArray(0)
        }
    }
}

updateFPSCamera :: proc() {
    dir : sgl.Direction3DSet
    if sgl.isButtonDown(g.sgl, .W) do dir += { .Forward }
    if sgl.isButtonDown(g.sgl, .S) do dir += { .Backward }
    if sgl.isButtonDown(g.sgl, .A) do dir += { .Left }
    if sgl.isButtonDown(g.sgl, .D) do dir += { .Right }
    if sgl.isButtonDown(g.sgl, .SPACE) do dir += { .Up }
    if sgl.isButtonDown(g.sgl, .LSHIFT) do dir += { .Down }
    sgl.updateFPSCameraPosition(&g.camera, sgl.getDelta(g.sgl), dir)
    sgl.updateFPSCameraRotation(&g.camera, sgl.getMouseDeltaX(g.sgl), sgl.getMouseDeltaY(g.sgl))
    sgl.updateFPSCamera(&g.camera)
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				log.errorf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					log.errorf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				log.errorf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					log.errorf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
    context.logger = log.create_console_logger()

    run()
}
