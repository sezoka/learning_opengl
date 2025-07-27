package main

import "./sgl"
import "core:log"
import "core:fmt"
import "core:os"
import "core:mem"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

Game :: struct {
    camera: sgl.FPSCamera,
    sgl: sgl.Context,
}
g : Game

cube_verts := [?]f32 {
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 0.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,
     0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 0.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,

    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,  1.0, 1.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,  0.0, 0.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,  1.0, 1.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  1.0, 1.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  1.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0
}

point_light_positions := [?]Vec3 {
    {0.7,  0.2,  -2.0},
    {2.3, -3.3, 4.0},
    {-4.0,  2.0, 12.0},
    {0.0,  0.0, 3.0}
}

cube_positions := [?]Vec3 {
    { 0.0,  0.0,  0.0 }, 
    {0.4, 0, 0}, 
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
    init_options := sgl.DEFAULT_INIT_OPTIONS
    init_options.target_fps = 60
    sgl.init(&g.sgl, 1280, 720, "learn opengl", init_options)
    defer sgl.deinit()

    model := sgl.loadModel_obj(context.allocator, "./assets/obj/slayer/slayer_left.obj"); defer sgl.destroyModel(&model)
    // fmt.println(model)

    object_shader := sgl.loadShaderFromFile("./shaders/object_vert.glsl", "./shaders/object_frag.glsl")
    light_shader := sgl.loadShaderFromFile("./shaders/light_vert.glsl", "./shaders/light_frag.glsl")
    skybox_shader := sgl.loadShaderFromFile("./shaders/skybox_vert.glsl", "./shaders/skybox_frag.glsl")

    skybox_tex := sgl.loadCubeMap({
        "./assets/skybox/right.jpg",
        "./assets/skybox/left.jpg",
        "./assets/skybox/top.jpg",
        "./assets/skybox/bottom.jpg",
        "./assets/skybox/front.jpg",
        "./assets/skybox/back.jpg"
    })

    vbo: sgl.GL_BufferId
    vao: sgl.GL_VaoId
    cube_stride : i32 = 8 * size_of(f32)
    // ebo: u32
    { // CUBE INIT
        vbo = sgl.makeBuffer_gl()
        vao := sgl.makeVAO_gl()

        sgl.setVBOData_gl(vbo, cube_verts[:], .StaticDraw)

        sgl.bindVAO_gl(vao);
        gl.EnableVertexAttribArray(0)  
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, cube_stride, 0);
        gl.EnableVertexAttribArray(1)
        gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, cube_stride, 3 * size_of(f32))
        gl.EnableVertexAttribArray(2)
        gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, cube_stride, 6 * size_of(f32))
    }

    light_vao: u32
    { // LIGHT INIT
        gl.GenVertexArrays(1, &light_vao)

        gl.BindVertexArray(light_vao)
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, cube_stride, 0);
        gl.EnableVertexAttribArray(0)  
    }

    skybox_vbo: sgl.GL_BufferId
    skybox_vao: sgl.GL_VaoId
    { // SKYBOX INIT
        skybox_vbo = sgl.makeBuffer_gl()
        skybox_vao= sgl.makeVAO_gl()
        sgl.bindVAO_gl(skybox_vao); defer sgl.bindVAO_gl(0)
        sgl.setVBOData_gl(skybox_vbo, sgl.gl_skybox_vertices[:], .StaticDraw)
        gl.EnableVertexAttribArray(0)
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0);
    }

    g.camera = sgl.makeFPSCamera(fov = 90)

    model_rot : f32 = 0

    for !sgl.isWindowShouldClose() {
        defer sgl.finishFrame()

        // input handling
        updateFPSCamera()

        // update simulation
        // light_pos.z = f32(math.sin(sgl.getTime()) * 3)
        // light_pos.x = f32(math.cos(sgl.getTime()) * 3)

        // light_color.r = f32(math.sin(sgl.getTime() * 2))
        // light_color.g = f32(math.sin(sgl.getTime() * 0.7))
        // light_color.b = f32(math.sin(sgl.getTime() * 1.3))
        light_color : Vec3 = {1, 1, 1}
        diffuse_color := light_color * 1
        ambient_color := diffuse_color * 0.5
        specular_color := linalg.length(diffuse_color)

        // drawing
        sgl.clearBackground({0.05, 0.05, 0.05, 1})

        projection := sgl.makePerspectiveMat4(
            g.camera.base.fov,
            f32(sgl.getScreenWidth()) / f32(sgl.getScreenHeight()),
            g.camera.base.near_frustum,
            g.camera.base.far_frustum,
            false,
        );
        view := sgl.makeViewMatrix(g.camera.base.pos, g.camera.base.front, g.camera.base.up);

        { // DRAW SKYBOX
            // sgl.gl_disableFaceCulling(); 
            sgl.gl_disableDepthTest()
            sgl.bindVAO_gl(skybox_vao); defer sgl.bindVAO_gl(0)

            sgl.useShader(skybox_shader)
            sgl.setUniformMat4(skybox_shader, "view_projection", projection * sgl.Mat4(sgl.Mat3(view)))
            sgl.setUniformInt(skybox_shader, "skybox", 0)

            gl.ActiveTexture(gl.TEXTURE0)
            gl.BindTexture(gl.TEXTURE_CUBE_MAP, skybox_tex.id)
            // sgl.enableCubeMap(skybox_tex, 0)

            gl.DrawArrays(gl.TRIANGLES, 0, 36)
            sgl.gl_enableDepthTest()
            // sgl.gl_enableFaceCulling(); 
        }

  
        { // DRAW CUBES
            sgl.useShader(object_shader)

            setSpotLightUniforms(object_shader, {
                position = g.camera.base.pos,
                direction = g.camera.base.front,
                ambient = ambient_color,
                diffuse = diffuse_color,
                specular = specular_color,
                cut_off = math.cos(math.to_radians_f32(12.5)),
                outer_cut_off = math.cos(math.to_radians_f32(15)),
                constant = 1.0,
                linear = 0.09,
                quadratic = 0.032,
            })

            for light_pos, i in point_light_positions {
                setPointLightsUniform(object_shader, i, {
                    position = light_pos,
                    direction = g.camera.base.front,
                    ambient = ambient_color,
                    diffuse = diffuse_color,
                    specular = specular_color,
                    constant = 1.0,
                    linear = 0.09,
                    quadratic = 0.032,
                })
            }

            setMaterialPropsUniform(object_shader, {
                diffuse_tex = {},
                specular_tex = {},
                shininess = 50
            })

            // gl.BindVertexArray(vao)
            // for pos, _ in cube_positions {
            //     // angle := f32(i) * 20.0
            //     model := sgl.makeTranslateMat4({pos.x, pos.y, -pos.z}) * sgl.makeRotationMat4(0, {-1, -0.3, 0.5}) 
            //     transform := projection * view * model
            //     normal_mat := Mat3(linalg.transpose(linalg.inverse(model)));  
            //     sgl.setUniformMat4(object_shader, "transform", transform)
            //     sgl.setUniformMat4(object_shader, "model", model)
            //     sgl.setUniformMat3(object_shader, "u_normal", normal_mat)
            //     sgl.setUniformVec3(object_shader, "u_view_pos", g.camera.base.pos)
            //     gl.DrawArrays(gl.TRIANGLES, 0, 36)
            // }
            // gl.BindVertexArray(0)

            {
                // sgl.setUniformTexture2D(object_shader, "U_MATERIAL.specular", {}, 0)
                model_mat := sgl.makeTranslateMat4({0, 0, 0}) * sgl.makeRotationMat4(10, {1, 0, 0})
                model_rot += sgl.getDelta() * 10
                transform := projection * view * model_mat
                normal_mat := Mat3(linalg.transpose(linalg.inverse(model_mat)));  
                sgl.setUniformMat4(object_shader, "transform", transform)
                sgl.setUniformMat4(object_shader, "model", model_mat)
                sgl.setUniformMat3(object_shader, "u_normal", normal_mat)
                sgl.setUniformVec3(object_shader, "u_view_pos", g.camera.base.pos)

                sgl.drawModel(model, object_shader)

                model_mat = sgl.makeTranslateMat4({1, 0, 1})
                model_rot += sgl.getDelta() * 10
                transform = projection * view * model_mat
                normal_mat = Mat3(linalg.transpose(linalg.inverse(model_mat)));  
                sgl.setUniformMat4(object_shader, "transform", transform)
                sgl.setUniformMat4(object_shader, "model", model_mat)
                sgl.setUniformMat3(object_shader, "u_normal", normal_mat)
                sgl.setUniformVec3(object_shader, "u_view_pos", g.camera.base.pos)

                sgl.drawModel(model, object_shader)
            }
        }

        { // DRAW LIGHTS
            sgl.useShader(light_shader)
            for light_pos in point_light_positions {
                model := sgl.makeTranslateMat4(light_pos) * sgl.makeScaleMat4({0.3, 0.3, 0.3})
                transform := projection * view * model
                sgl.setUniformMat4(light_shader, "transform", transform)
                sgl.setUniformVec3(light_shader, "light_color", light_color)
                sgl.bindVAO_gl(vao)
                // gl.DrawArrays(gl.TRIANGLES, 0, 36)
                gl.BindVertexArray(0)
            }
        }
    }
}

