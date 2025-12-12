open LlCtx

type signedness = Signed | Unsigned
type object_type = Instance | ClassStatic | EnumStatic | AbstractStatic

let object_kind_suffix = function
    | Instance -> ""
    | ClassStatic -> ".class"
    | EnumStatic -> ".enum"
    | AbstractStatic -> ".abstract"

type ir_type = 
    | Void
    | Bool
    | Int of int * signedness
    | F32
    | F64
    | Ptr
    | Closure of ir_type list * ir_type
    | Null of ir_type
    | Dynamic
    | Object of (Globals.path * object_type) option
    | EnumInstance of Globals.path option
    | TypeInfo
    | DynObj
    | Slice of ir_type
    | Struct of Globals.path * bool

let module_type_to_ir ctx (mt: TType.module_type) = match mt with
    | TClassDecl c ->
        Object (Some (c.cl_path, Instance))
	| TEnumDecl e ->
        EnumInstance (Some e.e_path)
	| TTypeDecl t ->
        Error.abort ("cannot get ir type for typedef " ^ Globals.s_type_path t.t_path) t.t_name_pos
	| TAbstractDecl a ->
        if Meta.has Meta.CoreType a.a_meta then
            match a.a_path with
            | [], "Void" -> Void
            | [], "Int" -> Int (32, Signed)
            | ["haxe"], "UInt32" -> Int (32, Unsigned)
            | [], "Float" -> F64
            | [], "Single" -> F32
            | [], "Bool" -> Bool
            | [], "Dynamic" -> Dynamic
            | [], "Class" -> Object (Some ((["llvm"], "BaseClass"), Instance))
            | [], "Enum" -> Object (Some ((["llvm"], "BaseEnum"), Instance))
            | [], "EnumValue" -> EnumInstance None
            | ["llvm"], "Int8" -> Int (8, Signed)
            | ["llvm"], "Int16" -> Int (16, Signed)
            | ["llvm"], "Int32" -> Int (32, Signed)
            | ["llvm"], "Int64" -> Int (64, Signed)
            | ["llvm"], "UInt8" -> Int (8, Unsigned)
            | ["llvm"], "UInt16" -> Int (16, Unsigned)
            | ["llvm"], "UInt32" -> Int (32, Unsigned)
            | ["llvm"], "UInt64" -> Int (64, Unsigned)
            | ["llvm"], "Ptr" -> Ptr
            | ["llvm"], "TypeInfo" -> TypeInfo
            | path -> Error.abort ("Unsupported core type: " ^ Globals.s_type_path path) Globals.null_pos
        else
            Error.abort "cannot get type for module type" Globals.null_pos

let rec ty_to_ir ctx (t: TType.t) = match t with
    | TMono t -> Option.map_default (ty_to_ir ctx) Dynamic t.tm_type
    | TEnum (e, params) -> EnumInstance (Some e.e_path)
    | TInst (c, params) -> 
        if Meta.has (Meta.Custom ":llvm.struct") c.cl_meta then
            Struct (c.cl_path, false)
        else
            (match c.cl_kind with
                KTypeParameter _ -> Dynamic
                | _ -> Object (Some (c.cl_path, Instance)))
    | TType (t, params) -> ty_to_ir ctx (TFunctions.apply_typedef t params)
    | TFun (args, ret) -> Closure (List.map (fun (_, _, t) -> ty_to_ir ctx t) args, ty_to_ir ctx ret)
    | TAnon t -> DynObj
    | TDynamic t -> Dynamic
    | TLazy t -> ty_to_ir ctx (TFunctions.lazy_type t)
    | TAbstract (a, params) ->
        if Meta.has Meta.CoreType a.a_meta then
            match a.a_path with
            | [], "Void" -> Void
            | [], "Int" -> Int (32, Signed)
            | ["haxe"], "UInt32" -> Int (32, Unsigned)
            | [], "Float" -> F64
            | ["llvm"], "Float64" -> F64
            | [], "Single" -> F32
            | ["llvm"], "Float32" -> F32
            | [], "Bool" -> Bool
            | [], "Dynamic" -> Dynamic
            | [], "Null" ->
                (match ty_to_ir ctx (List.hd params) with
                    Null t -> Null t
                    | t -> Null t)
            | [], "Class" -> 
                (match params with
                    [TInst({cl_kind = KNormal; _} as c, _)] ->
                        Object (Some (c.cl_path, ClassStatic))
                    | [TInst(_, _) | TDynamic _] ->
                        Object (Some ((["llvm"], "BaseClass"), Instance))
                    | _ ->
                        Object (Some ((["llvm"], "BaseType"), Instance))
                        (* Globals.die (String.concat ", " (List.map TPrinting.s_type_kind params)) __LOC__) *)
                )
            | [], "Enum" ->
                (match params with
                    [TEnum(e, _)] ->
                        Object (Some (e.e_path, EnumStatic))
                    | [TInst(_, _) | TDynamic _] ->
                        Object (Some ((["llvm"], "BaseEnum"), Instance))
                    | _ -> Object (Some ((["llvm"], "BaseType"), Instance)))
            | [], "EnumValue" -> EnumInstance None
            | ["llvm"], "Int8" -> Int (8, Signed)
            | ["llvm"], "Int16" -> Int (16, Signed)
            | ["llvm"], "Int32" -> Int (32, Signed)
            | ["llvm"], "Int64" -> Int (64, Signed)
            | ["llvm"], "UInt8" -> Int (8, Unsigned)
            | ["llvm"], "UInt16" -> Int (16, Unsigned)
            | ["llvm"], "UInt32" -> Int (32, Unsigned)
            | ["llvm"], "UInt64" -> Int (64, Unsigned)
            | ["llvm"], "Ptr" -> Ptr
            | ["llvm"], "TypeInfo" -> TypeInfo
            | ["llvm"], "ObjectPtr" -> Object None
            | ["llvm"], "EnumPtr" -> EnumInstance None
            | ["llvm"], "Slice" -> Slice (ty_to_ir ctx (List.hd params))
            | path -> Error.abort ("Unsupported core type: " ^ Globals.s_type_path path) Globals.null_pos
        else
            ty_to_ir ctx (Abstract.get_underlying_type a params)

