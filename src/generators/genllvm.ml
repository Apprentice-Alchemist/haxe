open Globals
open TType
open LlCtx
open LlType
open LlExpr

let generate_empty_body ctx ll_f =
    let entry_block = Llvm.append_block ctx.ll_ctx "entry" ll_f in
    let builder = Llvm.builder_at_end ctx.ll_ctx entry_block in
    let t = Llvm.function_type (Llvm.void_type ctx.ll_ctx) [||] in
    let trap_f = Llvm.declare_function "llvm.trap" t ctx.ll_module in
    let noreturn = Llvm.create_enum_attr ctx.ll_ctx "noreturn" 0L in
    Llvm.add_function_attr trap_f noreturn Function;
    ignore(Llvm.build_call t trap_f [||] "" builder);
    ignore(Llvm.build_unreachable builder)

let rec init_vtable ctx c method_ptrs = begin
    (match c.cl_super with Some(c, _) -> init_vtable ctx c method_ptrs | None -> ());
    List.iter (fun field ->
        match field.cf_kind with
        | Method (MethNormal | MethInline) ->
            let f = if not (TFunctions.has_class_field_flag field CfAbstract) then
                fst @@ declare_method ctx c field true
            else
                Llvm.const_pointer_null (Llvm.pointer_type ctx.ll_ctx)
            in
            let _, idx = get_method_index ctx c field in
            if TFunctions.has_class_field_flag field CfOverride then
                Dynarray.set method_ptrs idx f
            else
                Dynarray.add_last method_ptrs f;
        | _ -> ()
    ) c.cl_ordered_fields
end

let gen_metadata ctx ty name meta_class method_ptrs =
    let meth_array_type = (Llvm.array_type (Llvm.pointer_type ctx.ll_ctx) (Array.length method_ptrs)) in
    let type_meta_type = Llvm.struct_type ctx.ll_ctx [|
        ctx.type_info_type;
        meth_array_type
    |] in
    let type_meta_val = Llvm.const_struct ctx.ll_ctx [|
        Llvm.const_named_struct ctx.type_info_type [|
            meta_class; (* Llvm.declare_global static_type static_layout.o_name ctx.ll_module *)
            Llvm.const_int ctx.basic.i32 (LlType.ir_type_kind ty)
        |];
        (Llvm.const_array (Llvm.pointer_type ctx.ll_ctx) method_ptrs)
    |] in
    let o_meta = Llvm.declare_global type_meta_type (LlNaming.typeinfo_name ty) ctx.ll_module in
    Llvm.set_initializer type_meta_val o_meta;
    let o_vtable = Llvm.add_alias ctx.ll_module meth_array_type 0 (
        Llvm.const_gep type_meta_type o_meta [|Llvm.const_int ctx.basic.i32 0; Llvm.const_int ctx.basic.i32 1;|]
    ) (LlNaming.vtable_name ty) in 
    o_meta, o_vtable

