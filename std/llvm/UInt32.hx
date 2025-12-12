package llvm;

@:integer
@:coreType abstract UInt32 to Int from UInt {
	@:op(A / B) private function div(by: UInt32): UInt32;
	@:op(A % B) private function mod(by: UInt32): UInt32;
	@:op(A < B) private function lessThan(b:UInt32):Bool;

	@:op(A <= B) private function lessThanOrEq(b:UInt32):Bool;

	@:op(A > B) private function greaterThan(b:UInt32):Bool;

	@:op(A >= B) private function greaterThanOrEq(b:UInt32):Bool;

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