open Globals
open TType

type llvm_debug_ctx = {
    dibuilder: Llvm_debuginfo.lldibuilder;
    compile_unit: Llvm.llmetadata;
}

(* let create_type ctx ty =
    match LlType.ty_ with
        TFun s -> () *)

let create_pos ctx ll_ctx scope p =
    (* let f = Path.FilePath.parse p.pfile in *)
    (* let file = Llvm_debuginfo.dibuild_create_file ctx.dibuilder (Path.FilePath.name_and_extension f) (Option.default "" f.directory) in *)
    let line, column = Lexer.find_pos p in
    Llvm_debuginfo.dibuild_create_debug_location ll_ctx ~line ~column ~scope

let create_function (ctx: llvm_debug_ctx) linkage_name ((arg_types, ret_type): TType.tsignature) (p: Globals.pos) =
        let f = Path.FilePath.parse p.pfile in
        let file = Llvm_debuginfo.dibuild_create_file ctx.dibuilder (Path.FilePath.name_and_extension f) (Option.default "" f.directory) in
        let di_fun_ty = Llvm_debuginfo.dibuild_create_subroutine_type
            ctx.dibuilder
            ~file
            ~param_types: [||]
            (Llvm_debuginfo.diflags_get Zero)
        in
        let di_fun = Llvm_debuginfo.dibuild_create_function ctx.dibuilder
            ~scope: file
            ~name: linkage_name
            ~linkage_name
            ~file
            ~line_no: (Lexer.get_error_line p)
            ~ty: di_fun_ty
            ~is_local_to_unit: true
            ~is_definition: true
            ~scope_line: (Lexer.get_error_line p)
            ~flags: (Llvm_debuginfo.diflags_get Zero)
            ~is_optimized: false in
        di_fun