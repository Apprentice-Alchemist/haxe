package haxe.ds;

import python.Dict;
import python.Syntax;

class Int64Map<T> implements haxe.Constraints.IMap<haxe.Int64, T> {
	private var h:Dict<haxe.Int64, T>;

	public function new():Void {
		h = new Dict();
	}

	public function set(key:haxe.Int64, value:T):Void {
		h.set(key, value);
	}

	public inline function get(key:haxe.Int64):Null<T> {
		return h.get(key, null);
	}

	public inline function exists(key:haxe.Int64):Bool {
		return h.hasKey(key);
	}

	public function remove(key:haxe.Int64):Bool {
		if (!h.hasKey(key))
			return false;
		Syntax.delete(Syntax.arrayAccess(h, key));
		return true;
	}

	public function keys():Iterator<haxe.Int64> {
		return h.keys().iter();
	}

	public function iterator():Iterator<T> {
		return h.values().iter();
	}

	@:runtime public inline function keyValueIterator():KeyValueIterator<haxe.Int64, T> {
		return new haxe.iterators.MapKeyValueIterator(this);
	}

	public function copy():Int64Map<T> {
		var copied = new Int64Map();
		for (key in keys())
			copied.set(key, get(key));
		return copied;
	}

	public function toString():String {
		var s = new StringBuf();
		s.add("[");
		var it = keys();
		for (i in it) {
			s.add(i);
			s.add(" => ");
			s.add(Std.string(get(i)));
			if (it.hasNext())
				s.add(", ");
		}
		s.add("]");
		return s.toString();
	}

	public inline function clear():Void {
		h.clear();
	}
	
	public inline function size():Int {
		return h.length;
	}
}
