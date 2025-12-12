package llvm.integers;

@:integer
@:coreType abstract UInt16 to Int {
	@:op(A++) private function postinc(): UInt16;
	@:op(++A) private function preinc(): UInt16;
	@:op(A--) private function postdec(): UInt16;
	@:op(--A) private function predec(): UInt16;
	@:op(-A) private function neg(): UInt16;
	@:op(A + B) private function add(b: UInt16): UInt16;
	@:op(A - B) private function sub(b: UInt16): UInt16;
	@:op(A * B) private function mul(b: UInt16): UInt16;
	@:op(A / B) private function div(b: UInt16): UInt16;
	@:op(A % B) private function rem(b: UInt16): UInt16;
	@:op(A << B) private function shl(b: UInt16): UInt16;
	@:op(A >> B) private function ushr(b: UInt16): UInt16;
	@:op(A | B) private function or(b: UInt16): UInt16;
	@:op(A & B) private function and(b: UInt16): UInt16;
	@:op(A ^ B) private function xor(b: UInt16): UInt16;
	@:op(~A) private function not(): UInt16;

	@:op(A == B) private function eq(b: UInt16): Bool;
	@:op(A != B) private function neq(b: UInt16): Bool;
	@:op(A > B) private function gt(b: UInt16): Bool;
	@:op(A >= B) private function gteq(b: UInt16): Bool;
	@:op(A < B) private function lt(b: UInt16): Bool;
	@:op(A <= B) private function lteq(b: UInt16): Bool;
}