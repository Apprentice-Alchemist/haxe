package haxe;

import python.Syntax;
import haxe.Int64Helper;

using haxe.Int64;

private typedef __Int64 = python.Integer;

@:coreApi
@:transitive
abstract Int64(__Int64) from __Int64 to __Int64 {
	public static inline function make(high:Int32, low:Int32):Int64
		return new Int64(((high : __Int64) << 32) | ((low : __Int64) & Syntax.code("0xFFFFFFFF")));

	private inline function new(x:__Int64)
		this = clamp(x);

	private var val(get, set):__Int64;

	inline function get_val():__Int64
		return this;

	inline function set_val(x:__Int64):__Int64
		return this = x;

	public var high(get, never):Int32;

	inline function get_high():Int32
		return @:privateAccess Int32.clamp((this >> 32 : haxe.Int32) & Syntax.code("0xFFFFFFFF"));

	public var low(get, never):Int32;

	inline function get_low():Int32
		return @:privateAccess Int32.clamp(this & Syntax.code("0xFFFFFFFF"));

	public inline function copy():Int64
		return new Int64(this);

	@:from public static inline function ofInt(x:Int):Int64
		return new Int64((x : __Int64));

	@:deprecated('haxe.Int64.is() is deprecated. Use haxe.Int64.isInt64() instead')
	inline public static function is(val:Dynamic):Bool
		return @:privateAccess python.Boot.isPyInt(val);

	inline public static function isInt64(val:Dynamic):Bool
		return @:privateAccess python.Boot.isPyInt(val);

	public static inline function toInt(x:Int64):Int {
		if (x.val < 0x80000000 || x.val > 0x7FFFFFFF)
			throw "Overflow";
		return cast x.val;
	}

	public static inline function getHigh(x:Int64):Int32
		return cast(x.val >> 32);

	public static inline function getLow(x:Int64):Int32
		return cast(x.val & 0xFFFFFFFF);

	public static inline function isNeg(x:Int64):Bool
		return x.val < 0;

	public static inline function isZero(x:Int64):Bool
		return x.val == 0;

	public static inline function compare(a:Int64, b:Int64):Int {
		if (a.val < b.val)
			return -1;
		if (a.val > b.val)
			return 1;
		return 0;
	}

	public static inline function ucompare(a:Int64, b:Int64):Int {
		if (a.val < 0)
			return (b.val < 0) ? compare(a, b) : 1;
		return (b.val < 0) ? -1 : compare(a, b);
	}

	public static inline function toStr(x:Int64):String
		return '${x.val}';

	public static inline function divMod(dividend:Int64, divisor:Int64):{quotient:Int64, modulus:Int64}
		return {quotient: dividend / divisor, modulus: dividend % divisor};

	public inline function toString():String
		return '$this';

	public static function parseString(sParam:String):Int64 {
		// can this be done?: return new Int64( java.lang.Long.LongClass.parseLong( sParam ) );
		return Int64Helper.parseString(sParam);
	}

	public static function fromFloat(f:Float):Int64 {
		return Int64Helper.fromFloat(f);
	}

	@:op(-A) public static function neg(x:Int64):Int64
		return clamp(-x.val);

	@:op(++A) private inline function preIncrement():Int64
		return this = clamp(++this);

	@:op(A++) private inline function postIncrement():Int64 {
		var ret = this
		++;
		this = clamp(this);
		return ret;
	}

	@:op(--A) private inline function preDecrement():Int64
		return this = clamp(--this);

	@:op(A--) private inline function postDecrement():Int64 {
		var ret = this
		--;
		this = clamp(this);
		return ret;
	}

	@:op(A + B) public static inline function add(a:Int64, b:Int64):Int64
		return clamp(a.val + b.val);

	@:op(A + B) @:commutative private static inline function addInt(a:Int64, b:Int):Int64
		return clamp(a.val + b);

	@:op(A - B) public static inline function sub(a:Int64, b:Int64):Int64
		return clamp(a.val - b.val);

	@:op(A - B) private static inline function subInt(a:Int64, b:Int):Int64
		return clamp(a.val - b);

	@:op(A - B) private static inline function intSub(a:Int, b:Int64):Int64
		return clamp(a - b.val);

	static var MASK_32:python.Integer = python.Syntax.code("0xFFFFFFFF");

	@:op(A * B) public static inline function mul(a:Int64, b:Int64):Int64
		return clamp((a.val) * ((b.val) & MASK_32) + clamp((a.val) * ((b.val % (python.Syntax.opPow(2, 64))) >> 32) << 32));

	@:op(A * B) @:commutative private static inline function mulInt(a:Int64, b:Int):Int64
		return a.val * b;

	@:op(A / B) public static inline function div(a:Int64, b:Int64):Int64 {
		var ret = python.lib.Builtins.divmod(a.val, b.val);
		if (ret._1 < 0 && ret._2 != 0)
			return ret._1 + 1;
		else
			return ret._1;
	}

	@:op(A / B) private static inline function divInt(a:Int64, b:Int):Int64 {
		var ret = python.lib.Builtins.divmod(a.val, b);
		if (ret._1 < 0 && ret._2 != 0)
			return ret._1 + 1;
		else
			return ret._1;
	}

	@:op(A / B) private static inline function intDiv(a:Int, b:Int64):Int64 {
		var ret = python.lib.Builtins.divmod(a, b.val);
		if (ret._1 < 0 && ret._2 != 0)
			return ret._1 + 1;
		else
			return ret._1;
	}

	@:op(A % B) public static inline function mod(a:Int64, b:Int64):Int64
		return a.val % b.val;

	@:op(A % B) private static inline function modInt(a:Int64, b:Int):Int64
		return a.val % b;

	@:op(A % B) private static inline function intMod(a:Int, b:Int64):Int64
		return a % b.val;

	@:op(A == B) public static inline function eq(a:Int64, b:Int64):Bool
		return a.val == b.val;

	@:op(A == B) @:commutative private static inline function eqInt(a:Int64, b:Int):Bool
		return a.val == b;

	@:op(A != B) public static inline function neq(a:Int64, b:Int64):Bool
		return a.val != b.val;

	@:op(A != B) @:commutative private static inline function neqInt(a:Int64, b:Int):Bool
		return a.val != b;

	@:op(A < B) private static inline function lt(a:Int64, b:Int64):Bool
		return a.val < b.val;

	@:op(A < B) private static inline function ltInt(a:Int64, b:Int):Bool
		return a.val < (b:__Int64);

	@:op(A < B) private static inline function intLt(a:Int, b:Int64):Bool
		return (a : __Int64) < b.val;

	@:op(A <= B) private static inline function lte(a:Int64, b:Int64):Bool
		return a.val <= b.val;

	@:op(A <= B) private static inline function lteInt(a:Int64, b:Int):Bool
		return a.val <= (b : __Int64);

	@:op(A <= B) private static inline function intLte(a:Int, b:Int64):Bool
		return (a : __Int64) <= b.val;

	@:op(A > B) private static inline function gt(a:Int64, b:Int64):Bool
		return a.val > b.val;

	@:op(A > B) private static inline function gtInt(a:Int64, b:Int):Bool
		return a.val > (b : __Int64);

	@:op(A > B) private static inline function intGt(a:Int, b:Int64):Bool
		return (a : __Int64) > b.val;

	@:op(A >= B) private static inline function gte(a:Int64, b:Int64):Bool
		return a.val >= b.val;

	@:op(A >= B) private static inline function gteInt(a:Int64, b:Int):Bool
		return a.val >= (b : __Int64);

	@:op(A >= B) private static inline function intGte(a:Int, b:Int64):Bool
		return (a : __Int64) >= b.val;

	@:op(~A) private static inline function complement(x:Int64):Int64
		return clamp(~x.val);

	@:op(A & B) public static inline function and(a:Int64, b:Int64):Int64
		return a.val & b.val;

	@:op(A | B) public static inline function or(a:Int64, b:Int64):Int64
		return clamp(a.val | b.val);

	@:op(A ^ B) public static inline function xor(a:Int64, b:Int64):Int64
		return clamp(a.val ^ b.val);

	@:op(A << B) public static inline function shl(a:Int64, b:Int):Int64
		return clamp(a.val << (b & 63));

	@:op(A >> B) public static inline function shr(a:Int64, b:Int):Int64
		return clamp(a.val >> (b & 63));

	@:op(A >>> B) public static inline function ushr(a:Int64, b:Int):Int64
		return clamp((python.Syntax.binop(a.val, "%", (python.Syntax.opPow(2, 64)))) >> (b & 63));

	static inline function clamp(val:Int):Int {
		final ceil = python.Syntax.opPow(2, 63);
		return (python.Syntax.code("{0} % {1}", (val + ceil), python.Syntax.opPow(2, 64)) : Int) - ceil;
	}
}
