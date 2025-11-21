package js.lib;

import js.lib.intl.NumberFormat.NumberFormatOptions;

@:native("BigInt")
@:coreType extern abstract BigInt {
	static function asIntN(bits: Int, bigint: BigInt):BigInt;
	static function asUintN(bits: Int, bigint: BigInt):BigInt;

	@:selfCall extern overload function new(value: BigInt);
	@:selfCall extern overload function new(value: Int);
	@:selfCall extern overload function new(value: Bool);
	@:selfCall extern overload function new(value: String);

	@:op(A + B) private function add(b: BigInt): BigInt;
	@:op(A - B) private function sub(b: BigInt): BigInt;
	@:op(A * B) private function mul(b: BigInt): BigInt;
	@:op(A / B) private function div(b: BigInt): BigInt;
	@:op(A % B) private function rem(b: BigInt): BigInt;

	inline function pow(exp: BigInt): BigInt {
		return js.Syntax.code("{0} ** {1}", this, exp);
	}

	@:op(A >> B) private function shr(b: BigInt): BigInt;
	@:op(A << B) private function shl(b: BigInt): BigInt;
	@:op(A & B) private function bitAnd(b: BigInt): BigInt;
	@:op(A | B) private function bitOr(b: BigInt): BigInt;
	@:op(A ^ B) private function bitXor(b: BigInt): BigInt;
	@:op(~A) private function bitNeg(): BigInt;

	@:op(-A) private function neg(): BigInt;

	@:op(++A) private function preIncr(): BigInt;
	@:op(A++) private function postIncr(): BigInt;
	@:op(--A) private function preDecr(): BigInt;
	@:op(A--) private function postDecr(): BigInt;

	@:op(A == B) private function eq(v:BigInt):Bool;
	@:op(A != B) private function neq(v:BigInt):Bool;
	@:op(A >= B) private function gte(v:BigInt):Bool;
	@:op(A <= B) private function lte(v:BigInt):Bool;
	@:op(A > B) private function gt(v:BigInt):Bool;
	@:op(A < B) private function lt(v:BigInt):Bool;

	@:pure overload extern inline function toLocaleString(?locales:String, ?options:NumberFormatOptions):String {
		return (this:Dynamic).toLocaleString(locales, options);
	}
	@:pure overload extern inline function toLocaleString(?locales:Array<String>, ?options:NumberFormatOptions):String {
		return (this:Dynamic).toLocaleString(locales, options);
	}
	@:pure extern inline function toString(): String {
		return (this:Dynamic).toString();
	}
}