let gen_class_metadata ctx c =
    let instance_meta = begin
        let instance_layout = get_instance_layout ctx c in
        let meth_array_type = (Llvm.array_type (Llvm.pointer_type ctx.ll_ctx) (instance_layout.o_num_methods)) in
        let type_meta_type = Llvm.struct_type ctx.ll_ctx [|
            ctx.type_info_type;
            meth_array_type
        |] in
        let o_meta = Llvm.declare_global type_meta_type (LlNaming.typeinfo_name (module_type_to_ir ctx (TClassDecl c))) ctx.ll_module in
        o_meta
    end in
    let static_layout = get_class_layout ctx c in
    let alloc_ft = Llvm.function_type (Llvm.pointer_type ctx.ll_ctx) [||] in
    let alloc_f = Llvm.declare_function (mangle_field_name c.cl_path "$alloc") alloc_ft ctx.ll_module in
    let base_class = LlCtx.get_class_by_path ctx (["llvm"], "BaseClass") in
    let method_ptrs = Dynarray.create () in
    init_vtable ctx base_class method_ptrs;
    Dynarray.set method_ptrs 0 alloc_f;
    List.iter (fun field ->
        match field.cf_kind with
            | Method (MethNormal | MethInline) ->
                let f, t = declare_method ctx c field true in
                Dynarray.add_last method_ptrs f
            | _ -> ()
        ) c.cl_ordered_statics;
    let method_ptrs = Dynarray.to_array method_ptrs in
    let _, o_vtable = gen_metadata ctx (Object (Some (c.cl_path, ClassStatic))) static_layout.o_name ctx.const_ptr_null method_ptrs in 
    let o_field_inits = Dynarray.create () in
    Dynarray.add_last o_field_inits o_vtable;
    Dynarray.add_last o_field_inits instance_meta;
    Dynarray.add_last o_field_inits (get_string_object ctx (s_type_path c.cl_path));
    begin match c.cl_super with 
        Some (sup, params) ->
            let static_layout = get_class_layout ctx sup in
            let static_type = get_object_type ctx static_layout in
            let g = Llvm.declare_global static_type static_layout.o_name ctx.ll_module in
            Dynarray.add_last o_field_inits g
        | _ ->
            Dynarray.add_last o_field_inits ctx.const_ptr_null
    end;
    List.iter (fun field ->
        match field.cf_kind with
            | Method MethDynamic ->
                let f, _ = declare_method ctx c field true in
                Llvm.const_struct ctx.ll_ctx [|
                    f; Llvm.const_pointer_null (Llvm.pointer_type ctx.ll_ctx)
                |] |> Dynarray.add_last o_field_inits
            | Var _ ->
                ir_default_const ctx (ty_to_ir ctx field.cf_type) field.cf_pos |> Dynarray.add_last o_field_inits
            | _ -> ()
    ) c.cl_ordered_statics;
    let static_type = get_object_type ctx static_layout in
    let g_init = Llvm.const_named_struct static_type (Dynarray.to_array o_field_inits) in
    let g = Llvm.declare_global static_type static_layout.o_name ctx.ll_module in
    Llvm.set_initializer g_init g