let rec ir_type_is_ptr t = match t with
        | Ptr | Dynamic | Object _ | EnumInstance _ | TypeInfo | DynObj -> true
        | Null t -> ir_type_is_ptr t
        | _ -> false

let struct_for_class_by_path ctx path ty_to_llvm ispacked =
    let name = (Globals.s_type_path path) ^ ".struct" in
    try Hashtbl.find ctx.named_struct_types name with Not_found ->
        let s = Llvm.named_struct_type ctx.ll_ctx name in
        let c = get_class_by_path ctx path in

        let tl = List.map (fun f -> ty_to_llvm ctx f.TType.cf_type) c.cl_ordered_fields in
        Llvm.struct_set_body s (Array.of_list tl) ispacked;
        Hashtbl.add ctx.named_struct_types name s;
        s

let rec ir_to_llvm ctx t = match t with
    | Void -> ctx.basic.void
    | Bool -> ctx.basic.i1
    | Int (width, _) -> Llvm.integer_type ctx.ll_ctx width
    | F32 -> ctx.basic.f32
    | F64 -> ctx.basic.f64
    | Ptr | Dynamic | Object _ | EnumInstance _ | TypeInfo | DynObj -> ctx.basic.ptr
    | Closure _ -> Llvm.struct_type ctx.ll_ctx [| ctx.basic.ptr; ctx.basic.ptr |]
    | Null ty ->
        if ir_type_is_ptr ty then
            ctx.basic.ptr
        else
            Llvm.struct_type ctx.ll_ctx [| ctx.basic.i1; ir_to_llvm ctx ty |]
    | Slice ty -> Llvm.struct_type ctx.ll_ctx [| ir_to_llvm ctx ty; ctx.basic.i32 |]
    | Struct (path, ispacked) ->
        let ty_to_llvm ctx t = ir_to_llvm ctx (ty_to_ir ctx t) in
        struct_for_class_by_path ctx path ty_to_llvm ispacked

let ir_default_const ctx t pos = match t with
    | Void -> Error.abort "cannot use void as a value" pos
    | Bool -> ctx.const_false
    | Int (width, _) -> Llvm.const_int (Llvm.integer_type ctx.ll_ctx width) 0
    | F32 -> Llvm.const_float_of_string (Llvm.float_type ctx.ll_ctx) "0.0"
    | F64 -> Llvm.const_float_of_string (Llvm.double_type ctx.ll_ctx) "0.0"
    | Ptr | Dynamic | Object _ | EnumInstance _ | TypeInfo | DynObj -> ctx.const_ptr_null
    | Closure _ ->
        Llvm.const_struct ctx.ll_ctx [|
            ctx.const_ptr_null;
            ctx.const_ptr_null;
        |]
    | Null ty ->
        if ir_type_is_ptr ty then
            ctx.const_ptr_null
        else
            Llvm.const_struct ctx.ll_ctx [|
                ctx.const_true;
                Llvm.const_null (ir_to_llvm ctx ty);
            |]
    | Slice ty ->
        Llvm.const_struct ctx.ll_ctx [|
            Llvm.const_null (ir_to_llvm ctx ty);
            Llvm.const_int ctx.basic.i32 0;
        |]
    | Struct (path, ispacked) ->
        let ty_to_llvm ctx t = ir_to_llvm ctx (ty_to_ir ctx t) in
        let s = struct_for_class_by_path ctx path ty_to_llvm ispacked in
        Llvm.const_null s

let ty_to_llvm ctx t = ir_to_llvm ctx (ty_to_ir ctx t)

let rec ir_type_to_string = function
    | Void -> "void"
    | Bool -> "bool"
    | Int (width, Signed) -> "i" ^ (Int.to_string width)
    | Int (width, Unsigned) -> "u" ^ (Int.to_string width)
    | F32 -> "f32"
    | F64 -> "f64"
    | Ptr -> "ptr"
    | Closure (args, ret) -> "fn(" ^ (String.concat ", " (List.map ir_type_to_string args)) ^ "):" ^ ir_type_to_string ret
    | Null ty -> "null<" ^ ir_type_to_string ty ^ ">"
    | Dynamic -> "dyn"
    | Object (Some (path, kind)) -> "obj(" ^ (Globals.s_type_path path ^ object_kind_suffix kind) ^ ")"
    | Object None -> "obj"
    | EnumInstance (Some e) -> "enum(" ^ Globals.s_type_path e ^ ")"
    | EnumInstance None -> "enum"
    | TypeInfo -> "typeinfo"
    | DynObj -> "dynobj"
    | Slice ty -> "slice<" ^ ir_type_to_string ty ^ ">"
    | Struct (s, packed) -> if packed then "struct<{" ^ Globals.s_type_path s ^ "}>" else "struct{" ^ Globals.s_type_path s ^ "}"

let ir_type_kind = function
    | Void -> 0
    | Bool -> 1
    | Int (width, Signed) -> 2
    | Int (width, Unsigned) -> 2
    | F32 -> 3
    | F64 -> 4
    | Ptr -> 5
    | Closure (args, ret) -> 6
    | Null ty -> 7
    | Dynamic -> 8
    | Object _ -> 9
    | EnumInstance _ -> 10
    | TypeInfo -> 11
    | DynObj -> 12
    | Slice ty -> 13
    | Struct (s, packed) -> 14