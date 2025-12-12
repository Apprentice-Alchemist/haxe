package llvm.integers;

@:integer
@:runtimeValue
@:coreType abstract Int32 {
	@:op(A++) private function postinc(): Int32;
	@:op(++A) private function preinc(): Int32;
	@:op(A--) private function postdec(): Int32;
	@:op(--A) private function predec(): Int32;
	@:op(-A) private function neg(): Int32;
	@:op(A + B) private function add(b: Int32): Int32;
	@:op(A - B) private function sub(b: Int32): Int32;
	@:op(A * B) private function mul(b: Int32): Int32;
	@:op(A / B) private function div(b: Int32): Int32;
	@:op(A % B) private function rem(b: Int32): Int32;
	@:op(A << B) private function shl(b: Int32): Int32;
	@:op(A >> B) private function ashr(b: Int32): Int32;
	@:op(A >>> B) private function ushr(b: Int32): Int32;
	@:op(A | B) private function or(b: Int32): Int32;
	@:op(A & B) private function and(b: Int32): Int32;
	@:op(A ^ B) private function xor(b: Int32): Int32;
	@:op(~A) private function not(): Int32;

	@:op(A == B) private function eq(b: Int32): Bool;
	@:op(A != B) private function neq(b: Int32): Bool;
	@:op(A > B) private function gt(b: Int32): Bool;
	@:op(A >= B) private function gteq(b: Int32): Bool;
	@:op(A < B) private function lt(b: Int32): Bool;
	@:op(A <= B) private function lteq(b: Int32): Bool;
}