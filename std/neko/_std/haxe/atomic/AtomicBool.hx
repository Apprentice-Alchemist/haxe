package haxe.atomic;

#if doc_gen
@:coreApi
@:coreType
abstract AtomicBool {
	public function new(value:Bool):Void;

	public function compareExchange(expected:Bool, replacement:Bool):Bool;

	public function exchange(value:Bool):Bool;

	public function load():Bool;

	public function store(value:Bool):Bool;
}
#else
@:allow(haxe.atomic)
abstract AtomicBool(Dynamic) {
	public inline function new(value:Bool):Void {
		this = AtomicObject.make_atomic(value);
	}

	public inline function compareExchange(expected:Bool, replacement:Bool):Bool {
		return AtomicObject.atomic_compare_exchange(this, expected, replacement);
	}

	public inline function exchange(value:Bool):Bool {
		return AtomicObject.atomic_exchange(this, value);
	}

	public inline function load():Bool {
		return AtomicObject.atomic_load(this);
	}

	public inline function store(value:Bool):Bool {
		return AtomicObject.atomic_store(this, value);
	}
}
#end
