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
@:pythonImport("haxe_atomic", "AtomicBool")
extern class AtomicBool {
	public function new(value:Bool):Void;
	@:native("compare_exchange")
	public function compareExchange(expected:Bool, replacement:Bool):Bool;
	public function exchange(value:Bool):Bool;
	public function load():Bool;
	public function store(value:Bool):Bool;
}
#end
