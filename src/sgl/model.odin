package sgl

import gltf "vendor:cgltf"
import "core:log"
import "core:fmt"
import "core:path/filepath"
import ass "./lib/assimp"

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
    _initMesh_GL(m)
}

drawMesh :: proc(m: Mesh, s: Shader) {
    for &tex, unit in m.textures {
        setUniformTexture2D(s, fmt.ctprintf("U_MATERIAL.%s", tex.name), tex, u32(unit))
    }
    _drawMesh_GL(m)
}

Model :: struct {
    meshes: []Mesh,
    directory: string,
}

loadModel :: proc(path: cstring) -> (m: Model) {
    scene := ass.import_file_from_file(
        string(path),
        u32(ass.PostProcessSteps.Triangulate) | u32(ass.PostProcessSteps.FlipUVs)
    )
    if scene == nil || bool(scene.mFlags & ass.AI_SCENE_FLAGS_INCOMPLETE) || scene.mRootNode == nil {
        log.errorf("assimp: %s", ass.get_error_string())
        return;
    }
    defer ass.free_scene(scene)

    meshes := make([dynamic]Mesh, ally())
    m.directory = filepath.dir(string(path));

    _processNode(&meshes, scene.mRootNode, scene);

    fmt.println(scene)

    // gltf_model := loadGLTFModelAndBuffers(path)
    //
    // scene := gltf_model.scene
    // nodes := scene.nodes
    // node := nodes[0]
    // children := node.children[0]
    // children2 := children.children[0]
    // children3 := children2.children[0]
    // children := nodes[0].children


    // fmt.println(children3.children[0].mesh)
    return 
}

_processNode :: proc(meshes: ^[dynamic]Mesh, node: ^ass.Node, scene: ^ass.Scene) {
    // process all the node's meshes (if any)
    for i in 0..<node.mNumMeshes {
        mesh := scene.mMeshes[node.mMeshes[i]] 
        append(meshes, _processMesh(mesh, scene))
    }
    // then do the same for each of its children
    for i in 0..<node.mNumChildren {
        _processNode(meshes, node.mChildren[i], scene)
    }
}  

_processMesh :: proc(mesh: ^ass.Mesh, scene: ^ass.Scene) -> Mesh {
    vertices := make([dynamic]Vertex, ally())
    indices := make([dynamic]u32, ally())
    textures := make([dynamic]Texture2D, ally())

    for i in 0..<mesh.mNumVertices {
        vertex : Vertex
        vertex.pos.x = mesh.mVertices[i].x;
        vertex.pos.y = mesh.mVertices[i].y;
        vertex.pos.z = mesh.mVertices[i].z; 
        vertex.normal.x = mesh.mNormals[i].x;
        vertex.normal.y = mesh.mNormals[i].y;
        vertex.normal.z = mesh.mNormals[i].z;
        if (mesh.mTextureCoords[0] == nil) { // does the mesh contain texture coordinates?
            vertex.uv.x = mesh.mTextureCoords[0][i].x
            vertex.uv.y = mesh.mTextureCoords[0][i].y
        } else {
            vertex.uv = {0.0, 0.0}
        }
        append(&vertices, vertex);
    }
    // process indices
    for i in 0..<mesh.mNumFaces {
        face := mesh.mFaces[i];
        for j in 0..<face.mNumIndices {
            append(&indices, face.mIndices[j])
        }
    }  
    // process material
    if 0 <= mesh.mMaterialIndex {
        // [...]
    }

    return makeMesh(vertices[:], indices[:], textures[:]);
}  


destroyModel :: proc(m: ^Model) {
    _ = m
}

GLTFToModelCtx :: struct {

}

drawModel :: proc(m: Model, shader: Shader) {
    for &mesh in m.meshes {
        drawMesh(mesh, shader)
    }
}
