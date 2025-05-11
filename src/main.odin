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
    sgl: sgl.Context,
}
g : Game

triangle_verts := [?]f32 {
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0
};

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

    simple_shader := sgl.loadShaderFromFile("./shaders/vertex_shader.glsl", "./shaders/frag_shader.glsl")

    container_tex := sgl.loadTexture2D("./assets/container.jpg")
    face_tex := sgl.loadTexture2D("./assets/awesomeface.png")

    // fmt.println(container_tex.format, face_tex.format)

    vbo: u32
    vao: u32
    // ebo: u32
    { // TRIANGLE INIT
        gl.GenBuffers(1, &vbo)
        gl.GenVertexArrays(1, &vao)
        // gl.GenBuffers(1, &ebo)

        gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
        gl.BufferData(gl.ARRAY_BUFFER, size_of(triangle_verts), &triangle_verts, gl.STATIC_DRAW)

        gl.BindVertexArray(vao);
        stride : i32 = 5 * size_of(f32)
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, 0);
        gl.EnableVertexAttribArray(0)  
        gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, stride, 3 * size_of(f32))
        gl.EnableVertexAttribArray(1)

        // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
        // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(triangle_indices), &triangle_indices, gl.STATIC_DRAW);
    }


    for !sgl.isWindowShouldClose(g.sgl) {
        defer sgl.finishFrame(&g.sgl)

        sgl.clearScreen(0.2, 0.3, 0.3, 1)

        sgl.useShader(simple_shader)
        green_value := f32(math.sin(sgl.getTime())) / 2 + 0.5
        sgl.setUniformVec4(simple_shader, "u_color", {0, green_value, 0, 1})

        projection := sgl.makePerspectiveMat4(
            45,
            f32(sgl.getScreenWidth(&g.sgl)) / f32(sgl.getScreenHeight(&g.sgl)),
            0.1,
            100.0
        );
        view := sgl.makeTranslateMat4({ 0.0, 0.0, 3.0 });

        sgl.setUniformTexture2D(simple_shader, "texture1", container_tex, 0)
        sgl.setUniformTexture2D(simple_shader, "texture2", face_tex, 1)

        gl.BindVertexArray(vao)
        for pos, i in cube_positions {
            angle := f32(i) * 20.0
            model := sgl.makeTranslateMat4({pos.x, pos.y, -pos.z}) * sgl.makeRotationMat4(angle, {-1, -0.3, 0.5}) 
            transform := projection * view * model
            sgl.setUniformMat4(simple_shader, "transform", transform)
            gl.DrawArrays(gl.TRIANGLES, 0, 36)
        }
        gl.BindVertexArray(0)
    }
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