let gen_module_type ctx (ty: Type.module_type) =
    begin match ty with
    | TClassDecl c when not (TFunctions.has_class_flag c CExtern) ->
        List.iter (fun field ->
            match field.cf_kind with
                | Method (MethNormal | MethInline) ->
                    let f, t = declare_method ctx c field true in
                    if not (TFunctions.has_class_flag c CExtern || TFunctions.has_class_field_flag field CfExtern) then
                    begin match field.cf_expr with 
                    | Some e ->
                        generate_function_body ctx f e false
                    | _ -> generate_empty_body ctx f
                    end
                | Method (MethDynamic) ->
                    let f, t = declare_method ctx c field true in
                    if not (TFunctions.has_class_flag c CExtern || TFunctions.has_class_field_flag field CfExtern) then
                    begin match field.cf_expr with Some e -> generate_function_body ctx f e false | _ -> () end
                | _ -> ()
        ) c.cl_ordered_statics;
        (match c.cl_kind with
            | KAbstractImpl _ -> ()
            | KModuleFields _ ->
                List.iter (fun field ->
                    match field.cf_kind with
                        | Method MethDynamic ->
                            let f, _ = declare_method ctx c field true in
                            let init = Llvm.const_struct ctx.ll_ctx [|
                                f; Llvm.const_pointer_null (Llvm.pointer_type ctx.ll_ctx)
                            |] in
                            let name = mangle_field_name c.cl_path field.cf_name in
                            let ty = ty_to_ir ctx field.cf_type in
                            let g = Llvm.declare_global (ir_to_llvm ctx ty) name ctx.ll_module in
                            Llvm.set_initializer init g;
                        | Var _ ->
                            let name = mangle_field_name c.cl_path field.cf_name in
                            let ty = ty_to_ir ctx field.cf_type in
                            let g = Llvm.declare_global (ir_to_llvm ctx ty) name ctx.ll_module in
                            let init = ir_default_const ctx (ty_to_ir ctx field.cf_type) field.cf_pos in
                            Llvm.set_initializer init g;
                        | _ -> ()
                ) c.cl_ordered_statics;
            | _ -> gen_class_metadata ctx c);
        (match c.cl_constructor with
            Some field ->
                let f, t = declare_method ctx c field false in
                if not (TFunctions.has_class_flag c CExtern || TFunctions.has_class_field_flag field CfExtern) then
                begin match field.cf_expr with Some e -> generate_function_body ctx f e true | _ -> () end;
            | None -> ());
        if (match c.cl_kind with KModuleFields _ | KAbstractImpl _ -> false | _ -> true) then begin
            List.iter (fun field ->
                match field.cf_kind with
                    | Method (MethNormal | MethInline) ->
                        let f, t = declare_method ctx c field false in
                        if not (TFunctions.has_class_flag c CExtern || TFunctions.has_class_field_flag field CfExtern) then
                        begin match field.cf_expr with
                            | Some e -> generate_function_body ctx f e true
                            | None -> generate_empty_body ctx f
                        end
                    | Method (MethDynamic) ->
                        let f, t = declare_method ctx c field false in
                        if not (TFunctions.has_class_flag c CExtern || TFunctions.has_class_field_flag field CfExtern) then
                        begin match field.cf_expr with Some e -> generate_function_body ctx f e true | _ -> () end
                    | _ -> ()
            ) c.cl_ordered_fields;
            let instance_layout = get_instance_layout ctx c in
            let static_layout = get_class_layout ctx c in
            let static_type = get_object_type ctx static_layout in
            let instance_type = get_object_type ctx instance_layout in
            let method_ptrs = Dynarray.create () in
            init_vtable ctx c method_ptrs;
            let method_ptrs = Dynarray.to_array method_ptrs in
            let _, o_vtable = gen_metadata ctx ((module_type_to_ir ctx ty)) instance_layout.o_name (Llvm.declare_global static_type static_layout.o_name ctx.ll_module) method_ptrs in
            let alloc_ft = Llvm.function_type (Llvm.pointer_type ctx.ll_ctx) [||] in
            let alloc_f = Llvm.declare_function (mangle_field_name c.cl_path "$alloc") alloc_ft ctx.ll_module in
            let entry_block = Llvm.append_block ctx.ll_ctx "entry" alloc_f in
            let builder = Llvm.builder_at_end ctx.ll_ctx entry_block in
            let this = build_gc_alloc ctx instance_type "" builder in
            ignore(Llvm.build_store (Llvm.const_null instance_type) this builder);
            ignore(Llvm.build_store o_vtable (Llvm.build_struct_gep instance_type this 0 "" builder) builder);
            let rec init_dyn_methods c =
                match c.cl_super with Some (c, _) -> init_dyn_methods c | None -> ();
                List.iter (fun field ->
                    match field.cf_kind with
                    | Method (MethDynamic) ->
                        let f, _ = declare_method ctx c field true in
                        let _, field_idx = get_field_index ctx c field in
                        let f_ptr = Llvm.build_gep instance_type this [|
                            Llvm.const_int (Llvm.i32_type ctx.ll_ctx) 0;
                            Llvm.const_int (Llvm.i32_type ctx.ll_ctx) field_idx;
                            Llvm.const_int (Llvm.i32_type ctx.ll_ctx) 0;
                        |] "" builder in
                        let v_ptr = Llvm.build_gep instance_type this [|
                            Llvm.const_int (Llvm.i32_type ctx.ll_ctx) 0;
                            Llvm.const_int (Llvm.i32_type ctx.ll_ctx) field_idx;
                            Llvm.const_int (Llvm.i32_type ctx.ll_ctx) 1;
                        |] "" builder in
                        ignore(Llvm.build_store f f_ptr builder);
                        ignore(Llvm.build_store this v_ptr builder);
                    | _ -> ()
                ) c.cl_ordered_fields
            in
            init_dyn_methods c;
            ignore(Llvm.build_ret this builder)
        end
    | TEnumDecl e ->
        let static_layout = get_enum_layout ctx e in
        let static_type = get_object_type ctx static_layout in
        let g = Llvm.declare_global static_type static_layout.o_name ctx.ll_module in
        let instance_layout = get_enum_instance_layout ctx e in
        let o_meta, o_vtable = gen_metadata ctx (module_type_to_ir ctx ty) instance_layout.e_name (Llvm.declare_global static_type static_layout.o_name ctx.ll_module) [||] in
        let g_init = Llvm.const_named_struct static_type ([|
            Llvm.const_pointer_null (Llvm.pointer_type ctx.ll_ctx);
            o_meta;
            get_string_object ctx (s_type_path e.e_path);
        |]) in
        Llvm.set_initializer g_init g;
        PMap.iter (fun name ef -> 
            let enum_variant_layout = get_enum_variant_layout ctx e ef in
            (match ef.ef_type with
                TFun (args, ret) ->
                    let t = Llvm.function_type (ty_to_llvm ctx ret) (Array.of_list (List.map (fun (name, opt, t) -> ty_to_llvm ctx t) args)) in
                    let f = Llvm.declare_function (get_enum_constructor_name e ef) t ctx.ll_module in
                    let entry_block = Llvm.append_block ctx.ll_ctx "entry" f in
                    let builder = Llvm.builder_at_end ctx.ll_ctx entry_block in
                    let this = build_gc_alloc ctx enum_variant_layout.e_variant_type "" builder in
                    let ptr = Llvm.build_struct_gep enum_variant_layout.e_variant_type this 0 "" builder in
                    ignore(Llvm.build_store o_vtable ptr builder); 
                    let ptr = Llvm.build_struct_gep enum_variant_layout.e_variant_type this 1 "" builder in
                    ignore(Llvm.build_store (Llvm.const_int ctx.basic.i32 ef.ef_index) ptr builder); 
                    List.iteri (fun idx arg -> 
                        let ptr = build_enum_param_gep ctx builder e ef this idx in
                        ignore(Llvm.build_store (Llvm.param f idx) ptr builder);
                    ) args;
                    ignore(Llvm.build_ret this builder)
                | TEnum (_, _) ->
                    let g' = Llvm.declare_global enum_variant_layout.e_variant_type (get_enum_constructor_name e ef) ctx.ll_module in
                    Llvm.set_initializer (Llvm.const_named_struct enum_variant_layout.e_variant_type [|
                        o_vtable;
                        Llvm.const_int ctx.basic.i32 ef.ef_index
                    |]) g';
                | _ -> Globals.die ~p:ef.ef_pos "wrong enum type" __LOC__)
        ) e.e_constrs
    | TAbstractDecl a when Meta.has Meta.RuntimeValue a.a_meta && a.a_path <> ([], "Class") && a.a_path <> ([], "Enum") ->
        let static_layout = get_abstract_layout ctx a in
        let static_type = get_object_type ctx static_layout in
        let g = Llvm.declare_global static_type static_layout.o_name ctx.ll_module in
        let meta, _ = gen_metadata ctx (module_type_to_ir ctx ty) (s_type_path a.a_path) g [||] in
        let g_init = Llvm.const_named_struct static_type ([|
            Llvm.const_pointer_null (Llvm.pointer_type ctx.ll_ctx);
            meta;
            get_string_object ctx (s_type_path a.a_path);
        |]) in
        Llvm.set_initializer g_init g;
        ()
    | _ -> ()
    end

