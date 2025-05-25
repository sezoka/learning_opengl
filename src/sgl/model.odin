package sgl

import gltf "vendor:cgltf"
import "core:log"
import "core:fmt"

tryLoadGLTFModelAndBuffers :: proc(path: cstring) -> (^gltf.data, bool) {
    data, status := gltf.parse_file({}, path)
    if status != .success {
        log.errorf("failed to load model '%s' status: '%'", path, status)
    }
    status = gltf.load_buffers({}, data, path) 
    if status != .success {
        log.errorf("failed to load buffers '%s' status: '%v'", path, status)
    }

    return data, true
}

loadGLTFModelAndBuffers :: proc(path: cstring) -> ^gltf.data {
    data, ok := tryLoadGLTFModelAndBuffers(path)
    assert(ok)
    return data
}

freeGLTFModel :: proc(model: ^gltf.data) {
    gltf.free(model)
}

Vertex :: struct {
    pos: Vec3,
    normal: Vec3,
    uv: Vec2,
}

Mesh :: struct {
    vertices: []Vertex,
    indices: []u32,
    textures: []Texture2D,
    vao, vbo, ebo: u32,
}

makeMesh :: proc(vertices: []Vertex, indices: []u32, textures: []Texture2D) -> (m: Mesh) {
    m.vertices = vertices
    m.indices = indices
    m.textures = textures
    initMesh(&m)
    return m
} 

initMesh :: proc(m: ^Mesh) {
    _initMeshGL(m)
}

drawMesh :: proc(m: Mesh, s: Shader) {
    for &tex, unit in m.textures {
        setUniformTexture2D(s, fmt.ctprintf("U_MATERIAL.%s", tex.name), tex, u32(unit))
    }
    _drawMeshGL(m)
}

Model :: struct {
    meshes: []Mesh,
}

loadModel :: proc(path: cstring) -> (m: Model) {
    gltf_model := loadGLTFModelAndBuffers(path)

    scene := gltf_model.scene
    nodes := scene.nodes
    node := nodes[0]
    children := node.children[0]
    children2 := children.children[0]
    children3 := children2.children[0]
    // children := nodes[0].children
    fmt.println(children3.children[0].mesh)
    return 
}

GLTFToModelCtx :: struct {

}

drawModel :: proc(m: Model, shader: Shader) {
    for &mesh in m.meshes {
        drawMesh(mesh, shader)
    }
}

_processScene :: proc(m: ^Model) {
}

_processNode :: proc() {
}

_processMesh :: proc() {

}
