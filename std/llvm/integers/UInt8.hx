package llvm.integers;

@:integer
@:coreType abstract UInt8 to Int {
	@:op(A++) private function postinc(): UInt8;
	@:op(++A) private function preinc(): UInt8;
	@:op(A--) private function postdec(): UInt8;
	@:op(--A) private function predec(): UInt8;
	@:op(-A) private function neg(): UInt8;
	@:op(A + B) private function add(b: UInt8): UInt8;
	@:op(A - B) private function sub(b: UInt8): UInt8;
	@:op(A * B) private function mul(b: UInt8): UInt8;
	@:op(A / B) private function div(b: UInt8): UInt8;
	@:op(A % B) private function rem(b: UInt8): UInt8;
	@:op(A << B) private function shl(b: UInt8): UInt8;
	@:op(A << B) private function shlInt(b: Int): UInt8 {
		return this << (cast b: UInt8);
	}
	@:op(A >> B) private function ushr(b: UInt8): UInt8;
	@:op(A >> B) private function ushrInt(b: Int): UInt8 {
		return this >> (cast b: UInt8);
	}
	@:op(A | B) private function or(b: UInt8): UInt8;
	@:op(A & B) private function and(b: UInt8): UInt8;
	@:op(A ^ B) private function xor(b: UInt8): UInt8;
	@:op(~A) private function not(): UInt8;

	@:op(A == B) private function eq(b: UInt8): Bool;
	@:op(A != B) private function neq(b: UInt8): Bool;
	@:op(A > B) private function gt(b: UInt8): Bool;
	@:op(A >= B) private function gteq(b: UInt8): Bool;
	@:op(A < B) private function lt(b: UInt8): Bool;
	@:op(A <= B) private function lteq(b: UInt8): Bool;

	@:op(A < B) private function ltInt(b:Int):Bool {
		return this < (cast b : UInt8);
	}
	@:op(A <= B) private function lteqInt(b: Int): Bool {
		return this <= (cast b: UInt8);
	}

	@:llvm.builtin(u8_cmp)
	public function compare(b: UInt8): Int;
}