package llvm;

@:coreType abstract Slice<T> {
	@:llvm.builtin(slice_new)
	public function new(length: Int);
	@:llvm.builtin(slice_ptr)
	public function ptr(): llvm.Ptr<T>;

	@:llvm.builtin(slice_length)
	public function length(): Int;
	@:arrayAccess private function get(i: Int): T;
	@:arrayAccess private function set(i: Int, value: T): T;
}