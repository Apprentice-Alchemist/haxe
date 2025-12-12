open Type
open LlCtx
open LlType

module IntHashtbl = Globals.IntHashtbl

let mangle_field_name (pack, m: Globals.path) (name: string) = match pack with
    | [] -> "_H" ^ m ^ "." ^ name
    | _ -> "_H" ^ (String.concat "." pack) ^ "." ^ m ^ "." ^ name

let get_class_field_name c cf =
    if TFunctions.has_meta Meta.Native cf.cf_meta then
        fst (Native.get_native_name cf.cf_meta)
    else
        match cf.cf_kind with
            Method MethDynamic -> (mangle_field_name c.cl_path cf.cf_name) ^ ".dynimpl"
            | _ -> mangle_field_name c.cl_path cf.cf_name

let get_enum_constructor_name e ef =
    mangle_field_name e.e_path ef.ef_name

let declare_method ctx (c: tclass) (cf: tclass_field) (static: bool) =
    let name = get_class_field_name c cf in
    try Hashtbl.find ctx.functions name with Not_found ->
    let t_args, ret  = match TFunctions.follow cf.cf_type with TFun (args, ret) -> args, ret | _ -> Error.abort ("wrong function type " ^ s_type_kind cf.cf_type) cf.cf_pos in
    let pointer_type = Llvm.pointer_type ctx.ll_ctx in
    let args = List.map (fun (name, opt, t) -> ty_to_llvm ctx t) t_args in
    let args = if not static then pointer_type :: args else args in
    let t = Llvm.function_type (ty_to_llvm ctx ret) (Array.of_list args) in
    let f = Llvm.declare_function name t ctx.ll_module in
    if TFunctions.has_meta Meta.Native cf.cf_meta then
        Llvm.set_linkage Llvm.Linkage.External f
    else if (TFunctions.has_class_flag c CExtern || TFunctions.has_class_field_flag cf CfExtern) then
        Llvm.set_linkage Llvm.Linkage.External_weak f
    else begin
        Llvm.set_linkage Llvm.Linkage.Internal f;
        let di_fun = LlDbg.create_function ctx.dbg_ctx name (t_args, ret) cf.cf_pos in
        Llvm_debuginfo.set_subprogram f di_fun;
    end;
    Hashtbl.add ctx.functions name (f, t);
    f, t

let build_object_layout ctx cls ordered_fields o_super name static =
    let is_struct = not static && (Meta.has (Meta.Custom ":llvm.struct") cls.cl_meta) in
    let begin_field_offset, begin_method_offset = match o_super with
        | Some(o) -> o.o_num_fields, o.o_num_methods
        | None -> (if is_struct then 0 else 1), 0
    in
    let begin_field_offset = if static then begin_field_offset else begin_field_offset in
    let methods, fields = List.partition (fun cf -> match cf.cf_kind with | Method (MethNormal | MethInline | MethMacro) -> true | _ -> false) ordered_fields in
    let o_method_offsets, o_num_methods = List.fold_left (fun (method_offsets, last_offset) field ->
        if TFunctions.has_class_field_flag field CfOverride
        then
            (method_offsets, last_offset)
        else
        (StringMap.add field.cf_name last_offset method_offsets, last_offset + 1)
    ) (StringMap.empty, begin_method_offset) methods in
    let field_types = match o_super with Some(o) -> Dynarray.of_list o.o_field_types | None -> Dynarray.create () in
    let o_field_offsets, o_num_fields = List.fold_left (fun (field_offsets, last_off) field ->
        Dynarray.add_last field_types field.cf_type;
        (StringMap.add field.cf_name last_off field_offsets, last_off + 1)
    ) (StringMap.empty, begin_field_offset) fields in
    let o_field_types = Dynarray.to_list field_types in
    {
        o_name = name;
        o_super;
        o_field_offsets;
        o_num_fields;
        o_method_offsets;
        o_num_methods;
        o_field_types;
        o_static = static;
        o_struct = is_struct;
    }

let get_object_type ctx layout =
    try Hashtbl.find ctx.named_struct_types layout.o_name with Not_found ->
        let o_type = Llvm.named_struct_type ctx.ll_ctx layout.o_name in
        let o_field_types = 
            if layout.o_struct then 
                List.map (ty_to_llvm ctx) layout.o_field_types
            else
                (Llvm.pointer_type ctx.ll_ctx) :: List.map (ty_to_llvm ctx) layout.o_field_types
            in
        Llvm.struct_set_body o_type (Array.of_list o_field_types) false;
        Hashtbl.add ctx.named_struct_types layout.o_name o_type;
        o_type

let rec get_instance_layout ctx (cls: tclass) =
    let name = Globals.s_type_path cls.cl_path in
    try Hashtbl.find ctx.object_layouts name with Not_found ->
        let o_super = match cls.cl_super with Some (c, _) -> Some (get_instance_layout ctx c) | None -> None in
        let layout = build_object_layout ctx cls cls.cl_ordered_fields o_super name false in 
        Hashtbl.add ctx.object_layouts name layout;
        layout

let get_class_layout ctx (cls: tclass) =
    let name = (Globals.s_type_path cls.cl_path) ^ ".class" in
    try Hashtbl.find ctx.object_layouts name with Not_found ->
        let s = List.find (fun t -> match t with TClassDecl c -> c.cl_path = (["llvm"], "BaseClass") | _ -> false) ctx.gctx.types in
        let s = match s with TClassDecl c -> c | _ -> Globals.die "" __LOC__ in
        let s = get_instance_layout ctx s in
        let layout = build_object_layout ctx cls cls.cl_ordered_statics (Some s) name true in
        Hashtbl.add ctx.object_layouts name layout;
        layout

let get_enum_layout ctx (e: tenum) =
    let name = (Globals.s_type_path e.e_path) ^ ".enum" in
        try Hashtbl.find ctx.object_layouts name with Not_found ->
        let s = List.find (fun t -> match t with TClassDecl c -> c.cl_path = (["llvm"], "BaseEnum") | _ -> false) ctx.gctx.types in
        let s_cls = match s with TClassDecl c -> c | _ -> Globals.die "" __LOC__ in
        let s = get_instance_layout ctx s_cls in
        let layout = {
            o_name = name;
            o_super = Some s;
            o_field_types = s.o_field_types;
            o_field_offsets = StringMap.empty;
            o_num_fields = s.o_num_fields;
            o_method_offsets = StringMap.empty;
            o_num_methods = 0;
            o_static = true;
            o_struct = false;
        } in
        Hashtbl.add ctx.object_layouts name layout;
        layout

let get_abstract_layout ctx (a: tabstract) =
    let name = (Globals.s_type_path a.a_path) ^ ".abstract" in
        try Hashtbl.find ctx.object_layouts name with Not_found ->
        let s = List.find (fun t -> match t with TClassDecl c -> c.cl_path = (["llvm"], "BaseType") | _ -> false) ctx.gctx.types in
        let s_cls = match s with TClassDecl c -> c | _ -> Globals.die "" __LOC__ in
        let s = get_instance_layout ctx s_cls in
        let layout = {
            o_name = name;
            o_super = Some s;
            o_field_offsets = StringMap.empty;
            o_num_fields = s.o_num_fields;
            o_method_offsets = StringMap.empty;
            o_num_methods = 0;
            o_field_types = s.o_field_types;
            o_static = true;
            o_struct = false;
        } in
        Hashtbl.add ctx.object_layouts name layout;
        layout

let get_object_layout ctx path kind =
    match kind with
        | Instance ->
            let c = List.find_map (fun t -> match t with TClassDecl c when c.cl_path = path -> Some c | _ -> None) ctx.gctx.types in
            get_instance_layout ctx (Option.get c)
        | ClassStatic ->
            let c = List.find_map (fun t -> match t with TClassDecl c when c.cl_path = path -> Some c | _ -> None) ctx.gctx.types in
            get_class_layout ctx (Option.get c)
        | EnumStatic ->
            let e = List.find_map (fun t -> match t with TEnumDecl e when e.e_path = path -> Some e | _ -> None) ctx.gctx.types in
            get_enum_layout ctx (Option.get e)
        | AbstractStatic ->
            let a = List.find_map (fun t -> match t with TAbstractDecl a when a.a_path = path -> Some a | _ -> None) ctx.gctx.types in
            get_abstract_layout ctx (Option.get a)

let get_field_index ctx (cls: tclass) (cf: tclass_field) =
    let layout = if TFunctions.has_class_field_flag cf CfStatic then get_class_layout ctx cls else get_instance_layout ctx cls in
    let rec loop layout =
        match StringMap.find_opt cf.cf_name layout.o_field_offsets with
            | Some offset -> get_object_type ctx layout, offset
            | None -> match layout.o_super with Some layout -> loop layout | _ -> raise Not_found
        in
    loop layout

let get_method_index ctx (cls: tclass) (cf: tclass_field) =
    let layout = if TFunctions.has_class_field_flag cf CfStatic then get_class_layout ctx cls else get_instance_layout ctx cls in
    let rec loop layout =
        match StringMap.find_opt cf.cf_name layout.o_method_offsets with
            | Some offset -> get_object_type ctx layout, offset
            | None -> match layout.o_super with Some layout -> loop layout | _ -> raise Not_found
        in
    loop layout

let build_field_gep ctx cls cf o builder =
    let ty, idx = get_field_index ctx cls cf in
    Llvm.build_struct_gep ty o idx "" builder

let get_enum_instance_layout ctx (enum: tenum) =
    let enum_name = Globals.s_type_path enum.e_path in
    try Hashtbl.find ctx.enum_layouts enum_name with Not_found ->
        let e_base_type = Llvm.struct_type ctx.ll_ctx [| Llvm.pointer_type ctx.ll_ctx; Llvm.i32_type ctx.ll_ctx |] in
        let e_variant_layouts = PMap.map (fun v -> 
            let st = Llvm.named_struct_type ctx.ll_ctx ("enum." ^ enum_name ^ "." ^ v.ef_name) in
            let struct_body = (match v.ef_type with 
                | TFun (args, _) -> 
                    Llvm.pointer_type ctx.ll_ctx :: Llvm.i32_type ctx.ll_ctx :: List.map (fun (_, _, t) -> ty_to_llvm ctx t) args
                | TEnum (_, _) ->
                    [Llvm.pointer_type ctx.ll_ctx; Llvm.i32_type ctx.ll_ctx]
                | _ -> Error.abort "invalid enum variant type" v.ef_pos) in
            Llvm.struct_set_body st (Array.of_list struct_body) false;
            {
                e_variant_type = st
            }
        ) enum.e_constrs in
        
        let layout = { e_name = enum_name; e_base_type; e_variant_layouts } in
        Hashtbl.add ctx.enum_layouts enum_name layout;
        layout

let get_enum_variant_layout ctx enum ef =
    let e_layout = get_enum_instance_layout ctx enum in
    PMap.find ef.ef_name e_layout.e_variant_layouts

let build_enum_param_gep ctx builder enum ef e idx =
    let e_layout = get_enum_instance_layout ctx enum in
    let e_variant_layout = PMap.find ef.ef_name e_layout.e_variant_layouts in
    Llvm.build_struct_gep e_variant_layout.e_variant_type e (idx + 2) "" builder

type llvm_expr_ctx = {
    e_ctx: LlCtx.llvm_ctx;
    e_function: Llvm.llvalue;
    e_builder: Llvm.llbuilder;
    e_vars: Llvm.llvalue IntHashtbl.t;
    e_captured_vars: int IntHashtbl.t;
    break_label: Llvm.llbasicblock option;
    continue_label: Llvm.llbasicblock option;
    return_type: ir_type option;
    this_arg: Llvm.llvalue option;
    debug_scope: Llvm.llmetadata option;
}

