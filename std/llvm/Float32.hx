package llvm;

@:coreType abstract Float32 from Single to Single {
	@:llvm.builtin(f32_from_bits)
	public static function fromBits(val: UInt32): Float32;
	@:llvm.builtin(f32_to_bits)
	public function toBits(): UInt32;

	@:llvm.builtin(f32_to_f64)
	@:to public function toFloat64(): Float64;
}