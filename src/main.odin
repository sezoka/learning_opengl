package main

import "./sgl"
import "core:log"
import "core:fmt"
import "core:os"
import "core:mem"
import gl "vendor:OpenGL"

ODIN_DEBUG :: true

Game :: struct {
    sgl: sgl.Context,
}
g : Game

triangle_verts := [?]f32 {
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0
};  

run :: proc() {
    g.sgl = sgl.init(800, 600, "learn opengl")
    defer sgl.deinit(&g.sgl)

    simple_shader := sgl.loadShaderFromFile("./shaders/vertex_shader.glsl", "./shaders/frag_shader.glsl")

    vbo : u32
    vao: u32
    { // TRIANGLE INIT
        gl.GenBuffers(1, &vbo)
        gl.GenVertexArrays(1, &vao)

        gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
        gl.BufferData(gl.ARRAY_BUFFER, size_of(triangle_verts), &triangle_verts, gl.STATIC_DRAW)

        gl.BindVertexArray(vao);
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0);
        gl.EnableVertexAttribArray(0);  
    }


    for !sgl.isWindowShouldClose(g.sgl) {
        defer sgl.finishFrame(&g.sgl)

        sgl.clearScreen(0.2, 0.2, 0.2, 1)

        sgl.useShader(simple_shader)
        gl.BindVertexArray(vao);
        gl.DrawArrays(gl.TRIANGLES, 0, 3)
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