let create_empty_expr_ctx ctx f builder =
    {
        e_ctx = ctx;
        e_function = f;
        e_builder = builder;
        e_vars = IntHashtbl.create 0;
        e_captured_vars = IntHashtbl.create 0;
        break_label = None;
        continue_label = None;
        return_type = None;
        this_arg = None;
        debug_scope = None;
    }


type place =
    | Local of tvar
    | Global of ir_type * Llvm.llvalue
    | ObjField of Llvm.llvalue * tclass * tclass_field
    | Pointer of ir_type * Llvm.llvalue
    | Array of tclass * ir_type * Llvm.llvalue * Llvm.llvalue
type eval_kind = Value of ir_type option | Place | NoValue
type ir_value = Llvm.llvalue * ir_type
type eval_ret =
    | Value of ir_value
    | Place of place
    | Function of Llvm.llvalue option * Llvm.llvalue * Llvm.lltype * TType.tsignature
    | ControlFlow
    | Nothing

let get_string_object ctx s =
    try Hashtbl.find ctx.string_objects s with Not_found ->
        let c = List.find (fun t -> match t with TClassDecl c -> c.cl_path = ([], "String") | _ -> false) ctx.gctx.types in
        let c = match c with TClassDecl c -> c | _ -> Globals.die "" __LOC__ in
        let instance_layout = get_instance_layout ctx c in
        let instance_type = get_object_type ctx instance_layout in
        let meth_array_type = (Llvm.array_type (Llvm.pointer_type ctx.ll_ctx) instance_layout.o_num_methods) in
        let type_meta_type = Llvm.struct_type ctx.ll_ctx [|
            ctx.type_info_type;
            meth_array_type
        |] in
        let o_meta = Llvm.declare_global
            type_meta_type
            (LlNaming.typeinfo_name (module_type_to_ir ctx (TClassDecl c))) 
            ctx.ll_module
        in
        let g = Llvm.define_global ".str_obj" (Llvm.const_named_struct instance_type [|
            Llvm.const_gep type_meta_type o_meta [|Llvm.const_int ctx.basic.i32 0; Llvm.const_int ctx.basic.i32 1;|];
            Llvm.const_int ctx.basic.i32 (String.length s);
            get_string ctx s
        |]) ctx.ll_module in
        Llvm.set_linkage Private g;
        Hashtbl.add ctx.string_objects s g;
        g

exception Not_const

let rec expr_to_const ctx (e: texpr) =
    match e.eexpr with
        TConst c ->
            (match c with
                TInt i ->
                    let bit_width, signedness = match ty_to_ir ctx e.etype with Int (bit_width, signedness) -> (bit_width, signedness) | _ -> Globals.die "" __LOC__ in
                    (Llvm.const_of_int64 (Llvm.integer_type ctx.ll_ctx bit_width) (Int64.of_int32 i) (signedness = Signed))
                | TFloat s ->
                    (Llvm.const_float_of_string (ty_to_llvm ctx e.etype) s)
                | TBool b -> Llvm.const_int (ctx.basic.i1) (if b then 1 else 0)
                | TNull -> ir_default_const ctx (ty_to_ir ctx e.etype) e.epos
                | TString s -> get_string_object ctx s
                | TThis | TSuper -> raise Not_const
            )
        | TParenthesis e -> expr_to_const ctx e
        | TCast (e, _) -> expr_to_const ctx e
        | _ -> raise Not_const

let test_null ctx (value, ty) =
    if ir_type_is_ptr ty then
        Llvm.build_icmp Llvm.Icmp.Eq value (Llvm.const_pointer_null ctx.e_ctx.basic.ptr) "" ctx.e_builder
    else
        Llvm.build_extractvalue value 0 "" ctx.e_builder

let value_from_null e_ctx (value, ty) =
    let builder = e_ctx.e_builder in
    if ir_type_is_ptr ty then
            value
    else
        Llvm.build_extractvalue value 1 "" builder

let make_null e_ctx (value, ty) =
    let ctx = e_ctx.e_ctx in
    let builder = e_ctx.e_builder in
    if ir_type_is_ptr ty then
        value
    else
        let ty = match ty with Null _ -> ty | _ -> Null ty in
        let s_type = ir_to_llvm ctx ty in
        let v = Llvm.build_insertvalue (Llvm.poison s_type) (Llvm.const_int ctx.basic.i1 0) 0 "" builder in
        Llvm.build_insertvalue v value 1 "" builder

let branch_on_null e_ctx (value, ty) null not_null =
    let ctx = e_ctx.e_ctx in
    let builder = e_ctx.e_builder in
    let is_null = test_null e_ctx (value, ty) in
    let null_bb = Llvm.append_block ctx.ll_ctx "cond.null" e_ctx.e_function in
    let not_null_bb = Llvm.append_block ctx.ll_ctx "cond.not_null" e_ctx.e_function in
    let next_block = Llvm.append_block ctx.ll_ctx "cond.next" e_ctx.e_function in
    ignore(Llvm.build_cond_br is_null null_bb not_null_bb builder);
    Llvm.position_at_end null_bb builder;
    let null_val = null () in
    ignore(Llvm.build_br next_block builder);
    Llvm.position_at_end not_null_bb builder;
    let src_inner = value_from_null e_ctx (value, ty) in
    let non_null_val = not_null src_inner in
    let non_null_end_block = Llvm.insertion_block builder in
    ignore(Llvm.build_br next_block builder);
    Llvm.move_block_after non_null_end_block next_block;
    ignore(Llvm.position_at_end next_block builder);
    Llvm.build_phi [(null_val, null_bb); (non_null_val, non_null_end_block)] "" builder

let null_check e_ctx (value, ty) =
    let ctx = e_ctx.e_ctx in
    let builder = e_ctx.e_builder in
    match ty with
    | Null t ->
        let is_null = test_null e_ctx (value, ty) in
        let null_bb = Llvm.append_block ctx.ll_ctx "cond.null" e_ctx.e_function in
        let not_null_bb = Llvm.append_block ctx.ll_ctx "cond.not_null" e_ctx.e_function in
        ignore(Llvm.build_cond_br is_null null_bb not_null_bb builder);
        Llvm.position_at_end null_bb builder;
        let trap_ty = Llvm.function_type (Llvm.void_type ctx.ll_ctx) [||] in
        let trap = Llvm.declare_function "llvm.trap" trap_ty ctx.ll_module in
        ignore(Llvm.build_call trap_ty trap [||] "" builder);
        ignore(Llvm.build_unreachable builder);
        Llvm.position_at_end not_null_bb builder;
        value_from_null e_ctx (value, ty), t
    | _ -> value, ty

let rec build_cast e_ctx (value, (src_ty: ir_type)) (dest_ty: ir_type) builder p =
    let ctx = e_ctx.e_ctx in
    let builder = e_ctx.e_builder in
    if src_ty = dest_ty then value else
    match src_ty, dest_ty with
        | Int (_, Unsigned), (F32 | F64) ->
            Llvm.build_uitofp value (ir_to_llvm ctx dest_ty) "" builder
        | Int (_, Signed), (F32 | F64) ->
            Llvm.build_sitofp value (ir_to_llvm ctx dest_ty) "" builder
        | (F32 | F64), Int (_, Unsigned) ->
            Llvm.build_fptoui value (ir_to_llvm ctx dest_ty) "" builder
        | (F32 | F64), Int (_, Signed) ->
            Llvm.build_fptosi value (ir_to_llvm ctx dest_ty) "" builder
        | F64, F32 -> Llvm.build_fptrunc value (ir_to_llvm ctx dest_ty) "" builder
        | F32, F64 -> Llvm.build_fpext value (ir_to_llvm ctx dest_ty) "" builder
        | Int (from_width, Signed), Int(to_width, _) when from_width < to_width ->
            Llvm.build_sext value (ir_to_llvm ctx dest_ty) "" builder
        | Int (from_width, Unsigned), Int(to_width, _) when from_width < to_width ->
            Llvm.build_zext value (ir_to_llvm ctx dest_ty) "" builder
        | Int (from_width, _), Int(to_width, _) when from_width > to_width ->
            Llvm.build_trunc value (ir_to_llvm ctx dest_ty) "" builder
        | Int (from_width, _), Int(to_width, _) when from_width = to_width ->
            value
        | Null a, Null b ->
            branch_on_null e_ctx (value, src_ty) (fun () ->
                ir_default_const ctx (Null b) p
            ) (fun src_inner ->
                let dst_inner = build_cast e_ctx (src_inner, a) b builder p in
                make_null e_ctx (dst_inner, b)
            )
        | _, Null ty ->
            let value = build_cast e_ctx (value, src_ty) ty builder p in
            make_null e_ctx (value, ty)
        | Null a, b ->
            branch_on_null e_ctx (value, src_ty) (fun () ->
                ir_default_const ctx b p
            ) (fun src_inner ->
                build_cast e_ctx (src_inner, a) b builder p
            )
            (* let v, ty = null_check (value, src_ty) in
            build_cast (v, ty) dest_ty builder p *)
        | (Object _ | EnumInstance _), Dynamic ->
            value
        | Dynamic, (Object _ | EnumInstance _) ->
            value (* TODO: unsafe *)
        | ty, Dynamic ->
            let t = (Llvm.struct_type ctx.ll_ctx [|Llvm.pointer_type ctx.ll_ctx; ir_to_llvm ctx ty|]) in
            let this = build_gc_alloc ctx t "" builder in
            let type_meta_type = Llvm.struct_type ctx.ll_ctx [|
                ctx.type_info_type;
                Llvm.array_type ctx.basic.ptr 0
            |] in
            let o_meta = Llvm.declare_global type_meta_type (LlNaming.typeinfo_name src_ty) ctx.ll_module in
            let ti_v = Llvm.const_gep type_meta_type o_meta [|Llvm.const_int ctx.basic.i32 0; Llvm.const_int ctx.basic.i32 1;|] in
            ignore(Llvm.build_store ti_v (Llvm.build_struct_gep t this 0 "" builder) builder);
            ignore(Llvm.build_store value (Llvm.build_struct_gep t this 1 "" builder) builder);
            this
        | Dynamic, ty ->
            (* TODO: type check *)
            let dst_t = ir_to_llvm ctx ty in
            let t = (Llvm.struct_type ctx.ll_ctx [|Llvm.pointer_type ctx.ll_ctx; dst_t|]) in
            Llvm.build_load dst_t (Llvm.build_struct_gep t value 1 "" builder) "" builder
        | Object (Some (a_path, a_kind)), Object (Some (b_path, b_kind)) ->
            let a_layout = get_object_layout ctx a_path a_kind in
            let b_layout = get_object_layout ctx b_path b_kind in
            let rec loop layout = 
                if layout.o_name = b_layout.o_name then true
                else match layout.o_super with
                Some l -> loop l
                | None -> false
            in
            if loop a_layout then value else value (* very unsafe, TODO *)
                (* Error.abort ("invalid cast from " ^ (ir_type_to_string src_ty) ^ " to " ^ (ir_type_to_string dest_ty)) p *)
        | Object None, Object (Some _) ->  value (* very unsafe, TODO *)
        | EnumInstance (Some _), EnumInstance None -> value
        | Object (Some _), Object None -> value
        | _ ->
            Error.abort ("invalid cast from " ^ (ir_type_to_string src_ty) ^ " to " ^ (ir_type_to_string dest_ty)) p

