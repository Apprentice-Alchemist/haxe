open Globals

type item =
    | ClassObject of path
    | ClassVtable of path
    | InstanceVtable of path
    | ClassMethod of path * string
    | InstanceMethod of path * string
    | TypeInfo of LlType.ir_type

let rec encode_type (ty: LlType.ir_type) =
    match ty with 
        | Void -> "v"
        | Bool -> "b"
        | Int (bits, signedness) ->
            (match bits, signedness with
                | 8, Signed -> "a"
                | 8, Unsigned -> "h"
                | 16, Signed -> "s"
                | 16, Unsigned -> "t"
                | 32, Signed -> "i"
                | 32, Unsigned -> "u"
                | 64, Signed -> "x"
                | 64, Unsigned -> "y"
                | _ -> Globals.die "unsupported int type" __LOC__)
        | F32 -> "f"
        | F64 -> "d"
        | Ptr -> "P"
        | Closure (args, ty) -> (List.fold_left (fun acc t -> acc ^ encode_type t) "C" args) ^ "R" ^ encode_type ty
        | Null ty -> "N" ^ encode_type ty
        | Dynamic -> "Dy"
        | Object (Some (name, kind)) -> "O" ^ Globals.s_type_path name ^ LlType.object_kind_suffix kind
        | Object None -> "o"
        | EnumInstance (Some name) -> "E" ^ Globals.s_type_path name
        | EnumInstance None -> "e"
        | TypeInfo -> "T"
        | DynObj -> "Do"
        | Slice ty -> "Ds" ^ encode_type ty
        | Struct (path, packed) -> "S" ^ s_type_path path

let mangle item = 
    match item with
        | ClassObject path -> "_HCO" ^ s_type_path path
        | ClassVtable path -> "_HCV" ^ s_type_path path
        | ClassMethod (path, name) -> "_HCM" ^ s_type_path path ^ "." ^ name
        | InstanceVtable path -> "_HV" ^ s_type_path path
        | InstanceMethod (path, name) -> "_HM" ^ s_type_path path ^ "." ^ name
        | TypeInfo t -> "_HT" ^ encode_type t

let typeinfo_name ty = mangle (TypeInfo ty)
let vtable_name ty = (typeinfo_name ty) ^ ".vtable"