package llvm;

@:coreType extern abstract TypeInfo {
	@:llvm.builtin(type_info_of_dynamic)
	public static function ofDynamic(val: Dynamic): TypeInfo;

	@:llvm.builtin(type_info_base_type)
	public function type(): llvm.BaseType;
	
	@:llvm.builtin(type_info_kind)
	public function kind(): TypeKind;
}

enum abstract TypeKind(Int) {
	var Void = 0;
	var Bool = 1;
	var Int = 2;
	var Float32 = 3;
	var Float64 = 4;
	var Ptr = 5;
	var Closure = 6;
	var Null = 7;
	var Dynamic = 8;
	var Object = 9;
	var EnumInstance = 10;
	var TypeInfo = 11;
	var DynObj = 12;
	var Slice = 13;
	var Struct = 14;
}