let rec emit_cmp expr_ctx (op: Ast.binop) val_a ty_a val_b ty_b epos =
    let ctx = expr_ctx.e_ctx in
    let builder = expr_ctx.e_builder in
        begin match ty_a, ty_b with
            | F32, F32 | F64, F64 ->
                let fcmp: Llvm.Fcmp.t = match op with 
                    | OpEq -> Oeq
                    | OpNotEq -> Une
                    | OpGt -> Ogt
                    | OpGte -> Oge
                    | OpLt -> Olt
                    | OpLte -> Ole
                    | _ -> Error.abort ("not a comparison operation: " ^ (Ast.s_binop op)) epos
            in
                (Llvm.build_fcmp fcmp val_a val_b "" builder)
            | Int (width_a, sig_a), Int (width_b, sig_b) ->
                if width_a <> width_b then Error.abort "integer width mismatch" epos;
                if sig_a <> sig_b then Error.abort "integer signedness mismatch" epos;
                let icmp: Llvm.Icmp.t = match op with 
                    | OpEq -> Eq
                    | OpNotEq -> Ne
                    | OpGt -> if sig_a = Unsigned then Ugt else Sgt
                    | OpGte -> if sig_a = Unsigned then Uge else Sge
                    | OpLt -> if sig_a = Unsigned then Ult else Slt
                    | OpLte -> if sig_a = Unsigned then Ule else Sle
                    | _ -> Error.abort ("not a comparison operation: " ^ (Ast.s_binop op)) epos
                in
                (Llvm.build_icmp icmp val_a val_b "" builder)
            | Null ty, Null ty2 ->
                let a_is_null = test_null expr_ctx (val_a, ty_a) in
                let b_is_null = test_null expr_ctx (val_b, ty_b) in
                Llvm.build_icmp Eq a_is_null b_is_null "" builder
                (* TODO *)
            | Null ty, ty2 ->
                branch_on_null expr_ctx (val_a, ty_a) (fun () -> Llvm.const_int ctx.basic.i1 0) (fun v ->
                    emit_cmp expr_ctx op v ty val_b ty_b epos
                )
            | ty, Null ty2 ->
                branch_on_null expr_ctx (val_b, ty2) (fun () -> Llvm.const_int ctx.basic.i1 0) (fun v ->
                    emit_cmp expr_ctx op val_a ty v ty2 epos
                )
            | Object (Some (([], "String"), Instance)), Object (Some (([], "String"), Instance)) when op = OpEq || op = OpNotEq ->
                let c = match ctx.gctx.basic.tstring with TInst(c, _) -> c | _ -> Globals.die "" __LOC__ in
                let cf = List.find (fun cf -> cf.cf_name = "eq") c.cl_ordered_statics in
                let f, t = declare_method ctx c cf true in
                let v = Llvm.build_call t f [|val_a; val_b|] "" builder in
                if op = OpNotEq then Llvm.build_xor v ctx.const_true "" builder else v
            | Ptr, Ptr | Object _, Object _ | EnumInstance _, EnumInstance _ | TypeInfo, TypeInfo | Dynamic, Dynamic ->
                let icmp: Llvm.Icmp.t = match op with 
                    | OpEq -> Eq
                    | OpNotEq -> Ne
                    | OpGt -> Ugt
                    | OpGte -> Uge
                    | OpLt -> Ult
                    | OpLte -> Ule
                    | _ -> Error.abort ("not a comparison operation: " ^ (Ast.s_binop op)) epos
                in
                (Llvm.build_icmp icmp val_a val_b "" builder)
            | _ -> Error.abort ("wrong types for comparison: " ^ ir_type_to_string ty_a ^ " and " ^ ir_type_to_string ty_b) epos;
        end

let find_var expr_ctx v =
    try IntHashtbl.find expr_ctx.e_vars v.v_id with Not_found ->
        let idx = IntHashtbl.find expr_ctx.e_captured_vars v.v_id in
        let t = Llvm.array_type (Llvm.pointer_type expr_ctx.e_ctx.ll_ctx) (IntHashtbl.length expr_ctx.e_captured_vars) in
        let ptr = Llvm.build_gep t (Option.get expr_ctx.this_arg) [|Llvm.const_int (Llvm.i32_type expr_ctx.e_ctx.ll_ctx) 0; Llvm.const_int (Llvm.i32_type expr_ctx.e_ctx.ll_ctx) idx|] "" expr_ctx.e_builder in
        Llvm.build_load (Llvm.pointer_type expr_ctx.e_ctx.ll_ctx) ptr "" expr_ctx.e_builder

let store_place expr_ctx p v = match p with
    Local var -> ignore(Llvm.build_store v (find_var expr_ctx var) expr_ctx.e_builder)
    | Global (_, global) -> ignore(Llvm.build_store v global expr_ctx.e_builder)
    | ObjField (o, c, cf) ->
        let field_ptr = build_field_gep expr_ctx.e_ctx c cf o expr_ctx.e_builder in
        ignore(Llvm.build_store v field_ptr expr_ctx.e_builder)
    | Pointer (_ty, loc) ->
        ignore(Llvm.build_store v loc expr_ctx.e_builder)
    | Array (c, el_t, v, idx) ->
        let f, t = declare_method expr_ctx.e_ctx c (List.find (fun field -> field.cf_name = "set") c.cl_ordered_fields) false in
        ignore(Llvm.build_call t f [| v; idx; v |] "" expr_ctx.e_builder)

let load_place expr_ctx p =
    let ctx = expr_ctx.e_ctx in
    let builder = expr_ctx.e_builder in
    match p with 
    | Local v -> Llvm.build_load (ty_to_llvm ctx v.v_type) (find_var expr_ctx v) "" builder
    | Global (t, v) -> Llvm.build_load (ir_to_llvm ctx t) v "" builder
    | ObjField (o, c, cf) ->
        let field_ptr = build_field_gep ctx c cf o builder in
        Llvm.build_load (ty_to_llvm ctx cf.cf_type) field_ptr "" builder
    | Pointer (ty, v) -> Llvm.build_load (ir_to_llvm ctx ty) v "" builder
    | Array (c, el_ty, v, idx) ->
        let f, t = declare_method ctx c (List.find (fun field -> field.cf_name = "get") c.cl_ordered_fields) false in
        Llvm.build_call t f [| v; idx |] "" builder


let place_ty expr_ctx p = match p with
    | Local v -> ty_to_ir expr_ctx.e_ctx v.v_type
    | Global (t, _) -> t
    | ObjField (o, c, cf) -> ty_to_ir expr_ctx.e_ctx cf.cf_type
    | Pointer (ty, _) -> ty
    | Array (_, ty, _, _) -> ty

let ret_to_value expr_ctx r pos =
    let builder = expr_ctx.e_builder in
    let ctx = expr_ctx.e_ctx in
    match r with
    | Value (v, t) -> v, t
    | Place p -> load_place expr_ctx p, place_ty expr_ctx p
    | Function (None, f, t, s) ->
        let args = fst s |> List.map (fun (_, _, t) -> ty_to_ir ctx t) in
        let ret_ty = snd s |> ty_to_ir ctx in
        let agg_ty = Llvm.struct_type ctx.ll_ctx [|
            Llvm.pointer_type ctx.ll_ctx;
            Llvm.pointer_type ctx.ll_ctx;
        |] in
        Llvm.build_insertvalue (Llvm.const_null agg_ty) f 0 "" builder, Closure (args, ret_ty)
    | Function (Some env, f, t, s) ->
        let args = fst s |> List.map (fun (_, _, t) -> ty_to_ir ctx t) in
        let ret_ty = snd s |> ty_to_ir ctx in
        let agg_ty = Llvm.struct_type ctx.ll_ctx [|
            Llvm.pointer_type ctx.ll_ctx;
            Llvm.pointer_type ctx.ll_ctx;
        |] in
        let v = Llvm.build_insertvalue (Llvm.poison agg_ty) f 0 "" builder in
        Llvm.build_insertvalue v env 1 "" builder, Closure (args, ret_ty)
    | Nothing | ControlFlow -> Error.abort "no value" pos

let place_addr expr_ctx p  = match p with
    Local var -> (find_var expr_ctx var)
    | Global (_, global) -> global
    | ObjField (o, c, cf) ->
        build_field_gep expr_ctx.e_ctx c cf o expr_ctx.e_builder
    | Pointer (_ty, loc) ->
        loc
    | Array _ -> Globals.die "cannot take address of array" __LOC__

let insert_block expr_ctx name =
    let block = Llvm.append_block expr_ctx.e_ctx.ll_ctx name expr_ctx.e_function in
    block

