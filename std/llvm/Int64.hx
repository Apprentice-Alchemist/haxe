package llvm;

@:integer
@:runtimeValue
@:coreType abstract Int64 {
	@:op(A++) private function postinc(): Int64;
	@:op(++A) private function preinc(): Int64;
	@:op(A--) private function postdec(): Int64;
	@:op(--A) private function predec(): Int64;
	@:op(-A) private function neg(): Int64;
	@:op(A + B) private function add(b: Int64): Int64;
	@:op(A - B) private function sub(b: Int64): Int64;
	@:op(A * B) private function mul(b: Int64): Int64;
	@:op(A / B) private function div(b: Int64): Int64;
	@:op(A % B) private function rem(b: Int64): Int64;
	@:op(A << B) private function shl(b: Int64): Int64;
	@:op(A >> B) private function ashr(b: Int64): Int64;
	@:op(A >>> B) private function ushr(b: Int64): Int64;
	@:op(A | B) private function or(b: Int64): Int64;
	@:op(A & B) private function and(b: Int64): Int64;
	@:op(A ^ B) private function xor(b: Int64): Int64;
	@:op(~A) private function not(): Int64;

	@:op(A == B) private function eq(b: Int64): Bool;
	@:op(A != B) private function neq(b: Int64): Bool;
	@:op(A > B) private function gt(b: Int64): Bool;
	@:op(A >= B) private function gteq(b: Int64): Bool;
	@:op(A < B) private function lt(b: Int64): Bool;
	@:op(A <= B) private function lteq(b: Int64): Bool;
}