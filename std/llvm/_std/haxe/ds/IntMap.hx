package haxe.ds;

private class Entry<T> {
	public var key:Int = 0;
	public var value:Dynamic = null;
	public var next:Null<Entry<T>> = null;

	public function new(key:Int, value:T) {
		this.key = key;
		this.value = value;
	}
}

private class Bucket<T> {
	public var head:Null<Entry<T>> = null;

	public function new() {}

	public function set(key:Int, value:T) {
		var entry = this.head;
		while (entry != null) {
			if (entry.key == key) {
				entry.value = value;
				return;
			}
			entry = entry.next;
		}
		entry = new Entry(key, value);
		entry.next = this.head;
		this.head = entry;
	}

	public function get(key:Int):Null<Entry<T>> {
		var entry = this.head;
		while (entry != null) {
			if (entry.key == key) {
				return entry;
			}
			entry = entry.next;
		}
		return null;
	}

	public function remove(key:Int) {
		var entry = this.head;
		var prev = null;
		while (entry != null) {
			if (entry.key == key) {
				if (prev == null) {
					this.head = entry.next;
				} else {
					prev.next = entry.next;
				}
				return true;
			}

			prev = entry;
			entry = entry.next;
		}
		return false;
	}

	public function iterator():BucketIterator<T> {
		return new BucketIterator<T>(this.head);
	}
}

private class BucketIterator<T> {
	var head:Null<Entry<T>>;

	public function new(head:Null<Entry<T>>) {
		this.head = head;
	}

	public function hasNext():Bool {
		return head != null;
	}

	public function next():Null<Entry<T>> {
		var v = head;
		head = head.next;
		return v;
	}
}

class IntMap<T> implements haxe.Constraints.IMap<Int, T> {
	private static inline final MAX_LOAD_FACTOR:Float = 2;

	var buckets:Array<Bucket<T>>;
	var numEntries:Int;

	public function new():Void {
		buckets = [];
		numEntries = 0;
	}

	function hash(key: Int): Int {
		return key % buckets.length;
	}

	function resize(newSize:Int) {
		var newBuckets = new Array();
		newBuckets.resize(newSize);

		for (bucket in buckets) {
			for (entry in bucket) {
				buckets[hash(entry.key)].set(entry.key, entry.value);
			}
		}
	}

	public function set(key:Int, value:T):Void {
		if (numEntries / buckets.length > MAX_LOAD_FACTOR) {
			resize(buckets.length * 2);
		}

		buckets[hash(key)].set(key, value);
	}

	public function get(key:Int):Null<T> {
		return buckets[hash(key)].get(key)?.value;
	}

	public function exists(key:Int):Bool {
		return buckets[hash(key)].get(key) != null;
	}

	public function remove(key:Int):Bool {
		return buckets[hash(key)].remove(key);
	}

	public function keys():Iterator<Int> {
		return new KeyIterator(this.buckets);
	}

	public function iterator():Iterator<T> {
		return new ValueIterator(this.buckets);
	}

	@:runtime public inline function keyValueIterator():KeyValueIterator<Int, T> {
		return new haxe.iterators.MapKeyValueIterator(this);
	}

	public function copy():IntMap<T> {
		var copied = new IntMap();
		for (key in keys())
			copied.set(key, get(key));
		return copied;
	}

	public function toString():String {
		var s = new StringBuf();
		s.add("[");
		var it = keys();
		for (i in it) {
			s.add(Std.string(i));
			s.add(" => ");
			s.add(Std.string(get(i)));
			if (it.hasNext())
				s.add(", ");
		}
		s.add("]");
		return s.toString();
	}

	public function clear():Void {
		buckets = [];
		numEntries = 0;
	}

	public function size():Int {
		return this.numEntries;
	}
}

private class KeyIterator<T> {
	var buckets:Array<Bucket<T>>;
	var bucketIdx:Int;
	var head:Null<Entry<T>>;

	public function new(buckets:Array<Bucket<T>>) {
		this.buckets = buckets;
		bucketIdx = 0;
		head = null;
	}

	public function hasNext():Bool {
		return bucketIdx < buckets.length && head != null;
	}

	public function next():Null<Int> {
		if (head == null) {
			head = buckets[bucketIdx++].head;
		}
		var v = head.key;
		head = head.next;
		return v;
	}
}

private class ValueIterator<T> {
	var buckets:Array<Bucket<T>>;
	var bucketIdx:Int;
	var head:Null<Entry<T>>;

	public function new(buckets:Array<Bucket<T>>) {
		this.buckets = buckets;
		bucketIdx = 0;
		head = null;
	}

	public function hasNext():Bool {
		return bucketIdx < buckets.length && head != null;
	}

	public function next():Null<T> {
		if (head == null) {
			head = buckets[bucketIdx++].head;
		}
		var v = head.value;
		head = head.next;
		return v;
	}
}
