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
abstract AtomicInt(Dynamic) {
	public inline function new(value:Int):Void {
		this = AtomicObject.make_atomic(value);
	}

	public inline function add(b:Int):Int {
		return fetch_update(this, (a) -> a + b);
	}

	public inline function sub(b:Int):Int {
		return fetch_update(this, (a) -> a - b);
	}

	public inline function and(b:Int):Int {
		return fetch_update(this, (a) -> a & b);
	}

	public inline function or(b:Int):Int {
		return fetch_update(this, (a) -> a | b);
	}

	public inline function xor(b:Int):Int {
		return fetch_update(this, (a) -> a ^ b);
	}

	public inline function compareExchange(expected:Int, replacement:Int):Int {
		return AtomicObject.atomic_compare_exchange(this, expected, replacement);
	}

	public inline function exchange(value:Int):Int {
		return AtomicObject.atomic_exchange(this, value);
	}

	public inline function load():Int {
		return AtomicObject.atomic_load(this);
	}

	public inline function store(value:Int):Int {
		return AtomicObject.atomic_store(this, value);
	}

	private static var fetch_update = neko.Lib.loadLazy("std", "atomic_fetch_update", 2);
}
#end
