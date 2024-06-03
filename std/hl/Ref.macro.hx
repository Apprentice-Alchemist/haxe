package hl;

import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;

@:noPackageRestrict
@:coreType abstract Ref<T> {
	/**
		Take reference to the field of an object.
		Usage: ```
			hl.Ref.fieldRef(obj.a);
		```
	**/
	public static macro function fieldRef(expr:Expr):Expr {
		switch expr.expr {
			case EField(_, _, _):
			case _:
				Context.error("Expected field access expression", expr.pos);
		}

		final pos:Position = Context.currentPos();
		final typedFieldExpr:TypedExpr = Context.typeExpr(expr);

		var valType:Type = typedFieldExpr.t;
		var refType:Type = switch Context.getType("hl.Ref") {
			case TAbstract(t, _): TAbstract(t, [valType]);
			case _: Context.error("hl.Ref is not an abstract", pos);
		};

		switch typedFieldExpr.expr {
			case TField(e, FDynamic(s)):
				final expectedType = Context.getExpectedType();
				switch expectedType {
					case TAbstract(_.get() => {pack: ["hl"], name: "Ref"}, [param]):
						refType = expectedType;
						valType = param;
					case null, TMono(_):
						Context.error("Taking reference to a field of a dynamic requires an explicit type hint", pos);
					case _:
						// this case will fail later
				}
			case _:
		}

		final typedExpr:TypedExpr = {
			expr: TCall({
				expr: TIdent("$ref"),
				pos: pos,
				t: TFun([{name: "v", opt: false, t: valType}], refType)
			}, [typedFieldExpr]),
			t: refType,
			pos: pos,
		};

		return Context.storeTypedExpr(typedExpr);
	}
}