MaterialProps :: struct {
    diffuse_tex: sgl.Texture2D,
    specular_tex: sgl.Texture2D,
    shininess: f32,
}

setMaterialPropsUniform :: proc(shader: sgl.Shader, mat: MaterialProps) {
    sgl.setUniformTexture2D(shader, "U_MATERIAL.diffuse", mat.diffuse_tex, 0)
    sgl.setUniformTexture2D(shader, "U_MATERIAL.specular", mat.specular_tex, 1)
    sgl.setUniformFloat(shader, "U_MATERIAL.shininess", mat.shininess)
}

PointLight :: struct {
    position,
    ambient,
    diffuse,
    specular: Vec3,
    constant,
    linear,
    quadratic: f32,
}

setPointLightsUniform :: proc(shader: sgl.Shader, i: int, light: SpotLight) {
    sgl.setUniformVec3(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].position", i), light.position)
    sgl.setUniformVec3(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].direction", i), light.direction)
    sgl.setUniformVec3(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].ambient", i), light.ambient)
    sgl.setUniformVec3(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].diffuse", i), light.diffuse)
    sgl.setUniformVec3(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].specular", i), light.specular)
    sgl.setUniformFloat(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].constant", i), light.constant)
    sgl.setUniformFloat(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].linear", i), light.linear)
    sgl.setUniformFloat(shader, fmt.ctprintf("U_POINT_LIGHTS[%d].quadratic", i), light.quadratic)
}