let rec gen_expr expr_ctx (eval_kind: eval_kind) (expr: texpr) =
    let ctx = expr_ctx.e_ctx in
    let builder = expr_ctx.e_builder in
    Option.may (fun scope ->
        Llvm.set_current_debug_location builder (Llvm.metadata_as_value ctx.ll_ctx (LlDbg.create_pos ctx.dbg_ctx ctx.ll_ctx scope expr.epos));
    ) expr_ctx.debug_scope;

    let dst_ty = ty_to_ir ctx expr.etype in
    match expr.eexpr with
        | TReturn None ->
            ignore(Llvm.build_ret_void builder);
            ControlFlow
        | TReturn (Some e) ->
            let v = value_t expr_ctx e in
            let v = build_cast expr_ctx v (Option.get expr_ctx.return_type) builder e.epos in
            ignore(Llvm.build_ret v builder);
            ControlFlow
        | TConst c ->
            Value ((
            match c with 
                | TInt i -> Llvm.const_of_int64 (ir_to_llvm ctx dst_ty) (Int64.of_int32 i) true
                | TBool b -> Llvm.const_int (ir_to_llvm ctx dst_ty) (if b then 1 else 0)
                | TFloat s -> Llvm.const_float_of_string (ir_to_llvm ctx dst_ty) s
                | TNull -> ir_default_const ctx dst_ty expr.epos
                | TThis -> (match expr_ctx.this_arg with Some(v) -> v | None -> Error.abort "no this" expr.epos)
                | TSuper -> (match expr_ctx.this_arg with Some(v) -> v | None -> Error.abort "no this" expr.epos)
                | TString s -> get_string_object ctx s
            )
            , dst_ty)
        | TUnop (op, flag, e) ->
            Value ((match op with
                | Increment | Decrement -> begin
                    let p = place expr_ctx e in
                    let v = load_place expr_ctx p in
                    let new_v = match op with
                        | Increment ->
                            (match ty_to_ir ctx e.etype with
                            F32 | F64 as ty ->
                                (Llvm.build_fadd v (Llvm.const_float (ir_to_llvm ctx ty) 1.0) "" builder)
                            | Int _ as ty ->
                                (Llvm.build_add v (Llvm.const_int (ir_to_llvm ctx ty) 1) "" builder)
                            | _ -> Error.abort "invalid type for increment" expr.epos)
                        | Decrement ->
                            (match ty_to_ir ctx e.etype with
                            F32 | F64 as ty ->
                                (Llvm.build_fsub v (Llvm.const_float (ir_to_llvm ctx ty) 1.0) "" builder)
                            | Int _ as ty ->
                                (Llvm.build_sub v (Llvm.const_int (ir_to_llvm ctx ty) 1) "" builder)
                            | _ -> Error.abort "invalid type for decrement" expr.epos)
                        | _ -> failwith ""
                    in
                    store_place expr_ctx p new_v;
                    match flag with
                        | Prefix ->
                            new_v
                        | Postfix ->
                            v
                end
                | Neg -> let v = value expr_ctx e in (match ty_to_ir ctx e.etype with
                    F32 | F64 -> Llvm.build_fneg v "" builder
                    | Int _ -> Llvm.build_neg v "" builder
                    | _ -> Error.abort "invalid type for negation" expr.epos)
                | NegBits -> let v = value expr_ctx e in Llvm.build_not v "" builder
                | Not -> let v = value expr_ctx e in Llvm.build_xor v ctx.const_true "" builder
                | Spread -> Error.abort "spread should not reach generator" expr.epos), dst_ty)
        | TBinop (op, a, b) ->
            let binop (op: Ast.binop) (val_a, ty_a) (val_b, ty_b) dst_ty = begin match op with
                | OpAdd ->
                    begin match ty_a, ty_b with
                        | Object (Some (([], "String"), Instance)), Object (Some (([], "String"), Instance)) ->
                            let c = match ctx.gctx.basic.tstring with TInst(c, _) -> c | _ -> Globals.die "" __LOC__ in
                            let cf = List.find (fun cf -> cf.cf_name = "add") c.cl_ordered_statics in
                            let f, t = declare_method ctx c cf true in
                            let v = Llvm.build_call t f [|val_a; val_b|] "" builder in
                            v, ty_a
                        | Object (Some (([], "String"), Instance)), _ ->
                            let std_c = get_class_by_path ctx ([], "Std") in
                            let to_string = List.find (fun cf -> cf.cf_name = "string") std_c.cl_ordered_statics in
                            let to_string_f, to_string_t = declare_method ctx std_c to_string true in
                            let val_b = build_cast expr_ctx (val_b, ty_b) Dynamic builder b.epos in
                            let val_b = Llvm.build_call to_string_t to_string_f [| val_b |] "" builder in
                            let c = match ctx.gctx.basic.tstring with TInst(c, _) -> c | _ -> Globals.die "" __LOC__ in
                            let cf = List.find (fun cf -> cf.cf_name = "add") c.cl_ordered_statics in
                            let f, t = declare_method ctx c cf true in
                            let v = Llvm.build_call t f [|val_a; val_b|] "" builder in
                            v, ty_a
                        | _, Object (Some (([], "String"), Instance)) ->
                            let std_c = get_class_by_path ctx ([], "Std") in
                            let to_string = List.find (fun cf -> cf.cf_name = "string") std_c.cl_ordered_statics in
                            let to_string_f, to_string_t = declare_method ctx std_c to_string true in
                            let val_a = build_cast expr_ctx (val_a, ty_a) Dynamic builder b.epos in
                            let val_a = Llvm.build_call to_string_t to_string_f [| val_a |] "" builder in
                            let c = match ctx.gctx.basic.tstring with TInst(c, _) -> c | _ -> Globals.die "" __LOC__ in
                            let cf = List.find (fun cf -> cf.cf_name = "add") c.cl_ordered_statics in
                            let f, t = declare_method ctx c cf true in
                            let v = Llvm.build_call t f [|val_a; val_b|] "" builder in
                            v, ty_b
                        | _ ->
                        let val_a, ty_a = null_check expr_ctx (val_a, ty_a) in
                        let val_b, ty_b = null_check expr_ctx (val_b, ty_b) in
                        begin match ty_a, ty_b with
                            | F32, F32 | F64, F64 ->
                                (Llvm.build_fadd val_a val_b "" builder), ty_a
                            | Int (width_a, _), Int (width_b, _) ->
                                if width_a <> width_b then Error.abort "integer width mismatch" expr.epos;
                                (Llvm.build_add val_a val_b "" builder), ty_a
                            | _ -> Error.abort "wrong types for add" expr.epos;
                        end
                    end
                | OpMult ->
                    let val_a, ty_a = null_check expr_ctx (val_a, ty_a) in
                    let val_b, ty_b = null_check expr_ctx (val_b, ty_b) in
                    begin match ty_a, ty_b with
                        | F32, F32 | F64, F64 ->
                            (Llvm.build_fmul val_a val_b "" builder), ty_a
                        | Int (width_a, _), Int (width_b, _) ->
                            if width_a <> width_b then Error.abort "integer width mismatch" expr.epos;
                            (Llvm.build_mul val_a val_b "" builder), ty_a
                        | _ -> Error.abort "wrong types for mult" expr.epos;
                    end
                | OpDiv ->
                    let val_a, ty_a = null_check expr_ctx (val_a, ty_a) in
                    let val_b, ty_b = null_check expr_ctx (val_b, ty_b) in
                    begin match ty_a, ty_b with
                        | F32, F32 | F64, F64 ->
                            (Llvm.build_fdiv val_a val_b "" builder), ty_a
                        | Int (width_a, signedness_a), Int (width_b, signedness_b) ->
                            if width_a <> width_b then Error.abort "integer width mismatch" expr.epos;
                            if signedness_a <> signedness_b then Error.abort "integer signedness mismatch" expr.epos;
                            begin match dst_ty with 
                                | F32 | F64 ->
                                    let val_a = build_cast expr_ctx (val_a, ty_a) dst_ty builder a.epos in
                                    let val_b = build_cast expr_ctx (val_b, ty_b) dst_ty builder b.epos in
                                     (Llvm.build_fdiv val_a val_b "" builder), dst_ty
                                | Int _ ->
                                    let ll_ty = (ir_to_llvm ctx ty_b) in
                                    let is_zero = Llvm.build_icmp Eq val_b (Llvm.const_int ll_ty 0) "" builder in
                                    let cur_bb = Llvm.insertion_block builder in
                                    let non_zero_bb = insert_block expr_ctx "div.non_zero" in
                                    Llvm.position_at_end non_zero_bb builder;
                                    let div_result = begin match signedness_a with
                                        | Signed -> (Llvm.build_sdiv val_a val_b "" builder)
                                        | Unsigned -> (Llvm.build_udiv val_a val_b "" builder)
                                    end in
                                    let div_end_bb = Llvm.insertion_block builder in
                                    let end_bb = insert_block expr_ctx "div.end" in
                                    ignore(Llvm.build_br end_bb builder);
                                    Llvm.position_at_end cur_bb builder;
                                    ignore(Llvm.build_cond_br is_zero end_bb non_zero_bb builder);
                                    Llvm.position_at_end end_bb builder;
                                    Llvm.build_phi [(Llvm.const_int ll_ty 0, cur_bb); (div_result, div_end_bb)] "" builder, dst_ty
                                | _ -> Error.abort "invalid destination type" expr.epos
                            end

                        | _ -> Error.abort "wrong types for div" expr.epos;
                    end
                | OpMod ->
                    let val_a, ty_a = null_check expr_ctx (val_a, ty_a) in
                    let val_b, ty_b = null_check expr_ctx (val_b, ty_b) in
                    begin match ty_a, ty_b with
                        | F32, F32 | F64, F64 ->
                            (Llvm.build_frem val_a val_b "" builder), ty_a
                        | Int (width_a, signedness_a), Int (width_b, signedness_b) ->
                            if width_a <> width_b then Error.abort "integer width mismatch" expr.epos;
                            if signedness_a <> signedness_b then Error.abort "integer signedness mismatch" expr.epos;
                            let ll_ty = (ir_to_llvm ctx ty_b) in
                            let is_zero = Llvm.build_icmp Eq val_b (Llvm.const_int ll_ty 0) "" builder in
                            let cur_bb = Llvm.insertion_block builder in
                            let non_zero_bb = insert_block expr_ctx "rem.non_zero" in
                            let end_bb = insert_block expr_ctx "rem.end" in
                            Llvm.position_at_end end_bb builder;
                            let v = Llvm.build_empty_phi ll_ty "" builder in
                            Llvm.position_at_end non_zero_bb builder;
                            let rem_result = begin match signedness_a with
                                | Signed ->
                                    (* 2 ** n = 2 << (n - 1) *)
                                    (* min_val = 2 ** (bit_width - 1) = 2 << (bit_width - 2) *)
                                    let min_val = -(2 lsl (width_a - 2)) in
                                    let a_is_min = Llvm.build_icmp Eq val_a (Llvm.const_int ll_ty min_val) "" builder in
                                    let b_is_minus_one = Llvm.build_icmp Eq val_b (Llvm.const_int ll_ty (-1)) "" builder in
                                    let is_overflow = Llvm.build_and a_is_min b_is_minus_one "" builder in
                                    let not_overflow_bb = insert_block expr_ctx "rem.op" in
                                    Llvm.move_block_after not_overflow_bb end_bb;
                                    ignore(Llvm.build_cond_br is_overflow end_bb not_overflow_bb builder);
                                    Llvm.add_incoming (Llvm.const_int ll_ty 0, non_zero_bb) v;
                                    Llvm.position_at_end not_overflow_bb builder;
                                    Llvm.build_srem val_a val_b "" builder
                                | Unsigned ->
                                    Llvm.build_urem val_a val_b "" builder
                            end in
                            let rem_end_bb = Llvm.insertion_block builder in
                            Llvm.add_incoming (rem_result, rem_end_bb) v;
                            ignore(Llvm.build_br end_bb builder);
                            Llvm.position_at_end cur_bb builder;
                            ignore(Llvm.build_cond_br is_zero end_bb non_zero_bb builder);
                            Llvm.add_incoming (Llvm.const_int ll_ty 0, cur_bb) v;
                            Llvm.position_at_end end_bb builder;
                            v, dst_ty
                        | _ -> Error.abort "wrong types for mod" expr.epos;
                    end
                | OpSub ->
                    let val_a, ty_a = null_check expr_ctx (val_a, ty_a) in
                    let val_b, ty_b = null_check expr_ctx (val_b, ty_b) in
                    begin match ty_a, ty_b with
                        | F32, F32 | F64, F64 ->
                            (Llvm.build_fsub val_a val_b "" builder), ty_a
                        | Int (width_a, _), Int (width_b, _) ->
                            if width_a <> width_b then Error.abort "integer width mismatch" expr.epos;
                            (Llvm.build_sub val_a val_b "" builder), ty_a
                        | _ -> Error.abort "wrong types for sub" expr.epos;
                    end
                | OpEq | OpNotEq | OpGt | OpGte | OpLt | OpLte as op ->
                    emit_cmp expr_ctx op val_a (ty_to_ir ctx a.etype) val_b (ty_to_ir ctx b.etype) expr.epos, Bool
                | OpAnd
                | OpOr
                | OpXor
                | OpShl
                | OpShr
                | OpUShr as op ->
                    let val_a, ty_a = null_check expr_ctx (val_a, ty_a) in
                    let val_b, ty_b = null_check expr_ctx (val_b, ty_b) in
                    begin match ty_to_ir ctx a.etype, ty_to_ir ctx b.etype with
                        | Int (width_a, _) as ty_a, Int (width_b, _) ->
                            let ll_ty_a = ir_to_llvm ctx ty_a in
                            let check_width () = if width_a <> width_b then Error.abort "integer width mismatch" expr.epos in
                            (match op with 
                                | OpAnd -> check_width (); Llvm.build_and val_a val_b "" builder
                                | OpOr -> check_width (); Llvm.build_or val_a val_b "" builder
                                | OpXor -> check_width (); Llvm.build_xor val_a val_b "" builder
                                | OpShl ->
                                    let val_b = Llvm.build_trunc val_b ll_ty_a "" builder in
                                    let val_b = Llvm.build_and val_b (Llvm.const_int ll_ty_a (width_a - 1)) "" builder in
                                    Llvm.build_shl val_a val_b "" builder
                                | OpShr ->
                                    let val_b = Llvm.build_trunc val_b ll_ty_a "" builder in
                                    let val_b = Llvm.build_and val_b (Llvm.const_int ll_ty_a (width_a - 1)) "" builder in
                                    Llvm.build_ashr val_a val_b "" builder
                                | OpUShr ->
                                    let val_b = Llvm.build_trunc val_b ll_ty_a "" builder in
                                    let val_b = Llvm.build_and val_b (Llvm.const_int ll_ty_a (width_a - 1)) "" builder in
                                    Llvm.build_lshr val_a val_b "" builder
                                | _ -> Error.abort "wrong op" expr.epos
                            ), ty_a
                        | a, b -> Error.abort ("wrong types for `" ^ (Ast.s_binop op) ^ "`: " ^ ir_type_to_string a ^ ", " ^ ir_type_to_string b) expr.epos;
                    end
                | OpBoolAnd
                | OpBoolOr
                | OpAssign
                | OpAssignOp _
                | OpInterval
                | OpArrow
                | OpIn
                | OpNullCoal -> Error.abort "this op should not reach this point" expr.epos
            end
            in (match op with 
              | OpAssign ->
                    let place_a = place expr_ctx a in
                    let val_b, ty_b = value_t expr_ctx b in
                    begin match ty_b with
                        | Struct (path, ispacked) -> 
                            let ptr_ty = ctx.basic.ptr in
                            let memcpy_ty = Llvm.function_type ctx.basic.void [|
                                ptr_ty; ptr_ty; ctx.basic.i64; ctx.basic.i1;
                            |] in
                            let dst = place_addr expr_ctx place_a in
                            let src = val_b in
                            let len = Llvm.size_of (struct_for_class_by_path ctx path ty_to_llvm ispacked) in
                            let f = Llvm.declare_function "llvm.memcpy.p0.p0.i64"  memcpy_ty ctx.ll_module in
                            ignore(Llvm.build_call memcpy_ty f [|dst; src; len; Llvm.const_int ctx.basic.i1 0|] "" builder)
                        | _ ->  store_place expr_ctx place_a val_b
                    end;
                    Value (val_b, ty_to_ir ctx b.etype)
            | OpAssignOp op ->
                    let place_a = place expr_ctx a in
                    let val_a = load_place expr_ctx place_a, place_ty expr_ctx place_a in
                    let val_b = value_t expr_ctx b in
                    let v = binop op val_a val_b (snd val_a) in
                    store_place expr_ctx place_a (fst v);
                    Value (fst v, snd v)
            | OpBoolAnd ->
                (* if (a) { b } else { false } *)
                let lhs_val = value expr_ctx a in
                let cur_bb = Llvm.insertion_block builder in
                let rhs_bb = insert_block expr_ctx "land.rhs" in
                Llvm.position_at_end rhs_bb builder;
                let rhs_val = value expr_ctx b in
                let rhs_end_block = Llvm.insertion_block builder in
                let end_block = insert_block expr_ctx "land.end" in
                ignore(Llvm.build_br end_block builder);
                Llvm.position_at_end cur_bb builder;
                ignore(Llvm.build_cond_br lhs_val rhs_bb end_block builder);
                Llvm.position_at_end end_block builder;
                Value (Llvm.build_phi [(Llvm.const_int ctx.basic.i1 0, cur_bb); (rhs_val, rhs_end_block)] "" builder, Bool);
            | OpBoolOr ->
                (* if (a) { true } else { b } *)
                let lhs_val = value expr_ctx a in
                let cur_bb = Llvm.insertion_block builder in
                let rhs_bb = insert_block expr_ctx "lor.rhs" in
                Llvm.position_at_end rhs_bb builder;
                let rhs_val = value expr_ctx b in
                let rhs_end_block = Llvm.insertion_block builder in
                let end_block = insert_block expr_ctx "lor.end" in
                ignore(Llvm.build_br end_block builder);
                Llvm.position_at_end cur_bb builder;
                ignore(Llvm.build_cond_br lhs_val end_block rhs_bb builder);
                Llvm.position_at_end end_block builder;
                Value (Llvm.build_phi [(Llvm.const_int ctx.basic.i1 1, cur_bb); (rhs_val, rhs_end_block)] "" builder, Bool);
            | _ -> 
                let val_a = value_t expr_ctx a in
                let val_b = value_t expr_ctx b in
                let r = binop op val_a val_b dst_ty in
                Value (fst r, snd r)
            )
        | TBlock exprs ->
            let rec loop = function 
                | [e] -> gen_expr expr_ctx eval_kind e
                | [] -> Nothing
                | e :: el -> ignore(gen_expr expr_ctx NoValue e); loop el
            in loop exprs
        | TVar (tvar, Some e) ->
            let v = value_t expr_ctx e in
            let v = build_cast expr_ctx v (ty_to_ir ctx tvar.v_type) builder e.epos in
            let alloca = if TFunctions.has_var_flag tvar VCaptured then 
                build_gc_alloc ctx (ty_to_llvm ctx tvar.v_type) tvar.v_name builder
            else
                Llvm.build_alloca (ty_to_llvm ctx tvar.v_type) tvar.v_name builder
            in
            IntHashtbl.add expr_ctx.e_vars tvar.v_id alloca;
            let ty_a = ty_to_ir ctx tvar.v_type in
            begin match ty_a with
                | Struct (path, ispacked) -> 
                    let ptr_ty = ctx.basic.ptr in
                    let memcpy_ty = Llvm.function_type ctx.basic.void [|
                        ptr_ty; ptr_ty; ctx.basic.i64; ctx.basic.i1;
                    |] in
                    let dst = alloca in
                    let src = v in
                    let len = Llvm.size_of (struct_for_class_by_path ctx path ty_to_llvm ispacked) in
                    let f = Llvm.declare_function "llvm.memcpy.p0.p0.i64"  memcpy_ty ctx.ll_module in
                    ignore(Llvm.build_call memcpy_ty f [|dst; src; len; Llvm.const_int ctx.basic.i1 0|] "" builder)
                | _ ->  ignore(Llvm.build_store v alloca builder);
            end;
            
            Nothing
        | TVar (tvar, None) ->
            let alloca = if TFunctions.has_var_flag tvar VCaptured then 
                build_gc_alloc ctx (ty_to_llvm ctx tvar.v_type) tvar.v_name builder
            else
                Llvm.build_alloca (ty_to_llvm ctx tvar.v_type) tvar.v_name builder
            in
            IntHashtbl.add expr_ctx.e_vars tvar.v_id alloca;
            Nothing
        | TLocal var ->
            Place (Local var)
        | TIf (cond, if_body, None) ->
            let cond_val = value_t expr_ctx cond in
            let cond_val = build_cast expr_ctx cond_val Bool builder cond.epos in
            let cur_debug_location = Llvm.current_debug_location builder in
            let true_bb = insert_block expr_ctx "if.then" in
            let if_builder = Llvm.builder_at_end ctx.ll_ctx true_bb in
            Option.may (Llvm.set_current_debug_location if_builder) cur_debug_location;
            let r = gen_expr {expr_ctx with e_builder = if_builder} NoValue if_body in
            let next_bb = insert_block expr_ctx "if.end" in
            ignore(Llvm.build_cond_br cond_val true_bb next_bb builder);
            if r <> ControlFlow then ignore(Llvm.build_br next_bb if_builder);
            Llvm.position_at_end next_bb builder;
            Nothing
        | TIf (cond, if_body, Some else_body) ->
            let cond_val = value_t expr_ctx cond in
            let cond_val = build_cast expr_ctx cond_val Bool builder cond.epos in

            let true_bb = insert_block expr_ctx "if.then" in
            let if_builder = Llvm.builder_at_end ctx.ll_ctx true_bb in
            let if_ctx  = {expr_ctx with e_builder = if_builder} in
            let if_val_r = gen_expr if_ctx eval_kind if_body in    
            let if_val = match eval_kind with Value _ ->
                Some (build_cast if_ctx (ret_to_value if_ctx if_val_r if_body.epos) dst_ty if_builder if_body.epos)
            | _ -> None in

            let false_bb = insert_block expr_ctx "if.else" in
            let else_builder = Llvm.builder_at_end ctx.ll_ctx false_bb in
            let else_ctx = {expr_ctx with e_builder = else_builder} in
            let else_val_r = gen_expr else_ctx eval_kind else_body in
            let else_val = match eval_kind with Value _ ->
                Some (build_cast else_ctx (ret_to_value else_ctx else_val_r else_body.epos) dst_ty else_builder else_body.epos)
            | _ -> None in

            ignore(Llvm.build_cond_br cond_val true_bb false_bb builder);
            let next_bb = lazy (insert_block expr_ctx "if.end") in

            (if if_val_r <> ControlFlow then ignore(Llvm.build_br (Stdlib.Lazy.force next_bb) if_builder));
            let if_last_block = Llvm.insertion_block if_builder in

            (if else_val_r <> ControlFlow then ignore(Llvm.build_br (Stdlib.Lazy.force next_bb) else_builder));
            let else_last_block = Llvm.insertion_block else_builder in
            if Stdlib.Lazy.is_val next_bb then begin
                Llvm.position_at_end (Stdlib.Lazy.force next_bb) builder;
                (match eval_kind with
                | Value _ ->
                    let values = match if_val, else_val with
                        | Some if_val, Some else_val -> [(if_val, if_last_block); (else_val, else_last_block)]
                        | Some if_val, None -> [(if_val, if_last_block)]
                        | None, Some else_val -> [(else_val, else_last_block)]
                        | _ -> Error.abort "neither branch returns a value" expr.epos
                    in
                    Value (Llvm.build_phi values "" builder, dst_ty)
                | Place -> Error.abort "if else cannot return place" expr.epos
                | NoValue -> Nothing)
            end else ControlFlow
        | TWhile (cond, body, NormalWhile) ->
            let cond_start_block = Llvm.append_block ctx.ll_ctx "while.cond" expr_ctx.e_function in
            ignore(Llvm.build_br cond_start_block builder);
            Llvm.position_at_end cond_start_block builder;
            let cond_val = value expr_ctx cond in
            let body_block = Llvm.append_block ctx.ll_ctx "while.body" expr_ctx.e_function in
            let next_block = Llvm.append_block ctx.ll_ctx "while.end" expr_ctx.e_function in
            ignore(Llvm.build_cond_br cond_val body_block next_block builder);
            Llvm.position_at_end body_block builder;
            ignore(gen_expr { expr_ctx with continue_label = Some cond_start_block; break_label = Some next_block; } NoValue body);
            ignore(Llvm.build_br cond_start_block builder);
            Llvm.move_block_after (Llvm.insertion_block builder) next_block;
            Llvm.position_at_end next_block builder;
            Nothing
        | TWhile (cond, body, DoWhile) ->
            let cond_start_block = Llvm.append_block ctx.ll_ctx "while.cond" expr_ctx.e_function in
            let body_block = Llvm.append_block ctx.ll_ctx "while.body" expr_ctx.e_function in
            let next_block = Llvm.append_block ctx.ll_ctx "while.end" expr_ctx.e_function in
            ignore(Llvm.build_br body_block builder);
            Llvm.position_at_end body_block builder;
            ignore(gen_expr { expr_ctx with continue_label = Some cond_start_block; break_label = Some next_block; } NoValue body);
            ignore(Llvm.build_br cond_start_block builder);
            Llvm.position_at_end cond_start_block builder;
            let cond_val = value expr_ctx cond in
            ignore(Llvm.build_cond_br cond_val body_block next_block builder);
            Llvm.position_at_end next_block builder;
            Nothing
        | TContinue ->
            let block = Option.get expr_ctx.continue_label in
            ignore(Llvm.build_br block builder);
            ControlFlow
        | TBreak ->
            let block = Option.get expr_ctx.break_label in
            ignore(Llvm.build_br block builder);
            ControlFlow
        | TNew (c, params, args) ->
            if Meta.has (Meta.Custom ":llvm.struct") c.cl_meta then
                let ty = ty_to_llvm ctx (TInst (c, [])) in
                let this = Llvm.build_alloca ty "" builder in
                let f, t = declare_method ctx c (TFunctions.get_constructor c) false in
                let l_args = Array.of_list (this :: List.map (value expr_ctx) args) in
                ignore(Llvm.build_call t f l_args "" builder);
                Value (this, Struct (c.cl_path, false))
            else
                let alloc_ty = (Llvm.function_type (Llvm.pointer_type ctx.ll_ctx) [||]) in
                let alloc = Llvm.declare_function (mangle_field_name c.cl_path "$alloc") alloc_ty ctx.ll_module in
                let this = Llvm.build_call alloc_ty alloc [||] "" builder in
                let f, t = declare_method ctx c (TFunctions.get_constructor c) false in
                let l_args = Array.of_list (this :: List.map (value expr_ctx) args) in
                ignore(Llvm.build_call t f l_args "" builder);
                Value (this, Object (Some (c.cl_path, Instance)))
        | TField (ethis, field_access) ->
            begin match field_access with
                | FStatic (c, ({cf_kind = Var _ | Method MethDynamic} as cf)) ->
                   (match c.cl_kind with
                        | KModuleFields _ ->
                            let name = mangle_field_name c.cl_path cf.cf_name in
                            let ty = ty_to_ir ctx cf.cf_type in
                            let g = Llvm.declare_global (ir_to_llvm ctx ty) name ctx.ll_module in
                            Place (Global (ty, g))
                        | _ -> Place (ObjField (value expr_ctx ethis, c, cf)))
                | FInstance (c, _, ({cf_kind = Var _ | Method MethDynamic} as cf)) 
                | FClosure (Some (c, _), ({cf_kind = Method MethDynamic} as cf)) ->
                    let v = if Meta.has (Meta.Custom ":llvm.struct") c.cl_meta then
                        match gen_expr expr_ctx Place ethis with
                            | Place p -> place_addr expr_ctx p
                            | Value v -> fst v
                            | _ -> Error.abort "invalid" ethis.epos
                    else value expr_ctx ethis in 
                    Place (ObjField (v, c, cf))
                | FInstance (c, _, ({ cf_kind = Method (MethNormal | MethInline) } as cf))
                | FClosure (Some (c, _), ({cf_kind = Method (MethNormal | MethInline)} as cf)) ->
                    let this_val = value expr_ctx ethis in
                    let f, t = declare_method ctx c cf false in
                    let obj_ty, idx = get_method_index ctx c cf in
                    let vtable_ptr = Llvm.build_load
                        (Llvm.pointer_type ctx.ll_ctx)
                        (Llvm.build_struct_gep obj_ty this_val 0 "" builder) "" builder
                    in
                    let ptr_to_method_ptr = Llvm.build_gep
                        (Llvm.pointer_type ctx.ll_ctx)
                        vtable_ptr
                        [|Llvm.const_int (Llvm.i32_type ctx.ll_ctx) idx|] "" builder
                    in
                    let method_ptr = Llvm.build_load (Llvm.pointer_type ctx.ll_ctx) ptr_to_method_ptr "" builder in
                    Function (Some this_val, method_ptr, t, match cf.cf_type with TFun t -> t | _ -> Error.abort "want TFun" expr.epos)
                | FStatic (c, ({ cf_kind = Method (MethNormal | MethInline) } as cf)) ->
                    let f, t = declare_method ctx c cf true in
                    Function (None, f, t, match cf.cf_type with TFun t -> t | _ -> Error.abort "want TFun" expr.epos)
                | FEnum (e, ef) ->
                    (match ef.ef_type with
                        TFun (args, ret) ->
                            let t = Llvm.function_type (ty_to_llvm ctx ret) (Array.of_list (List.map (fun (name, opt, t) -> ty_to_llvm ctx t) args)) in
                            let f = Llvm.declare_function (get_enum_constructor_name e ef) t ctx.ll_module in
                            Function (None, f, t, (args, ret))
                        | TEnum (_, _) as t ->
                            let t = ty_to_ir ctx t in
                            let enum_variant_layout = get_enum_variant_layout ctx e ef in
                            let g = Llvm.declare_global enum_variant_layout.e_variant_type (get_enum_constructor_name e ef) ctx.ll_module in
                            Value (g, t)
                        | _ -> Globals.die ~p:expr.epos "wrong enum type" __LOC__)
                | FClosure (_c, {cf_kind = Var _}) as fa ->
                    Globals.die ~p:expr.epos ("unexpected field access: " ^ TPrinting.s_field_access TPrinting.s_type_kind fa) __LOC__
                | FClosure (None, _cf)
                | FAnon (_cf) -> 
                    Value (ir_default_const ctx dst_ty expr.epos, dst_ty)
                    (* Error.abort "FAnon" expr.epos *)
                | FDynamic (_cf) ->
                    Value (ir_default_const ctx dst_ty expr.epos, dst_ty)
                | FStatic (_, {cf_kind = Method MethMacro})
                | FInstance (_, _, {cf_kind = Method MethMacro})
                | FClosure (_, {cf_kind = Method MethMacro}) ->
                    Globals.die ~p:expr.epos "macro invocations should not reach generators" __LOC__
            end
        | TCall(({ eexpr = TConst TSuper; etype = TInst (c, _) }), args) ->
            let cf = TFunctions.get_constructor c in
            let t_args = match TFunctions.follow cf.cf_type with TFun (args, _) -> args | _ -> Globals.die "" __LOC__ in
            let t_args = List.map (fun (_, _, t) -> ty_to_ir ctx t) t_args in
            let f, t = declare_method ctx c (TFunctions.get_constructor c) false in
            let l_args = Array.of_list ((Option.get expr_ctx.this_arg) :: List.map2 (fun e t -> let v = value_t expr_ctx e in build_cast expr_ctx v t builder e.epos) args t_args) in
            ignore(Llvm.build_call t f l_args "" builder);
            Nothing
        | TCall({ eexpr = TField(_, FStatic ({cl_path = (["llvm"; "_Ptr"], "Ptr_Impl_")}, {cf_name = "ref"}))}, args) ->
            (* let pointee_type = (match TFunctions.follow expr.etype with
                | TAbstract ({ a_path = (["llvm"], "Ptr")}, [pointee_type]) ->
                    ty_to_ir ctx pointee_type
                | _ -> Error.abort "" expr.epos) in *)
            let p = place expr_ctx (List.hd args) in
            Value (place_addr expr_ctx p, Ptr)
        | TCall({ eexpr = TField(_, FStatic ({cl_path = (["llvm"; "_Ptr"], "Ptr_Impl_")}, {cf_name = "alloc"}))}, args) ->
            let pointee_type = (match TFunctions.follow expr.etype with
                | TAbstract ({ a_path = (["llvm"], "Ptr")}, [pointee_type]) ->
                    ty_to_ir ctx pointee_type
                | _ -> Error.abort "" expr.epos) in
            Value (build_gc_array_alloc ctx (ir_to_llvm ctx pointee_type) (value expr_ctx (List.hd args)) "" builder, Ptr)
        | TCall({ eexpr = TField(_, FStatic ({cl_path = (["llvm"; "_Ptr"], "Ptr_Impl_")}, {cf_name = "copyFrom"}))}, args) ->
            begin match args with
                    [this; src; len] ->
                        let pointee_type = (match TFunctions.follow (this.etype) with
                        | TAbstract ({ a_path = (["llvm"], "Ptr")}, [pointee_type]) ->
                            ty_to_llvm ctx pointee_type
                        | _ -> Error.abort "" expr.epos) in
                        let void_ty = ctx.basic.void in
                        let ptr_ty = ctx.basic.ptr in
                        let i32_ty = ctx.basic.i32 in
                        let i1_ty = ctx.basic.i1 in
                        let memcpy_ty = Llvm.function_type void_ty [|
                            ptr_ty; ptr_ty; i32_ty; i1_ty;
                        |] in
                        let this = value expr_ctx this in
                        let src = value expr_ctx src in
                        let len = value expr_ctx len in
                        let size_of = Llvm.size_of (pointee_type) in
                        let size_of = Llvm.const_trunc size_of i32_ty in
                        let len = Llvm.build_mul len size_of "" builder in
                        let f = Llvm.declare_function "llvm.memcpy.p0.p0.i32"  memcpy_ty ctx.ll_module in
                        ignore(Llvm.build_call memcpy_ty f [|this; src; len; Llvm.const_int i1_ty 0|] "" builder);
                        Nothing
                    | _ -> Error.abort "wrong arg count" expr.epos
            end
        | TCall({ eexpr = TField(_, FStatic ({cl_path = (["llvm"; "_Ptr"], "Ptr_Impl_")}, {cf_name = "offset"}))}, args) ->
            begin match args with
                    [this; offset] ->
                        let pointee_type = (match TFunctions.follow (this.etype) with
                        | TAbstract ({ a_path = (["llvm"], "Ptr")}, [pointee_type]) ->
                            ty_to_llvm ctx pointee_type
                        | _ -> Error.abort "" expr.epos) in
                        let this = value expr_ctx this in
                        let offset = value expr_ctx offset in
                        Value (Llvm.build_gep pointee_type this [| offset |] "" builder, Ptr)
                    | _ -> Error.abort "wrong arg count" expr.epos
            end
        | TCall ({eexpr = TField(_, FStatic (c, cf))}, args) when Meta.has (Meta.Custom ":llvm.builtin") cf.cf_meta ->
            let _, exprs, meta_pos = TFunctions.get_meta (Meta.Custom ":llvm.builtin") cf.cf_meta in
            let builtin_name, name_pos = (match exprs with
                [(EConst (Ident i), name_pos)] -> i, name_pos
                | _ -> Error.abort "invalid llvm.builtin meta" meta_pos) in
            begin match builtin_name with
                | "type_info_of_dynamic" ->
                    let arg = List.hd args in
                    let v = value expr_ctx arg in
                    let ptr_type = ctx.basic.ptr in
                    (* let i32_type = ctx.basic.i32 in *)
                    (* let ptr = Llvm.build_struct_gep (Llvm.struct_type ctx.ll_ctx [|ptr_type; i32_type|]) v 0 "" builder in *)
                    let vtable_ptr = Llvm.build_load ptr_type v "" builder in
                    let meta_ptr = Llvm.build_gep ctx.type_info_type vtable_ptr [| Llvm.const_int ctx.basic.i32 (-1) |] "" builder in
                    Value (meta_ptr, TypeInfo)
                    (* let v = value_t expr_ctx (List.hd args) in
                    let v = build_cast expr_ctx v Dynamic builder expr.epos in
                    let ti_val = Llvm.build_load (Llvm.pointer_type ctx.ll_ctx) v "" builder in
                    Value (ti_val, TypeInfo) *)
                | "type_info_base_type" ->
                    let arg = List.hd args in
                    let v = value expr_ctx arg in
                    Value (Llvm.build_load ctx.basic.ptr v "" builder, Object (Some ((["llvm"], "BaseType"), Instance)))
                | "type_info_kind" ->
                    let arg = List.hd args in
                    let v = value expr_ctx arg in
                    let ptr = Llvm.build_gep ctx.type_info_type v [|Llvm.const_int ctx.basic.i32 0; Llvm.const_int ctx.basic.i32 1;|] "" builder in
                    Value (Llvm.build_load ctx.basic.i32 ptr "" builder, Object (Some ((["llvm"], "BaseType"), Instance)))
                | "slice_new" ->
                    let elem_type = (match TFunctions.follow expr.etype with
                        | TAbstract ({ a_path = (["llvm"], "Slice")}, [elem_type]) ->
                            ty_to_ir ctx elem_type
                        | _ -> Error.abort "" expr.epos) in
                    let size = value expr_ctx (List.hd args) in
                    let ptr = build_gc_array_alloc ctx (ir_to_llvm ctx elem_type) size "" builder in
                    let ty = Slice elem_type in
                    let ll_ty = ir_to_llvm ctx ty in
                    let v = Llvm.build_insertvalue (Llvm.poison ll_ty) ptr 0 "" builder in
                    let v = Llvm.build_insertvalue v size 1 "" builder in
                    Value (v, Slice elem_type)
                | "slice_ptr" ->
                    let v = value expr_ctx (List.hd args) in
                    let v = Llvm.build_extractvalue v 0 "" builder in
                    Value (v, Ptr)
                | "slice_length" ->
                    let v = value expr_ctx (List.hd args) in
                    let v = Llvm.build_extractvalue v 1 "" builder in
                    Value (v, Int (32, Signed))
                | "f32_to_bits" ->
                    let arg = List.hd args in
                    let v = value_t expr_ctx arg in
                    let v = build_cast expr_ctx v F32 builder arg.epos in
                    Value (Llvm.build_bitcast v ctx.basic.i32 "" builder, Int (32, Unsigned))
                | "f64_to_bits" ->
                    let arg = List.hd args in
                    let v = value_t expr_ctx arg in
                    let v = build_cast expr_ctx v F64 builder arg.epos in
                    Value (Llvm.build_bitcast v ctx.basic.i64 "" builder, Int (64, Unsigned))
                | "f32_from_bits" ->
                    let arg = List.hd args in
                    let v = value_t expr_ctx arg in
                    let v = build_cast expr_ctx v (Int (32, Unsigned)) builder arg.epos in
                    Value (Llvm.build_bitcast v ctx.basic.f32 "" builder, F32)
                | "f64_from_bits" ->
                    let arg = List.hd args in
                    let v = value_t expr_ctx arg in
                    let v = build_cast expr_ctx v (Int (64, Unsigned)) builder arg.epos in
                    Value (Llvm.build_bitcast v ctx.basic.f64 "" builder, F64)
                | "f32_to_f64" ->
                    let arg = List.hd args in
                    let v = value_t expr_ctx arg in
                    let v = build_cast expr_ctx v F32 builder arg.epos in
                    Value (Llvm.build_fpext v ctx.basic.f64 "" builder, F64)
                | "f64_to_f32" ->
                    let arg = List.hd args in
                    let v = value_t expr_ctx arg in
                    let v = build_cast expr_ctx v F64 builder arg.epos in
                    Value (Llvm.build_fptrunc v ctx.basic.f32 "" builder, F32)
                | "enum_index" ->
                    let arg = List.hd args in
                    let v = value expr_ctx arg in
                    let i32_type = ctx.basic.i32 in
                    let ptr = Llvm.build_struct_gep (Llvm.struct_type ctx.ll_ctx [|Llvm.pointer_type ctx.ll_ctx; i32_type|]) v 1 "" builder in
                    Value (Llvm.build_load i32_type ptr "" builder, Int (32, Signed))
                | "enum_type" ->
                    let arg = List.hd args in
                    let v = value expr_ctx arg in
                    let ptr_type = ctx.basic.ptr in
                    let i32_type = ctx.basic.i32 in
                    let ptr = Llvm.build_struct_gep (Llvm.struct_type ctx.ll_ctx [|ptr_type; i32_type|]) v 0 "" builder in
                    let vtable_ptr = Llvm.build_load ptr_type ptr "" builder in
                    let meta_ptr = Llvm.build_gep ctx.type_info_type vtable_ptr [| Llvm.const_int ctx.basic.i32 (-1) |] "" builder in
                    Value (Llvm.build_load ptr_type meta_ptr "" builder, Object (Some ((["llvm"], "BaseEnum"), Instance)))
                | "make_i64" ->
                    begin match args with [a; b] ->
                        begin match (a.eexpr, b.eexpr) with 
                            | (TConst (TInt a), TConst (TInt b)) ->
                                let high = Int64.of_int32 a in
                                let high = Int64.logand high 0xFFFFFFFFL in
                                let high = Int64.shift_left high 32 in
                                let low = Int64.of_int32 b in
                                let low = Int64.logand low 0xFFFFFFFFL in
                                let v = Int64.logor high low in
                                Value (Llvm.const_of_int64 ctx.basic.i64 v true, Int (64, Signed))
                            | _ ->
                                let high = value expr_ctx a in
                                let low = value expr_ctx b in
                                let high = Llvm.build_zext high ctx.basic.i64 "" builder in
                                let low = Llvm.build_zext low ctx.basic.i64 "" builder in
                                let high = Llvm.build_shl high (Llvm.const_int ctx.basic.i64 32) "" builder in
                                Value (Llvm.build_or high low "" builder, Int (64, Signed))
                        end
                    | _ -> Globals.die "" __LOC__
                    end
                | "i64_scmp" ->
                    let a, b = match args with [a; b] -> value expr_ctx a, value expr_ctx b | _ -> Globals.die "" __LOC__ in
                    let scmp_type = Llvm.function_type ctx.basic.i32 [|ctx.basic.i64; ctx.basic.i64|] in
                    let scmp = Llvm.declare_function "llvm.scmp.i32.i64" scmp_type ctx.ll_module in
                    Value (Llvm.build_call scmp_type scmp [|a; b|] "" builder, Int (32, Signed))
                | "i64_ucmp" ->
                    let a, b = match args with [a; b] -> value expr_ctx a, value expr_ctx b | _ -> Globals.die "" __LOC__ in
                    let ucmp_type = Llvm.function_type ctx.basic.i32 [|ctx.basic.i64; ctx.basic.i64|] in
                    let ucmp = Llvm.declare_function "llvm.ucmp.i32.i64" ucmp_type ctx.ll_module in
                    Value (Llvm.build_call ucmp_type ucmp [|a; b|] "" builder, Int (32, Signed))
                | "u8_cmp" ->
                    let a, b = match args with [a; b] -> value expr_ctx a, value expr_ctx b | _ -> Globals.die "" __LOC__ in
                    let ucmp_type = Llvm.function_type ctx.basic.i32 [|ctx.basic.i8; ctx.basic.i8|] in
                    let ucmp = Llvm.declare_function "llvm.ucmp.i32.i8" ucmp_type ctx.ll_module in
                    Value (Llvm.build_call ucmp_type ucmp [|a; b|] "" builder, Int (32, Signed))
                | _ -> Error.abort ("unknown builtin " ^ builtin_name) name_pos
            end
        | TCall(e, args) ->
            let e_val = gen_expr expr_ctx (Value None) e in
            begin match e_val with  
                | Function (None, v, t, (arg_types, ret)) ->
                    let l_args = Array.of_list (List.map2 (fun arg (_, _, ty) ->
                        let v = value_t expr_ctx arg in
                        build_cast expr_ctx v (ty_to_ir ctx ty) builder arg.epos
                    ) args arg_types) in
                    let ret_v = Llvm.build_call t v l_args "" builder in
                    let ret_t = ty_to_ir ctx ret in
                    Value (build_cast expr_ctx (ret_v, ret_t) dst_ty builder expr.epos, dst_ty)
                | Function (Some v_this, v, t, (arg_types, ret)) ->
                    let l_args = Array.of_list (v_this :: List.map2 (fun arg (_, _, ty) ->
                        let v = value_t expr_ctx arg in
                        build_cast expr_ctx v (ty_to_ir ctx ty) builder arg.epos
                    ) args arg_types) in
                    let ret_v = Llvm.build_call t v l_args "" builder in
                    let ret_t = ty_to_ir ctx ret in
                    Value (build_cast expr_ctx (ret_v, ret_t) dst_ty builder expr.epos, dst_ty)
                | Value _ | Place _ ->
                    let v = ret_to_value expr_ctx e_val e.epos in
                    let v, t = null_check expr_ctx v in
                    begin match t with
                        Closure (args_t, ret) ->
                            let function_pointer = Llvm.build_extractvalue v 0 "" builder in
                            let closure_env = Llvm.build_extractvalue v 1 "" builder in
                            let cmp_result = Llvm.build_icmp Llvm.Icmp.Eq closure_env (Llvm.const_pointer_null (Llvm.pointer_type ctx.ll_ctx)) "" builder in
                            let null_block = insert_block expr_ctx "" in
                            let not_null_block = insert_block expr_ctx "" in
                            let next_block = insert_block expr_ctx "" in
                            ignore(Llvm.build_cond_br cmp_result null_block not_null_block builder);
                            Llvm.position_at_end null_block builder;
                            let l_args = Array.of_list (List.map (value expr_ctx) args) in
                            let null_ret = Llvm.build_call (Llvm.function_type (ir_to_llvm ctx ret) (Array.of_list (List.map (ir_to_llvm ctx) args_t))) function_pointer l_args "" builder in
                            ignore(Llvm.build_br next_block builder);
                            Llvm.position_at_end not_null_block builder;
                            let l_args = Array.of_list( closure_env :: (List.map (value expr_ctx) args)) in
                            let not_null_ret = Llvm.build_call (Llvm.function_type (ir_to_llvm ctx ret) (Array.of_list (List.map (ir_to_llvm ctx) (Ptr :: args_t)))) function_pointer l_args "" builder in
                            ignore(Llvm.build_br next_block builder);
                            Llvm.position_at_end next_block builder;
                            (match eval_kind with
                                | Value _ ->
                                    let v = Llvm.build_phi [(null_ret, null_block); (not_null_ret, not_null_block)] "" builder in
                                    Value (build_cast expr_ctx (v, ret) dst_ty builder expr.epos, dst_ty)
                                | _ -> Nothing
                            )
                            | t -> Error.abort ("not a closure " ^ (ir_type_to_string t)) expr.epos
                        end
                | _ -> Error.abort "unhandled call" expr.epos
            end
        | TParenthesis e -> gen_expr expr_ctx eval_kind e
        | TMeta (_, e) -> gen_expr expr_ctx eval_kind e
        | TIdent s -> Error.abort (Printf.sprintf "Unbound identifier `%s`" s) expr.epos
        | TCast (e, None) ->
            Value (build_cast expr_ctx (value_t expr_ctx e) dst_ty builder expr.epos, dst_ty)
        | TCast (e, Some m) ->
            let e_v = value expr_ctx e in
            let layout = match m with
                | TClassDecl c ->
                    get_class_layout ctx c
                | TEnumDecl e ->
                    get_enum_layout ctx e
                | TAbstractDecl a when Meta.has Meta.RuntimeValue a.a_meta ->
                    get_abstract_layout ctx a
                | _ -> Error.abort "wrong module type for cast" expr.epos
            in
            let global = Llvm.declare_global (get_object_type ctx layout) layout.o_name ctx.ll_module in
            let t = Llvm.function_type (Llvm.void_type ctx.ll_ctx) [| Llvm.pointer_type ctx.ll_ctx |] in
            let f = Llvm.declare_function "__haxe_cast" t ctx.ll_module in
            Value (Llvm.build_call t f [| e_v; global; |] "" builder, dst_ty (* TODO: check*))
        | TThrow e ->
            let _v = value expr_ctx e in
            (* let t = Llvm.function_type (Llvm.void_type ctx.ll_ctx) [| Llvm.pointer_type ctx.ll_ctx |] in
            let f = Llvm.declare_function "__haxe_throw_exception" t ctx.ll_module in
            let noreturn = Llvm.create_enum_attr ctx.ll_ctx "noreturn" 0L in
            Llvm.add_function_attr f noreturn Function;
            ignore(Llvm.build_call t f [| v |] "" builder); *)
            ignore(Llvm.build_unreachable builder);
            ControlFlow
        | TEnumParameter (e, ef, idx) ->
            let e_val = value expr_ctx e in
            let e_type = match TFunctions.follow e.etype with
                TEnum (e, _) -> e
                | _ -> Error.abort "wrong type for TEnumParameter.e" e.epos
            in
            let param_ptr = build_enum_param_gep ctx builder e_type ef e_val idx in
            let ret_ty = ty_to_ir ctx expr.etype in
            Value (Llvm.build_load (ty_to_llvm ctx expr.etype) param_ptr "" builder, ret_ty)
        | TEnumIndex e ->
            let v = value expr_ctx e in
            let i32_type = ctx.basic.i32 in
            let ptr = Llvm.build_struct_gep (Llvm.struct_type ctx.ll_ctx [|Llvm.pointer_type ctx.ll_ctx; i32_type|]) v 1 "" builder in
            Value (Llvm.build_load i32_type ptr "" builder, Int (32, Signed))
        | TTypeExpr m ->
            let layout, path, kind = match m with
                | TClassDecl c ->
                    (match c.cl_kind with
                        KAbstractImpl a when Meta.has Meta.RuntimeValue a.a_meta -> get_abstract_layout ctx a, a.a_path, AbstractStatic
                        | _ -> get_class_layout ctx c, c.cl_path, ClassStatic)
                | TEnumDecl e ->
                    get_enum_layout ctx e, e.e_path, EnumStatic
                | TAbstractDecl a when Meta.has Meta.RuntimeValue a.a_meta ->
                    get_abstract_layout ctx a, a.a_path, AbstractStatic
                | _ -> Error.abort "wrong module type for TTypeExpr" expr.epos
            in
            let global = Llvm.declare_global (get_object_type ctx layout) layout.o_name ctx.ll_module in
            Value (global, Object (Some (path, kind)))
        | TObjectDecl fields ->
            Value (Llvm.const_pointer_null (Llvm.pointer_type ctx.ll_ctx), Ptr)
        | TArrayDecl elems ->
            let ptr_ty = Llvm.pointer_type ctx.ll_ctx in
            let i32_ty = Llvm.i32_type ctx.ll_ctx in
            let length = List.length elems in
            let length_val = Llvm.const_int i32_ty length in
            let data_ptr = match elems with 
                [] -> Llvm.const_pointer_null ptr_ty
                | _ ->
                    let data_ptr = build_gc_array_alloc ctx ptr_ty length_val "" builder in
                    List.iteri (fun idx e ->
                        let v = value_t expr_ctx e in
                        let v = build_cast expr_ctx v Dynamic builder e.epos in
                        ignore(Llvm.build_store v (Llvm.build_gep ptr_ty data_ptr [| Llvm.const_int i32_ty idx |] "" builder) builder);
                    ) elems;
                    data_ptr
                in
            let c = match TFunctions.follow expr.etype with
                TInst({cl_path = ([], "Array"); _} as c, _) -> c
                | _ -> Error.abort "expected array type" expr.epos
            in
            let alloc_ty = (Llvm.function_type (Llvm.pointer_type ctx.ll_ctx) [||]) in
            let alloc = Llvm.declare_function (mangle_field_name c.cl_path "$alloc") alloc_ty ctx.ll_module in
            let this = Llvm.build_call alloc_ty alloc [||] "" builder in
            let length_ptr = build_field_gep ctx c (List.find (fun field -> field.cf_name = "length") c.cl_ordered_fields) this builder in
            ignore(Llvm.build_store length_val length_ptr builder);
            let capacity_ptr = build_field_gep ctx c (List.find (fun field -> field.cf_name = "capacity") c.cl_ordered_fields) this builder in
            ignore(Llvm.build_store length_val capacity_ptr builder);
            let this_data_ptr = build_field_gep ctx c (List.find (fun field -> field.cf_name = "data") c.cl_ordered_fields) this builder in
            ignore(Llvm.build_store data_ptr this_data_ptr builder);
            Value (this, Object (Some (c.cl_path, Instance)))
        | TArray (e, idx) ->
            let v = value expr_ctx e in
            let v_idx = value expr_ctx idx in
            (match TFunctions.follow e.etype with
                | TAbstract ({ a_path = (["llvm"], "Ptr")}, [pointee_type]) ->
                    let ir_pointee_type = ty_to_ir ctx pointee_type in
                    let ll_pointee_type = ir_to_llvm ctx ir_pointee_type in
                    let ptr = Llvm.build_gep ll_pointee_type v [| v_idx |] "" builder in
                    Place (Pointer (ir_pointee_type, ptr))
                | TInst({ cl_path = ([], "Array"); _} as c, [elem_type]) ->
                    Place (Array (c, ty_to_ir ctx elem_type, v, v_idx))
                | TInst({ cl_path = (["llvm"], "Slice"); _}, [elem_type]) ->
                    (* TODO: bounds check *)
                    let ir_elem_type = ty_to_ir ctx elem_type in
                    let ll_elem_type = ir_to_llvm ctx ir_elem_type in
                    let ptr = Llvm.build_extractvalue v 0 "" builder in
                    let elem_ptr = Llvm.build_gep ll_elem_type ptr [|v_idx|] "" builder in
                    Place (Pointer (ir_elem_type, elem_ptr))
                | _ -> Error.abort "invalid array access" expr.epos)
        | TFunction tf ->
            let args, ret  = match expr.etype with TFun (args, ret) -> args, ret | t -> Error.abort (TPrinting.s_type_kind t) expr.epos in
            let t = Llvm.function_type (ty_to_llvm ctx ret) (Array.of_list (Llvm.pointer_type ctx.ll_ctx :: List.map (fun (name, opt, t) -> ty_to_llvm ctx t) args)) in
            let f = Llvm.declare_function ("anon." ^ (Int.to_string (Atomic.fetch_and_add ctx.anon_function_counter 1))) t ctx.ll_module in
            let vars, _ = Texpr.collect_captured_vars tf.tf_expr in
            let this_ty = Llvm.array_type (Llvm.pointer_type ctx.ll_ctx) (List.length vars) in
            let this_arg = build_gc_alloc ctx this_ty "" builder in
            let e_captured_vars = IntHashtbl.create 0 in
            List.iteri (fun idx tvar ->
                IntHashtbl.add e_captured_vars tvar.v_id idx;
                ignore(Llvm.build_store (find_var expr_ctx tvar) (Llvm.build_gep this_ty this_arg [|Llvm.const_int (Llvm.i32_type ctx.ll_ctx) 0; Llvm.const_int (Llvm.i32_type ctx.ll_ctx) idx; |] "" builder) builder)
            ) vars;
            generate_function_body ctx f expr true ~e_captured_vars:(Some e_captured_vars);
            Function (Some this_arg, f, t, match expr.etype with TFun t -> t | _ -> Error.abort (s_type_kind tf.tf_type) expr.epos)
        | TTry (e, cases) ->
            gen_expr expr_ctx eval_kind e (* TODO *)
        | TSwitch s ->
            let want_value = match eval_kind with Value _ -> true | _ -> false in
            let v = value expr_ctx s.switch_subject in
            let v_type = ty_to_ir ctx s.switch_subject.etype in
            let current_block = Llvm.insertion_block builder in
            let default_block = insert_block expr_ctx "" in
            let next_block = insert_block expr_ctx "" in
            let default_val = Option.map (fun e ->
                Llvm.position_at_end default_block builder;
                let _v = gen_expr expr_ctx eval_kind e in
                if _v <> ControlFlow then begin
                    ignore(Llvm.build_br next_block builder);
                    if want_value then
                        Some (ret_to_value expr_ctx _v e.epos |> fst, Llvm.insertion_block builder)
                    else None
                end else None
            ) s.switch_default in
            Llvm.position_at_end current_block builder;
            let rec is_const_int e =
                match e.eexpr with
                    | TConst (TInt _) -> true
                    | TParenthesis e -> is_const_int e
                    | TMeta (_, e) -> is_const_int e
                    | _ -> false
            in
            let values = (match v_type with
                Int (_, _) when List.for_all (fun arg ->
                        List.for_all is_const_int arg.case_patterns
                    ) s.switch_cases ->
                    let switch_inst = Llvm.build_switch v default_block 10 builder in
                    List.filter_map (fun case ->
                        let case_block = insert_block expr_ctx "case" in
                        List.iter (fun e ->
                            let const = expr_to_const ctx e in
                            Llvm.add_case switch_inst const case_block;
                        ) case.case_patterns;
                        Llvm.position_at_end case_block builder;
                        let _v = gen_expr expr_ctx eval_kind case.case_expr in
                        if _v <> ControlFlow then begin
                            ignore(Llvm.build_br next_block builder);
                            if want_value then
                                Some (ret_to_value expr_ctx _v case.case_expr.epos |> fst, Llvm.insertion_block builder)
                            else None
                        end else None
                    ) s.switch_cases
                | _ ->
                    List.filter_map (fun case ->
                        let case_block = insert_block expr_ctx "case" in
                        List.iter (fun e ->
                            let v2 = value expr_ctx e in
                            let result = emit_cmp expr_ctx OpEq v v_type v2 (ty_to_ir ctx e.etype) expr.epos in
                            let fallthrough_block = insert_block expr_ctx "" in
                            ignore(Llvm.build_cond_br result case_block fallthrough_block builder);
                            Llvm.position_at_end fallthrough_block builder;
                        ) case.case_patterns;
                        Llvm.position_at_end case_block builder;
                        let _v = gen_expr expr_ctx eval_kind case.case_expr in
                        if _v <> ControlFlow then begin
                            ignore(Llvm.build_br next_block builder);
                            if want_value then
                                Some (ret_to_value expr_ctx _v case.case_expr.epos |> fst, Llvm.insertion_block builder)
                            else None
                        end else None
                    ) s.switch_cases
            ) in
            let values = match default_val with Some (Some (v, b)) -> (v, b) :: values | _ -> values in
            Llvm.position_at_end next_block builder;
            if want_value then Value (Llvm.build_phi values "" builder, dst_ty) else Nothing

