package llvm;

@:integer
@:coreType abstract UInt8 to Int {
	@:op(A + B) private function add(b: UInt8): UInt8;
	@:op(A < B) private function lessThan(b: UInt8):Bool;
	@:op(A <= B) private function lessThanOrEq(b: UInt8):Bool;
	@:op(A > B) private function greaterThan(b: UInt8):Bool;
	@:op(A >= B) private function greaterThanOrEq(b: UInt8):Bool;
	@:op(A < B) private function lessThanInt(b: Int):Bool {
		return this < (cast b: UInt8);
	}
	@:op(A <= B) private function lessThanOrEqInt(b: Int):Bool {
		return this <= (cast b: UInt8);
	}
	@:op(A > B) private function greaterThanInt(b: Int):Bool {
		return this > (cast b: UInt8);
	}
	@:op(A >= B) private function greaterThanOrEqInt(b: Int):Bool {
		return this >= (cast b: UInt8);
	}

	@:op(A | B) private function or(b: llvm.UInt8): llvm.UInt8;
	@:op(A & B) private function and(b: llvm.UInt8): llvm.UInt8;
	@:op(A << B) private function ishl(by: Int): llvm.UInt8;

	@:llvm.builtin(u8_cmp)
	public function compare(b: UInt8): Int;
}