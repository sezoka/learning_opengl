package sgl

import "core:strings"
import "core:path/filepath"

concatStrings :: proc(ally: Allocator, strs: ..string) -> string {
    return strings.concatenate(strs, allocator=ally)
}

relToAbsFilePath :: proc(ally: Allocator, root: string, relpath: string) -> (string, bool) {
    paths : [2]string = {root, filepath.dir(relpath)}
    path := filepath.join(paths[:], allocator=tempAlly())
    abs, ok := filepath.abs(path, allocator=tempAlly())
    if ok {
        path_and_name : [2]string = {abs, filepath.base(relpath)}
        return filepath.join(path_and_name[:], allocator=ally), ok
    } else {
        path_and_name : [2]string = {path, filepath.base(relpath)}
        return filepath.join(path_and_name[:], allocator=ally), ok
    }
}
