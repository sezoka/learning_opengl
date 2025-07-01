package sgl

import "base:runtime"
import "core:reflect"
import "core:mem"
import "core:fmt"

// pub fn serialize(ally: mem.Allocator, val: anytype) ![]u8 {
//     var buff = std.ArrayList(u8).init(ally);
//     try serializeImpl(&buff, val);
//     return buff.toOwnedSlice();
// }

testSerialize :: proc() {
    Some_Struct :: struct {
        x: u32,
        y: i32,
    }
    v := make([dynamic]Some_Struct)
    append(&v, Some_Struct{123, 321}, Some_Struct{1, 2}, Some_Struct{321, -232})

    serialized := serialize(v)
    deserialized := deserialize(type_of(v), serialized)

    fmt.println(deserialized, len(v))
}

serialize :: proc(v: $T, allocator := context.allocator) -> []u8 {
    buff := make([dynamic]u8, allocator)
    serializeImpl(&buff, v)
    return buff[:]
}

serializeImpl :: proc(buff: ^[dynamic]u8, v: any) -> int {
	ti := runtime.type_info_base(type_info_of(v.id))
	a := any{v.data, ti.id}

    #partial switch info in ti.variant {
    case runtime.Type_Info_Integer,
        runtime.Type_Info_Boolean,
        runtime.Type_Info_Float,
        runtime.Type_Info_Quaternion,
        runtime.Type_Info_Complex,
        runtime.Type_Info_Matrix,
        runtime.Type_Info_Bit_Field:
        bytes := cast([^]u8)(a.data)
        size := reflect.size_of_typeid(ti.id)
        append(buff, ..bytes[0:size])
        return size
    case runtime.Type_Info_Array:
        size := 0
        for i in 0..<info.count {
            data := uintptr(a.data) + uintptr(i * info.elem_size)
            size += serializeImpl(buff, any{rawptr(data), info.elem.id})
        }
        return size
    case runtime.Type_Info_Struct:
        size := 0
        for i in 0..<info.field_count {
            offset := info.offsets[i]
            t := info.types[i]
            data := uintptr(a.data) + offset
            size += serializeImpl(buff, any{rawptr(data), t.id})
        }
        return size
    case runtime.Type_Info_Dynamic_Array:
        array := (^runtime.Raw_Dynamic_Array)(a.data)
        append(buff, 0, 0, 0, 0)
        byte_len := 0
        for i in 0..<array.len {
            data := uintptr(array.data) + uintptr(i * info.elem_size)
            byte_len += serializeImpl(buff, any{rawptr(data), info.elem.id})
        }
        len_insert_pos := &buff[len(buff) - byte_len - 4]
        len_slice := cast([^]u8)(&byte_len)
        mem.copy(len_insert_pos, len_slice, 4)
        return byte_len
    case runtime.Type_Info_Named,
        runtime.Type_Info_String,
        runtime.Type_Info_Any,
        runtime.Type_Info_Type_Id,
        runtime.Type_Info_Pointer,
        runtime.Type_Info_Multi_Pointer,
        runtime.Type_Info_Procedure,
        runtime.Type_Info_Enumerated_Array,
        runtime.Type_Info_Slice,
        runtime.Type_Info_Parameters,
        runtime.Type_Info_Union,
        runtime.Type_Info_Enum,
        runtime.Type_Info_Map,
        runtime.Type_Info_Bit_Set,
        runtime.Type_Info_Simd_Vector,
        runtime.Type_Info_Soa_Pointer:
        panic("unhandled")
    case:
        panic("unhandled")
    }

    return 0
}

deserialize :: proc($T: typeid, buff: []u8, allocator := context.allocator) -> T {
    v: T
    deserializeImpl(v, buff)
    return v
}

deserializeImpl :: proc(v: any, buff: []u8, allocator := context.allocator) -> int {
	ti := runtime.type_info_base(type_info_of(v.id))
	a := any{v.data, ti.id}

    #partial switch info in ti.variant {
    case runtime.Type_Info_Integer,
        runtime.Type_Info_Boolean,
        runtime.Type_Info_Float,
        runtime.Type_Info_Quaternion,
        runtime.Type_Info_Complex,
        runtime.Type_Info_Matrix,
        runtime.Type_Info_Enum,
        runtime.Type_Info_Bit_Field:
        len := reflect.size_of_typeid(ti.id)
        mem.copy(a.data, raw_data(buff), len)
        return len
    case runtime.Type_Info_Array:
        offset := 0
        for _ in 0..<info.count {
            data := uintptr(a.data) + uintptr(offset)
            offset += deserializeImpl(any{rawptr(data), info.elem.id}, buff[offset:])
        }
        return offset
    case runtime.Type_Info_Struct:
        size := 0
        for i in 0..<info.field_count {
            t := info.types[i]
            data := uintptr(a.data) + info.offsets[i]
            size += deserializeImpl(any{rawptr(data), t.id}, buff[size:])
        }
        return size
    case runtime.Type_Info_Dynamic_Array:
        byte_len := (cast(^u32)raw_data(buff))^
        dyn_arr := make([dynamic]u8, byte_len, byte_len)

        offset := 0
        for offset < int(byte_len) {
            offset += deserializeImpl(any{raw_data(dyn_arr[offset:]), info.elem.id}, buff[offset + 4:])
        }

        (^runtime.Raw_Dynamic_Array)(&dyn_arr).len = offset / info.elem_size
        (^runtime.Raw_Dynamic_Array)(a.data)^ = (^runtime.Raw_Dynamic_Array)(&dyn_arr)^

        return offset + 4
    case runtime.Type_Info_Named,
        runtime.Type_Info_String,
        runtime.Type_Info_Any,
        runtime.Type_Info_Type_Id,
        runtime.Type_Info_Pointer,
        runtime.Type_Info_Multi_Pointer,
        runtime.Type_Info_Procedure,
        runtime.Type_Info_Enumerated_Array,
        runtime.Type_Info_Slice,
        runtime.Type_Info_Parameters,
        runtime.Type_Info_Union,
        runtime.Type_Info_Map,
        runtime.Type_Info_Bit_Set,
        runtime.Type_Info_Simd_Vector,
        runtime.Type_Info_Soa_Pointer:
        panic("unhandled")
    case:
        panic("unhandled")
    }

    return 0
}
