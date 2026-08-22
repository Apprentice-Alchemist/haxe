open Globals
open Type

let check_field_type_params (scom: SafeCom.t) (e: texpr) =
    let rec check_param_constraints map params tl p =
        match params, tl with
            | ttp :: ttp_rest, t :: t_rest ->
                List.iter (fun ti ->
                    let ti = map ti in
                    Typecore.unify_raise t ti p
                ) (TFunctions.get_constraints ttp)
            | [], [] -> ()
            | _ :: _, [] ->
                SafeCom.add_error scom (Error.make_error (Custom "not enough type parameters") p)
            | [], _ :: _ ->
                SafeCom.add_error scom (Error.make_error (Custom "too many type parameters") p)

    in
    let rec loop e = match e.eexpr with
        TField (e1, access) ->
            begin
                match access with
                    | FInstance (c, tl, cf, cf_params)
                    | FClosure (Some (c, tl), cf, cf_params) ->
                        check_param_constraints (fun t -> apply_params cf.cf_params cf_params t |> apply_params c.cl_params tl ) cf.cf_params cf_params e.epos;
                    (* TODO TP: figure out how to get the type params in order to be able to check constraints *)
                    | FStatic ({cl_kind = KAbstractImpl ({a_params = _ :: _ }) }, _, _) -> ()
                    | FStatic (_, cf, cf_params) ->
                        check_param_constraints (fun t -> apply_params cf.cf_params cf_params t) cf.cf_params cf_params e.epos;
                    | FAnon (cf, cf_params)
                    | FClosure (None, cf, cf_params) ->
                        check_param_constraints (fun t -> apply_params cf.cf_params cf_params t) cf.cf_params cf_params e.epos;
                    | FDynamic _ | FEnum _-> ()
            end;
            loop e1
        | _ -> iter loop e
    in loop e; e