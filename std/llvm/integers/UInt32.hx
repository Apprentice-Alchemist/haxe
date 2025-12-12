package llvm.integers;

@:integer
@:coreType abstract UInt32 to Int from UInt {
	@:op(A++) private function postinc(): UInt32;
	@:op(++A) private function preinc(): UInt32;
	@:op(A--) private function postdec(): UInt32;
	@:op(--A) private function predec(): UInt32;
	@:op(-A) private function neg(): UInt32;
	@:op(A + B) private function add(b: UInt32): UInt32;
	@:op(A - B) private function sub(b: UInt32): UInt32;
	@:op(A * B) private function mul(b: UInt32): UInt32;
	@:op(A / B) private function div(b: UInt32): UInt32;
	@:op(A % B) private function rem(b: UInt32): UInt32;
	@:op(A << B) private function shl(b: UInt32): UInt32;
	@:op(A >> B) private function ushr(b: UInt32): UInt32;
	@:op(A | B) private function or(b: UInt32): UInt32;
	@:op(A & B) private function and(b: UInt32): UInt32;
	@:op(A ^ B) private function xor(b: UInt32): UInt32;
	@:op(~A) private function not(): UInt32;

	@:op(A == B) private function eq(b: UInt32): Bool;
	@:op(A != B) private function neq(b: UInt32): Bool;
	@:op(A > B) private function gt(b: UInt32): Bool;
	@:op(A >= B) private function gteq(b: UInt32): Bool;
	@:op(A < B) private function lt(b: UInt32): Bool;
	@:op(A <= B) private function lteq(b: UInt32): Bool;
	@:op(A < B) private function lessThanInt(b:Int):Bool {
		return this < (cast b : UInt32);
	}

	@:op(A <= B) private function lessThanOrEqInt(b:Int):Bool {
		return this <= (cast b : UInt32);
	}

	@:op(A > B) private function greaterThanInt(b:Int):Bool {
		return this > (cast b : UInt32);
	}

	@:op(A >= B) private function greaterThanOrEqInt(b:Int):Bool {
		return this >= (cast b : UInt32);
	}
}