open Llvm_target
let generate (gctx: Gctx.t) =
    Llvm_all_backends.initialize ();
    let ll_ctx = Llvm.create_context () in
    let ll_module = Llvm.create_module ll_ctx "" in
    let default_triple = Target.default_triple () in
    let target = Target.by_triple default_triple in
    let target_machine = TargetMachine.create ~reloc_mode:RelocMode.PIC ~triple:default_triple target in
    let data_layout = TargetMachine.data_layout target_machine in
    Llvm.set_target_triple default_triple ll_module;
    Llvm.set_data_layout (DataLayout.as_string data_layout) ll_module;
    let compiler_ident = ("Haxe version " ^ s_version_full gctx.version) in
    Llvm.add_named_metadata_operand ll_module "llvm.ident" (Llvm.mdstring ll_ctx compiler_ident);
    let debug_ver = Llvm_debuginfo.debug_metadata_version () |> Llvm.const_int (Llvm.i32_type ll_ctx) in
    Llvm.add_module_flag ll_module Error "Debug Info Version" (Llvm.mdnode ll_ctx [| debug_ver |] |> Llvm.value_as_metadata);
    let debug_ver = Llvm.const_int (Llvm.i32_type ll_ctx) 4 in
    Llvm.add_module_flag ll_module Error "Dwarf Version" (Llvm.mdnode ll_ctx [| debug_ver |] |> Llvm.value_as_metadata);
    let dibuilder = Llvm_debuginfo.dibuilder ll_module in
    let cu_file = Llvm_debuginfo.dibuild_create_file dibuilder gctx.file "" in
    let compile_unit = Llvm_debuginfo.dibuild_create_compile_unit
        dibuilder
        C
        ~file_ref:cu_file
        ~producer:compiler_ident
        ~is_optimized:false
        ~flags:""
        ~runtime_ver:0
        ~split_name:"" 
        Full
        ~dwoid:0
        ~di_inlining:false
        ~di_profiling:false
        ~sys_root:""
        ~sdk:""
    in
    let (debug_ctx: LlDbg.llvm_debug_ctx) = { dibuilder; compile_unit; } in
    let ctx = create_llvm_ctx gctx ll_ctx ll_module data_layout debug_ctx in
    List.iter (gen_module_type ctx) gctx.types;
    (match gctx.main.main_expr with
    | Some main_expr ->
        let di_fun = LlDbg.create_function debug_ctx "main" ([], TDynamic None) Globals.null_pos in
        let i32_type = Llvm.i32_type ll_ctx in
        let f = Llvm.define_function "main" (Llvm.function_type i32_type [| i32_type; Llvm.pointer_type ll_ctx|]) ll_module in
        Llvm_debuginfo.set_subprogram f di_fun;
        let loc = Llvm_debuginfo.dibuild_create_debug_location 
            ll_ctx ~line: 0 ~column: 0 ~scope: di_fun in 
        let _loc2 = Llvm_debuginfo.dibuild_create_debug_location 
            ll_ctx ~line: 0 ~column: 0 ~scope: di_fun in 
        let entry_block = Llvm.entry_block f in
        let builder = Llvm.builder ll_ctx in
        Llvm.set_current_debug_location builder (Llvm.metadata_as_value ll_ctx loc);
        Llvm.position_at_end entry_block builder;

        let gc_init_fun_ty = Llvm.function_type ctx.basic.void [||] in
        let gc_init_fun = Llvm.declare_function "GC_init" gc_init_fun_ty ll_module in
        ignore(Llvm.build_call gc_init_fun_ty gc_init_fun [||] "" builder);
        let init_fun_ty = Llvm.function_type ctx.basic.void [| ctx.basic.i32; ctx.basic.ptr |] in
        let init_fun = Llvm.declare_function "__haxe_init_args" init_fun_ty ll_module in
        ignore(Llvm.build_call init_fun_ty init_fun [| Llvm.param f 0; Llvm.param f 1;|] "" builder);
        ignore(gen_expr (create_empty_expr_ctx ctx f builder) NoValue main_expr);
        ignore(Llvm.build_ret (Llvm.const_int i32_type 0) builder);
    | None -> ());
    Llvm_debuginfo.dibuild_finalize dibuilder;
    Llvm.print_module gctx.file ll_module;
    if gctx.dump_config.dump_mode <> NoDump then begin
        let file = gctx.dump_config.dump_path ^ "/dump.ll" in
        Llvm.print_module file ll_module;
    end;
    Llvm_analysis.assert_valid_module ll_module;

    begin if Gctx.raw_defined gctx "llvm_opt" then
        let passes = Define.raw_defined_value gctx.defines "llvm_opt" in
        let passes = match passes with "1" -> "default<O2>" | _ -> passes in
        let pass_options = Llvm_passbuilder.create_passbuilder_options () in
        (match Llvm_passbuilder.run_passes ll_module passes target_machine pass_options with
            | Ok(()) -> ()
            | Error (err) -> failwith err);
    end;
    (* shell out to llvm-as to verify the module and give a nice diagnostic *)
    (* TODO: figure out how to do this without shelling out *)
    let code = Sys.command (String.concat " " ["llvm-as"; gctx.file; "--disable-output"]) in
    (if code <> 0 then exit code);
    let _bc_path = match List.rev (ExtString.String.nsplit gctx.file ".") with
        | e :: list -> (String.concat "." (List.rev list)) ^ ".bc"
        | _ -> Globals.die "" __LOC__ in
    let o_path = match List.rev (ExtString.String.nsplit gctx.file ".") with
        | e :: list -> (String.concat "." (List.rev list)) ^ ".o"
        | _ -> Globals.die "" __LOC__ in
    let exe_path = match List.rev (ExtString.String.nsplit gctx.file ".") with
        | e :: list -> (String.concat "." (List.rev list)) ^ (if Sys.os_type = "Win32" then ".exe" else "")
        | _ -> Globals.die "" __LOC__ in
    TargetMachine.emit_to_file ll_module CodeGenFileType.ObjectFile o_path target_machine;
    Llvm.dispose_module ll_module;
    Llvm.dispose_context ll_ctx;
    if Sys.command (String.concat " " ["cc"; "-g"; "-lm"; "-lgc"; o_path;"-o"; exe_path]) <> 0 then failwith "Linker failure";
