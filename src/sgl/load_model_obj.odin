package sgl

import "core:path/filepath"
import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import "core:strconv"

loadModel_obj :: proc(gpa: Allocator, obj_path: string) -> (model: Model) {
    model.directory = filepath.dir(string(obj_path));
    model.meshes = loadMeshes_obj(gpa, obj_path)
    return model
}

Face_obj :: struct {
    vert_ids:   [3]u32,
    uv_ids:     [3]u32,
    normal_ids: [3]u32,
}

loadMeshes_obj :: proc(gpa: Allocator, obj_path: string) -> []Mesh {
    mtl_path := concatStrings(tempAlly(), obj_path[:len(obj_path) - 3], "mtl")
    mtl, mtl_load_ok := loadAndParseMTL(gpa, mtl_path)

    file_bytes, obj_read_ok := readEntireFile(tempAlly(), obj_path)
    assert(obj_read_ok)
    file := string(file_bytes)


    faces := make([dynamic]Face_obj, gpa); defer delete(faces)
    vertices := make([dynamic]Vec3, gpa); defer delete(vertices)
    normals := make([dynamic]Vec3, gpa); defer delete(normals)
    uvs := make([dynamic]Vec2, gpa); defer delete(uvs)

    meshes := make([dynamic]Mesh, gpa)
    curr_mat : MTLMaterial

    is_first_obj := true

    lines_iter := file
    for line in strings.split_lines_iterator(&lines_iter) {
        if len(strings.trim_space(line)) < 2 do continue

        is_normal := line[0:3] == "vn "
        if line[0:2] == "v " || is_normal {
            vert: Vec3
            nums_iter : string
            if is_normal {
                nums_iter = line[3:]
            } else {
                nums_iter = line[2:]
            }
            i := 0
            for num_str in strings.split_iterator(&nums_iter, " ") {
                coord, ok := strconv.parse_f32(num_str)
                assert(ok)
                vert[i] = coord
                i += 1
            }
            if is_normal {
                append(&normals, vert)
            } else {
                append(&vertices, vert)
            }
        } else if line[0:2] == "f " {
            face: Face_obj

            indices_groups_iter := line[2:]
            i := 0
            for indices_group in strings.split_iterator(
                &indices_groups_iter,
                " ",
            ) {
                indices: [3]u32

                indices_iter := indices_group
                j := 0
                for index_str in strings.split_iterator(&indices_iter, "/") {
                    if len(index_str) != 0 {
                        index, ok := strconv.parse_int(index_str)
                        assert(ok)
                        indices[j] = u32(index)
                    }
                    j += 1
                }

                if 3 <= i do break

                face.vert_ids[i] = indices[0]
                face.uv_ids[i] = indices[1]
                face.normal_ids[i] = indices[2]

                i += 1
            }

            append(&faces, face)
        } else if line[0:2] == "vt" {
            uv: Vec2
            nums_iter := line[3:]
            i := 0
            for num_str in strings.split_iterator(&nums_iter, " ") {
                coord, ok := strconv.parse_f32(num_str)
                assert(ok)
                uv[i] = coord
                i += 1
            }
            append(&uvs, uv)
        } else if strings.has_prefix(line, "o ") {
            if is_first_obj {
                is_first_obj = false
                continue
            }
            append(
                &meshes,
                convertOJBModelToMyModel(gpa, faces[:], vertices[:], normals[:], uvs[:], curr_mat)
            )
            clear(&faces)
        } else if strings.has_prefix(line, "usemt") {
            tokens_iter := line
            strings.split_iterator(&tokens_iter, " ")
            mat_name, ok := strings.split_iterator(&tokens_iter, " ")
            fmt.println(mat_name)
            if mtl_load_ok {
                curr_mat = mtl[mat_name]
            }
            assert(ok)

        }
    }

    append(
        &meshes,
        convertOJBModelToMyModel(gpa, faces[:], vertices[:], normals[:], uvs[:], curr_mat)
    )

    shrink(&meshes)

    return meshes[:]
}

convertOJBModelToMyModel :: proc(
    gpa: Allocator,
    faces: []Face_obj,
    vertices: []Vec3,
    normals: []Vec3,
    uvs: []Vec2,
    mat: MTLMaterial,
) -> Mesh {
    decompressed_verts := make([]Vertex, len(faces) * 3, gpa)
    indices := make([]u32, len(faces) * 3, gpa)

    insert_idx := 0;
    for face in faces {
        for i in 0..<3 {
            vert_idx := face.vert_ids[i]
            uv_idx := face.uv_ids[i]
            normal_idx := face.normal_ids[i]

            vert := vertices[vert_idx - 1]
            vert.x = -vert.x
            uv := uvs[uv_idx - 1]
            normal := normals[normal_idx - 1]

            decompressed_verts[insert_idx].pos = vert
            decompressed_verts[insert_idx].uv = uv
            decompressed_verts[insert_idx].normal = normal
            indices[insert_idx] = u32(insert_idx)
            insert_idx += 1
        }
    }

    textures_len := 0
    if mat.diffuse_tex != {} do textures_len += 1
    if mat.specular_tex != {} do textures_len += 1
    textures := make([]Texture2D, textures_len, gpa)
    if mat.specular_tex != {} {
        textures_len -= 1
        textures[textures_len] = mat.specular_tex
    }
    if mat.diffuse_tex != {} {
        textures_len -= 1
        textures[textures_len] = mat.diffuse_tex
    }


    return makeMesh(decompressed_verts, indices, textures)
}

MTLMaterial :: struct {
    diffuse_tex: Texture2D,
    specular_tex: Texture2D,
}

MTLContent :: map[string]MTLMaterial

loadAndParseMTL :: proc(gpa: Allocator, path: string) -> (MTLContent, bool) {
    mtl_bytes, ok := readEntireFile(tempAlly(), path)
    if !ok {
        return {}, false
    }

    mtl := make(MTLContent, gpa)
    _ = mtl

    file := string(mtl_bytes)
    lines_iter := file

    curr_mat : string
    for line in strings.split_lines_iterator(&lines_iter) {
        if strings.has_prefix(line, "newmtl") {
            tokens_iter := line
            strings.split_iterator(&tokens_iter, " ")
            mat_name, ok := strings.split_iterator(&tokens_iter, " ")
            assert(ok)
            curr_mat = mat_name
            mtl[curr_mat] = {}
        } else if strings.has_prefix(line, "map_Kd") || strings.has_prefix(line, "map_Ks") {
            assert(curr_mat != "")

            is_diffuse := strings.has_prefix(line, "map_Kd")
            // is_spec := strings.has_prefix(line, "map_Ks")

            tex_path := line[7:]
            abs_tex_path, abs_path_ok := relToAbsFilePath(tempAlly(), filepath.dir(path), tex_path)
            assert(abs_path_ok)
            if is_diffuse {
                (&mtl[curr_mat]).diffuse_tex = loadTexture2D(abs_tex_path, "diffuse")
            } else {
                (&mtl[curr_mat]).specular_tex = loadTexture2D(abs_tex_path, "specular")
            } 
        }
    }

    return mtl, true
}
