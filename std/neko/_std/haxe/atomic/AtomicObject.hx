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
@:allow(haxe.atomic)
abstract AtomicObject<T:{}>(Dynamic) {
	public inline function new(value:T):Void {
		this = make_atomic(value);
	}

	public inline function compareExchange(expected:T, replacement:T):T {
		return atomic_compare_exchange(this, expected, replacement);
	}

	public inline function exchange(value:T):T {
		return atomic_exchange(this, value);
	}

	public inline function load():T {
		return atomic_load(this);
	}

	public inline function store(value:T):T {
		return atomic_store(this, value);
	}

	private static var make_atomic:(Dynamic)->Dynamic = neko.Lib.loadLazy("std", "make_atomic", 1);
	private static var atomic_load:(Dynamic)->Dynamic = neko.Lib.loadLazy("std", "atomic_load", 1);
	private static var atomic_store:(Dynamic, Dynamic)->Dynamic = neko.Lib.loadLazy("std", "atomic_store", 2);
	private static var atomic_exchange:(Dynamic, Dynamic) -> Dynamic = neko.Lib.loadLazy("std", "atomic_exchange", 2);
	private static var atomic_compare_exchange:(Dynamic, Dynamic, Dynamic) -> Dynamic = neko.Lib.loadLazy("std", "atomic_compare_exchange", 3);
}
#end