and place expr_ctx e = match gen_expr expr_ctx Place e with
    | Place p -> p
    | _ -> Error.abort "not a place" e.epos
and value_t expr_ctx e = ret_to_value expr_ctx (gen_expr expr_ctx (Value None) e) e.epos
and value expr_ctx e = ret_to_value expr_ctx (gen_expr expr_ctx (Value None) e) e.epos |> fst
and generate_function_body ctx ?(e_captured_vars = Stdlib.Option.None) ll_f expr has_this_arg =
    let entry_block = Llvm.append_block ctx.ll_ctx "entry" ll_f in
    let builder = Llvm.builder_at_end ctx.ll_ctx entry_block in
    let scope = Llvm_debuginfo.get_subprogram ll_f in
    (match scope with
        Some s ->
            Llvm.set_current_debug_location builder (Llvm.metadata_as_value ctx.ll_ctx (LlDbg.create_pos ctx.dbg_ctx ctx.ll_ctx s expr.epos))
    | _ -> ());
        match expr.eexpr with TFunction tfunc -> begin
        let e_vars = IntHashtbl.create 0 in
        List.iteri (fun idx (tvar, expr) ->
            let alloc = Llvm.build_alloca (ty_to_llvm ctx tvar.v_type) tvar.v_name builder in
            IntHashtbl.add e_vars tvar.v_id alloc;
            ignore(Llvm.build_store (Llvm.param ll_f (if has_this_arg then idx + 1 else idx)) alloc builder);
        ) tfunc.tf_args;
        let expr_ctx = {
            e_ctx = ctx;
            e_function = ll_f;
            e_builder = builder;
            e_vars;
            e_captured_vars = (match e_captured_vars with None -> IntHashtbl.create 0 | Some table -> table);
            continue_label = None;
            break_label = None;
            return_type = Some (ty_to_ir ctx tfunc.tf_type);
            this_arg = if has_this_arg then Some (Llvm.param ll_f 0) else None;
            debug_scope = scope;
        } in
        match gen_expr expr_ctx NoValue tfunc.tf_expr with
            ControlFlow -> ()
            | _ -> ignore(Llvm.build_ret_void builder)
    end
    | _ -> Error.abort "invalid function body" expr.epos

