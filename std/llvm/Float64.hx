package llvm;

@:coreType abstract Float64 from Float to Float {
	@:llvm.builtin(f64_from_bits)
	public static function fromBits(val:UInt64):Float32;

	@:llvm.builtin(f64_to_bits)
	public function toBits():UInt64;

	@:llvm.builtin(f64_to_f32)
	public function toFloat32(): Float32;
}