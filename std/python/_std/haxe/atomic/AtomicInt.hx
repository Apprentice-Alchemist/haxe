package haxe.atomic;

#if doc_gen
@:coreApi
@:coreType
abstract AtomicInt {
	public function new(value:Int):Void;

	public function add(b:Int):Int;

	public function sub(b:Int):Int;

	public function and(b:Int):Int;

	public function or(b:Int):Int;

	public function xor(b:Int):Int;

	public function compareExchange(expected:Int, replacement:Int):Int;

	public function exchange(value:Int):Int;

	public function load():Int;

	public function store(value:Int):Int;
}
#else
@:pythonImport("haxe_atomic", "AtomicInt")
extern class AtomicInt {
	public function new(value:Int):Void;
	@:native("fetch_add")
	public function add(b:Int):Int;
	@:native("fetch_sub")
	public function sub(b:Int):Int;
	@:native("fetch_and")
	public function and(b:Int):Int;
	@:native("fetch_or")
	public function or(b:Int):Int;
	@:native("fetch_xor")
	public function xor(b:Int):Int;
	@:native("compare_exchange")
	public function compareExchange(expected:Int, replacement:Int):Int;
	public function exchange(value:Int):Int;
	public function load():Int;
	public function store(value:Int):Int;
}
#end
