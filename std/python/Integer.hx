package python;

@:defaultValue(0)
@:coreType @:notNull @:runtimeValue abstract Integer from Int to Int {
	@:op(A + B) function add(v:Integer):Integer;

	@:op(A - B) function sub(v:Integer):Integer;

	@:op(A * B) function mul(v:Integer):Integer;

	@:op(A / B) function div(v:Integer):Integer;

	@:op(A % B) function mod(v:Integer):Integer;

	@:op(A << B) function shl(v:Int):Integer;

	@:op(A >> B) function shr(v:Int):Integer;

	@:op(A | B) function or(v:Integer):Integer;

	@:op(A & B) function and(v:Integer):Integer;

	@:op(A ^ B) function xor(v:Integer):Integer;

	@:op(-A) function neg():Integer;

	@:op(~A) function compl():Integer;

	@:op(++A) function incr():Integer;

	@:op(--A) function decr():Integer;

	@:op(A++) function pincr():Integer;

	@:op(A--) function pdecr():Integer;

	@:op(A == B) function eq(v:Integer):Bool;

	@:op(A >= B) function gte(v:Integer):Bool;

	@:op(A <= B) function lte(v:Integer):Bool;

	@:op(A > B) function gt(v:Integer):Bool;

	@:op(A < B) function lt(v:Integer):Bool;
}