SpotLight :: struct {
    position,
    direction,
    ambient,
    diffuse,
    specular: Vec3,
    cut_off,
    outer_cut_off,
    constant,
    linear,
    quadratic: f32,
}

setSpotLightUniforms :: proc(shader: sgl.Shader, light: SpotLight) {
    sgl.setUniformVec3(shader, "U_LIGHT.position", light.position)
    sgl.setUniformVec3(shader, "U_LIGHT.direction", light.direction)
    sgl.setUniformVec3(shader, "U_LIGHT.ambient", light.ambient)
    sgl.setUniformVec3(shader, "U_LIGHT.diffuse", light.diffuse)
    sgl.setUniformVec3(shader, "U_LIGHT.specular", light.specular)
    sgl.setUniformFloat(shader, "U_LIGHT.cut_off", light.cut_off)
    sgl.setUniformFloat(shader, "U_LIGHT.outer_cut_off", light.outer_cut_off)
    sgl.setUniformFloat(shader, "U_LIGHT.constant", light.constant)
    sgl.setUniformFloat(shader, "U_LIGHT.linear", light.linear)
    sgl.setUniformFloat(shader, "U_LIGHT.quadratic", light.quadratic)
}

updateFPSCamera :: proc() {
    dir : sgl.Direction3DSet
    if sgl.isKeyDown(.W) do dir += { .Forward }
    if sgl.isKeyDown(.S) do dir += { .Backward }
    if sgl.isKeyDown(.A) do dir += { .Left }
    if sgl.isKeyDown(.D) do dir += { .Right }
    if sgl.isKeyDown(.SPACE) do dir += { .Up }
    if sgl.isKeyDown(.LSHIFT) do dir += { .Down }
    sgl.updateFPSCameraPosition(&g.camera, sgl.getDelta(), dir)
    sgl.updateFPSCameraRotation(&g.camera, sgl.getMouseDeltaX(), sgl.getMouseDeltaY())
    sgl.updateFPSCamera(&g.camera)
}

main :: proc() {
    // sgl.testSerialize()
    // when true do return;

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
    context.logger = log.create_console_logger(); defer log.destroy_console_logger(context.logger)

    run()
}
