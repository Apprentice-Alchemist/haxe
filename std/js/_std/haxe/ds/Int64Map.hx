package haxe.ds;

@:coreApi class Int64Map<T> implements haxe.Constraints.IMap<Int64, T> {
	private var m:js.lib.Map<Int64, T>;

	public inline function new():Void {
		m = new js.lib.Map();
	}

	public inline function set(key:Int64, value:T):Void {
		m.set(key, value);
	}

	public inline function get(key:Int64):Null<T> {
		return m.get(key);
	}

	public inline function exists(key:Int64):Bool {
		return m.has(key);
	}

	public inline function remove(key:Int64):Bool {
		return m.delete(key);
	}

	public inline function keys():Iterator<Int64> {
		return new js.lib.HaxeIterator(m.keys());
	}

	public inline function iterator():Iterator<T> {
		return m.iterator();
	}

	public inline function keyValueIterator():KeyValueIterator<Int64, T> {
		return m.keyValueIterator();
	}

	public inline function copy():Int64Map<T> {
		var copied = new Int64Map();
		copied.m = new js.lib.Map(m);
		return copied;
	}

	public function toString():String {
		var s = new StringBuf();
		s.add("[");
		var it = keyValueIterator();
		for (i in it) {
			s.add(i.key);
			s.add(" => ");
			s.add(Std.string(i.value));
			if (it.hasNext())
				s.add(", ");
		}
		s.add("]");
		return s.toString();
	}

	public inline function clear():Void {
		m.clear();
	}

	public inline function size():Int {
		return m.size;
	}
}