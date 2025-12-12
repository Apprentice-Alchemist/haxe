module StringMap = Map.Make(Stdlib.String)

type object_layout = {
    o_name: string;
    o_super: object_layout option;
    o_field_offsets: int StringMap.t;
    o_field_types: TType.t list;
    o_num_fields: int;
    o_method_offsets: int StringMap.t;
    o_num_methods: int;
    o_static: bool;
    o_struct: bool;
}

type enum_variant_layout = {
    e_variant_type: Llvm.lltype
}

type enum_layout = {
    e_name: string;
    e_base_type: Llvm.lltype;
    e_variant_layouts: (string, enum_variant_layout) PMap.t
}

type ll_basic_types = {
    void: Llvm.lltype;
    i1: Llvm.lltype;
    i8: Llvm.lltype;
    i16: Llvm.lltype;
    i32: Llvm.lltype;
    i64: Llvm.lltype;
    ptr: Llvm.lltype;
    f32: Llvm.lltype;
    f64: Llvm.lltype;
}

type llvm_ctx = {
    gctx: Gctx.t;
    ll_ctx: Llvm.llcontext;
    ll_module: Llvm.llmodule;
    data_layout: Llvm_target.DataLayout.t;
    object_layouts: (string, object_layout) Hashtbl.t;
    enum_layouts: (string, enum_layout) Hashtbl.t;
    anon_function_counter: int Atomic.t;
    named_struct_types: (string, Llvm.lltype) Hashtbl.t;
    strings: (string, Llvm.llvalue) Hashtbl.t;
    string_objects: (string, Llvm.llvalue) Hashtbl.t;
    dbg_ctx: LlDbg.llvm_debug_ctx;
    functions: (string, Llvm.llvalue * Llvm.lltype) Hashtbl.t;
    basic: ll_basic_types;
    const_ptr_null: Llvm.llvalue;
    const_true: Llvm.llvalue;
    const_false: Llvm.llvalue;
    type_info_type: Llvm.lltype;
}

let create_llvm_ctx gctx ll_ctx ll_module data_layout dbg_ctx =
    let basic = {
        void = Llvm.void_type ll_ctx;
        i1 = Llvm.i1_type ll_ctx;
        i8 = Llvm.i8_type ll_ctx;
        i16 = Llvm.i16_type ll_ctx;
        i32 = Llvm.i32_type ll_ctx;
        i64 = Llvm.i64_type ll_ctx;
        ptr = Llvm.pointer_type ll_ctx;
        f32 = Llvm.float_type ll_ctx;
        f64 = Llvm.double_type ll_ctx;
    } in
    let type_info_type = Llvm.named_struct_type ll_ctx "haxe.type_info" in
    Llvm.struct_set_body type_info_type [|
        basic.ptr;
        basic.i32;
    |] false;
    {
        gctx;
        ll_ctx;
        ll_module;
        data_layout;
        object_layouts = Hashtbl.create 0;
        enum_layouts = Hashtbl.create 0;
        anon_function_counter = Atomic.make 0;
        named_struct_types = Hashtbl.create 0;
        strings = Hashtbl.create 0;
        string_objects = Hashtbl.create 0;
        dbg_ctx;
        functions = Hashtbl.create 0;
        basic;
        const_ptr_null = Llvm.const_pointer_null basic.ptr;
        const_true = Llvm.const_int basic.i1 1;
        const_false = Llvm.const_int basic.i1 0;
        type_info_type;
    }

let get_string ctx s =
    try Hashtbl.find ctx.strings s with Not_found ->
        let g = Llvm.define_global ".str" (Llvm.const_stringz ctx.ll_ctx s) ctx.ll_module in
        Llvm.set_linkage Private g;
        Llvm.set_unnamed_addr true g;
        Hashtbl.add ctx.strings s g;
        g

let get_class_by_path ctx path =
    let s = List.find (fun t -> match t with TType.TClassDecl c -> c.cl_path = path | _ -> false) ctx.gctx.types in
    let s = match s with TClassDecl c -> c | _ -> Globals.die "" __LOC__ in
    s

let build_gc_alloc ctx ty name builder =
    let alloc_fty = Llvm.function_type ctx.basic.ptr [| ctx.basic.i64 |] in
    let alloc_fun = Llvm.declare_function "GC_malloc" alloc_fty ctx.ll_module in
    Llvm.build_call alloc_fty alloc_fun [| Llvm.size_of ty |] name builder

let build_gc_array_alloc ctx ty length name builder =
    let alloc_fty = Llvm.function_type ctx.basic.ptr [| ctx.basic.i64 |] in
    let alloc_fun = Llvm.declare_function "GC_malloc" alloc_fty ctx.ll_module in
    Llvm.build_call alloc_fty alloc_fun [| Llvm.build_mul (Llvm.size_of ty) (Llvm.build_sext_or_bitcast length ctx.basic.i64 "" builder) "" builder |] name builder