package llvm.integers;

@:integer
@:runtimeValue
@:coreType abstract Int8 {
	@:op(A++) private function postinc(): Int8;
	@:op(++A) private function preinc(): Int8;
	@:op(A--) private function postdec(): Int8;
	@:op(--A) private function predec(): Int8;
	@:op(-A) private function neg(): Int8;
	@:op(A + B) private function add(b: Int8): Int8;
	@:op(A - B) private function sub(b: Int8): Int8;
	@:op(A * B) private function mul(b: Int8): Int8;
	@:op(A / B) private function div(b: Int8): Int8;
	@:op(A % B) private function rem(b: Int8): Int8;
	@:op(A << B) private function shl(b: Int8): Int8;
	@:op(A >> B) private function ashr(b: Int8): Int8;
	@:op(A >>> B) private function ushr(b: Int8): Int8;
	@:op(A | B) private function or(b: Int8): Int8;
	@:op(A & B) private function and(b: Int8): Int8;
	@:op(A ^ B) private function xor(b: Int8): Int8;
	@:op(~A) private function not(): Int8;

	@:op(A == B) private function eq(b: Int8): Bool;
	@:op(A != B) private function neq(b: Int8): Bool;
	@:op(A > B) private function gt(b: Int8): Bool;
	@:op(A >= B) private function gteq(b: Int8): Bool;
	@:op(A < B) private function lt(b: Int8): Bool;
	@:op(A <= B) private function lteq(b: Int8): Bool;
}