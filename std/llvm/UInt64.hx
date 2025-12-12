package llvm;

@:integer
@:coreType abstract UInt64 from Int {
	@:op(A++) private function postinc(): UInt64;
	@:op(++A) private function preinc(): UInt64;
	@:op(A--) private function postdec(): UInt64;
	@:op(--A) private function predec(): UInt64;
	@:op(-A) private function neg(): UInt64;
	@:op(A + B) private function add(b: UInt64): UInt64;
	@:op(A - B) private function sub(b: UInt64): UInt64;
	@:op(A * B) private function mul(b: UInt64): UInt64;
	@:op(A / B) private function div(b: UInt64): UInt64;
	@:op(A % B) private function rem(b: UInt64): UInt64;
	@:op(A << B) private function shl(b: UInt64): UInt64;
	@:op(A >> B) private function ushr(b: UInt64): UInt64;
	@:op(A | B) private function or(b: UInt64): UInt64;
	@:op(A & B) private function and(b: UInt64): UInt64;
	@:op(A ^ B) private function xor(b: UInt64): UInt64;
	@:op(~A) private function not(): UInt64;

	@:op(A == B) private function eq(b: UInt64): Bool;
	@:op(A != B) private function neq(b: UInt64): Bool;
	@:op(A > B) private function gt(b: UInt64): Bool;
	@:op(A >= B) private function gteq(b: UInt64): Bool;
	@:op(A < B) private function lt(b: UInt64): Bool;
	@:op(A <= B) private function lteq(b: UInt64): Bool;

	@:op(A < B) private function lessThanInt(b:Int):Bool {
		return this < (cast b : UInt64);
	}

	@:op(A <= B) private function lessThanOrEqInt(b:Int):Bool {
		return this <= (cast b : UInt64);
	}

	@:op(A > B) private function greaterThanInt(b:Int):Bool {
		return this > (cast b : UInt64);
	}

	@:op(A >= B) private function greaterThanOrEqInt(b:Int):Bool {
		return this >= (cast b : UInt64);
	}
}