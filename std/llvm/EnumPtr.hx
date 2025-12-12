package llvm;

@:coreType abstract EnumPtr {
	@:llvm.builtin(enum_type)
	public function type(): llvm.BaseType.BaseEnum;
	@:llvm.builtin(enum_index)
	public function index(): Int;
}