package;

import haxe.iterators.ArrayKeyValueIterator;

class Array<T> {
	public var length(default, null):Int;
	private var capacity: Int;
	private var data: llvm.Ptr<T>;

	public function new():Void {
		length = 0;
		capacity = 0;
		data = null;
	}

	function ensureCapacityFor(extra: Int) {
		var required = length + extra;
		if (capacity < required) {
			var newCapacity = capacity * 2;
			if (newCapacity < required) {
				newCapacity = required;
			}
			var newData:llvm.Ptr<T> = llvm.Ptr.alloc(newCapacity);
			newData.copyFrom(data, length);
			capacity = newCapacity;
			data = newData;
		}
	}

	function grow(newLength: Int) {
		if (capacity < newLength) {
			ensureCapacityFor(newLength - capacity);
			length = newLength;
		}
	}

	function get(i: Int): T {
		if (0 < i && i < length) {
			return data[i];
		} else {
			return null;
		}
	}

	function set(i: Int, value: T) {
		if (i < 0) {
			throw "negative index";
		}
		if (i >= length) {
			resize(i + 1);
		}
		data[i] = value;
	}

	public function concat(a:Array<T>):Array<T> {
		var newArray = new Array();
		newArray.grow(this.length + a.length);
		newArray.data.copyFrom(this.data, this.length);
		newArray.data.offset(this.length).copyFrom(a.data, a.length);
		return newArray;
	}

	public function join(sep:String):String {
		if (length == 0) {
			return "";
		} else if (length == 1) {
			return Std.string(data[0]);
		} else {
			var s = new StringBuf();
			for (i in 0...length) {
				if (i > 0) {
					s.add(sep);
				}
				s.add(Std.string(data[i]));
			}
			return s.toString();
		}
	}

	public function pop():Null<T> {
		if (length > 0) {
			var ret = data[length - 1];
			length -= 1;
			return ret;
		} else {
			return null;
		}
	}

	public function push(x:T):Int {
		ensureCapacityFor(1);
		data[length] = x;
		var idx = length;
		length += 1;
		return idx;
	}

	public function reverse():Void {
		var half_len = Std.int(length / 2);
		for (i in 0...half_len) {
			var tmp = data[i];
			data[i] = data[length - i - 1];
			data[length - i - 1] = tmp;
		}
	}

	public function shift():Null<T> {
		if (length > 0) {
			var ret = data[length - 1];
			length -= 1;
			data.copyFrom(data.offset(1), length);
			return ret;
		} else {
			return null;
		}
	}

	public function slice(pos:Int, ?end:Int):Array<T> {
		var ret = new Array();
		var pend: Int;
		if (end == null || (end: Int) > length) {
			pend = length;
		} else {
			pend = length - (end: Int);
		}
		var retLength = pend - pos;
		if (retLength > 0) {
			var retData = llvm.Ptr.alloc(retLength);
			retData.copyFrom(data.offset(pos), retLength);
			ret.data = retData;
			ret.length = retLength;
			ret.capacity = retLength;
		}
		return ret;
	}

	public function sort(f:T->T->Int):Void {
		haxe.ds.ArraySort.sort(this, f);
	}

	public function splice(pos:Int, len:Int):Array<T> {
		var ret = new Array();
		if (len == 0) {
			return ret;
		}
		var retData = llvm.Ptr.alloc(len);
		retData.copyFrom(data.offset(pos), len);
		data.copyFrom(data.offset(pos + len), length - len - pos);
		length -= len;
		ret.data = retData;
		ret.length = len;
		ret.capacity = len;
		return ret;
	}

	public function toString():String {
		var b = new StringBuf();
		b.addChar("[".code);
		for (i in 0...length) {
			if (i > 0)
				b.addChar(",".code);
			b.add(data[i]);
		}
		b.addChar("]".code);
		return b.toString();
	}

	public function unshift(x:T):Void {
		ensureCapacityFor(1);
		data.offset(1).copyFrom(data, length);
		data[0] = x;
		length += 1;
	}

	public function insert(pos:Int, x:T):Void {
		ensureCapacityFor(1);
		data.offset(pos + 1).copyFrom(data.offset(pos), length - pos);
		data[pos] = x;
		length += 1;
	}

	public function remove(x:T):Bool {
		final idx = indexOf(x);
		if (idx == -1) {
			return false;
		}
		length -= 1;
		data.offset(idx).copyFrom(data.offset(idx + 1), length - idx);
		return true;
	}

	@:pure public function contains( x : T ) : Bool {
		return indexOf(x) != -1;
	}

	public function indexOf(x:T, ?fromIndex:Int):Int {
		var fromIndex:Int = fromIndex ?? 0;
		var start = if (fromIndex < 0) length - fromIndex else fromIndex;
		if (start < 0) {
			start = 0;
		} else if (start > length) {
			return -1;
		}
		for (i in start...length) {
			if (data[i] == x) {
				return i;
			}
		}
		return -1;
	}

	public function lastIndexOf(x:T, ?fromIndex:Int):Int {
		var fromIndex = fromIndex ?? 0;
		for (i in 0...length) {
			var i = length - i - 1;
			if (data[i] == x) {
				return i;
			}
		}
		return -1;
	}

	public function copy():Array<T> {
		var ret = new Array();
		var retLength = length;
		var retData = llvm.Ptr.alloc(length);
		retData.copyFrom(data, length);
		ret.length = retLength;
		ret.capacity = retLength;
		ret.data = retData;
		return ret;
	}

	@:runtime public inline function iterator():haxe.iterators.ArrayIterator<T> {
		return new haxe.iterators.ArrayIterator(this);
	}

	@:pure @:runtime public inline function keyValueIterator() : ArrayKeyValueIterator<T> {
		return new ArrayKeyValueIterator(this);
	}

	@:runtime public inline function map<S>(f:T->S):Array<S> {
		return [for (v in this) f(v)];
	}

	@:runtime public inline function filter(f:T->Bool):Array<T> {
		return [for (v in this) if (f(v)) v];
	}

	public function resize(len:Int):Void {
		grow(len);
	}
}
