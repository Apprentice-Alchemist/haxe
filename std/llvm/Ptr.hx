package llvm;

@:coreType @:runtimeValue abstract Ptr<T> {
	@:arrayAccess private function get(idx: Int): T;
	@:arrayAccess private function set(idx: Int, value: T): T;

	public extern static function ref<T>(v: T): Ptr<T>;

	public extern static function alloc<T>(count: Int): Ptr<T>;
	public extern function copyFrom(src: Ptr<T>, length: Int): Void;
	public extern function offset(offset: Int): Ptr<T>;
}