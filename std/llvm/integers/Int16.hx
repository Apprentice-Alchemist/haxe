package llvm.integers;

@:integer
@:runtimeValue
@:coreType abstract Int16 {
	@:op(A++) private function postinc(): Int16;
	@:op(++A) private function preinc(): Int16;
	@:op(A--) private function postdec(): Int16;
	@:op(--A) private function predec(): Int16;
	@:op(-A) private function neg(): Int16;
	@:op(A + B) private function add(b: Int16): Int16;
	@:op(A - B) private function sub(b: Int16): Int16;
	@:op(A * B) private function mul(b: Int16): Int16;
	@:op(A / B) private function div(b: Int16): Int16;
	@:op(A % B) private function rem(b: Int16): Int16;
	@:op(A << B) private function shl(b: Int16): Int16;
	@:op(A >> B) private function ashr(b: Int16): Int16;
	@:op(A >>> B) private function ushr(b: Int16): Int16;
	@:op(A | B) private function or(b: Int16): Int16;
	@:op(A & B) private function and(b: Int16): Int16;
	@:op(A ^ B) private function xor(b: Int16): Int16;
	@:op(~A) private function not(): Int16;

	@:op(A == B) private function eq(b: Int16): Bool;
	@:op(A != B) private function neq(b: Int16): Bool;
	@:op(A > B) private function gt(b: Int16): Bool;
	@:op(A >= B) private function gteq(b: Int16): Bool;
	@:op(A < B) private function lt(b: Int16): Bool;
	@:op(A <= B) private function lteq(b: Int16): Bool;
}