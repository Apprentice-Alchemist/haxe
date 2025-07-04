package haxe.atomic;

#if doc_gen
@:coreType
abstract AtomicObject<T:{}> {
	public function new(value:T):Void;

	public function compareExchange(expected:T, replacement:T):T;

	public function exchange(value:T):T;

	public function load():T;

	public function store(value:T):T;
}
#else
@:pythonImport("haxe_atomic", "AtomicObject")
extern class AtomicObject<T> {
	public function new(value:T):Void;
	@:native("compare_exchange")
	public function compareExchange(expected:T, replacement:T):T;
	public function exchange(value:T):T;
	public function load():T;
	public function store(value:T):T;
}
#end
