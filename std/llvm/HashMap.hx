package llvm;

private class Entry<K, T> {
	public var key:K = null;
	public var value:Dynamic = null;
	public var next:Entry<K, T> = null;

	public function new(key:K, value:T) {
		this.key = key;
		this.value = value;
	}
}

private class Bucket<K, T> {
	public var head:Entry<K, T> = null;

	public function new() {
		// Sys.println("bucket head");
		// Sys.println((cast head: llvm.integers.Int64));
	}

	public function set(key:K, value:T) {
		Sys.println("bucket head in set");
		Sys.println((cast head : llvm.integers.Int64));
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

	public function get(key:K):Null<Entry<K, T>> {
		var entry = this.head;
		while (entry != null) {
			if (entry.key == key) {
				return entry;
			}
			entry = entry.next;
		}
		return null;
	}

	public function remove(key:K) {
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

	public function toString() {
		return "bucket";
	}

	public inline function iterator():BucketIterator<K, T> {
		return new BucketIterator(this.head);
	}
}

private class BucketIterator<K, T> {
	var head:Null<Entry<K, T>>;

	public inline function new(head:Null<Entry<K, T>>) {
		this.head = head;
	}

	public inline function hasNext():Bool {
		return head != null;
	}

	public inline function next():Null<Entry<K, T>> {
		var v = head;
		head = head.next;
		return v;
	}
}

class HashMap<K, T> implements haxe.Constraints.IMap<K, T> {
	private static inline final MAX_LOAD_FACTOR:Float = 2;

	var buckets:Array<Bucket<K, T>>;
	var numEntries:Int;
	var hashFn:(K) -> Int;

	public function new(hashFn:(K) -> Int):Void {
		buckets = [];
		numEntries = 0;
		this.hashFn = hashFn;
	}

	function hash(key:K):Int {
		return hashFn(key) % buckets.length;
	}

	function resize(newSize:Int) {
		var newBuckets = new Array();
		newBuckets.resize(newSize);
		for (i in 0...newSize) {
			newBuckets[i] = new Bucket();
			Sys.println(newBuckets[i] != null);
		}

		var oldBuckets = buckets;
		buckets = newBuckets;

		for (bucket in oldBuckets) {
			for (entry in bucket) {
				buckets[hash(entry.key)].set(entry.key, entry.value);
			}
		}
	}

	inline function rebalance() {
		if (buckets.length == 0) {
			resize(8);
		} else if (numEntries / buckets.length > MAX_LOAD_FACTOR) {
			resize(buckets.length * 2);
		}
	}

	public function set(key:K, value:T):Void {
		rebalance();
		Sys.println('buckets.length: ${buckets.length}');
		Sys.println(hash(key));
		var bucket:Bucket<K, T> = buckets[hash(key)];
		var head = bucket.head;
		// Sys.println((cast buckets:llvm.integers.Int64));
		// Sys.println((cast head:llvm.integers.Int64));
		// Sys.println(head.key != null);
		buckets[hash(key)].set(key, value);
	}

	public function get(key:K):Null<T> {
		return buckets[hash(key)]?.get(key)?.value;
	}

	public function exists(key:K):Bool {
		return buckets[hash(key)]?.get(key) != null;
	}

	@:keep public function remove(key:K):Bool {
		return buckets[hash(key)]?.remove(key);
	}

	public inline function keys():Iterator<K> {
		return new KeyIterator(this.buckets);
	}

	public inline function iterator():Iterator<T> {
		return new ValueIterator(this.buckets);
	}

	@:runtime public inline function keyValueIterator():KeyValueIterator<K, T> {
		return new haxe.iterators.MapKeyValueIterator(this);
	}

	public function copy():HashMap<K, T> {
		var copied = new HashMap(hashFn);
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

private class KeyIterator<K, T> {
	var buckets:Array<Bucket<K, T>>;
	var bucketIdx:Int;
	var head:Null<Entry<K, T>>;

	public inline function new(buckets:Array<Bucket<K, T>>) {
		this.buckets = buckets;
		bucketIdx = 0;
		head = null;
	}

	public inline function hasNext():Bool {
		return bucketIdx < buckets.length && head != null;
	}

	public inline function next():Null<K> {
		if (head == null) {
			head = buckets[bucketIdx++].head;
		}
		var v = head.key;
		head = head.next;
		return v;
	}
}

private class ValueIterator<K, T> {
	var buckets:Array<Bucket<K, T>>;
	var bucketIdx:Int;
	var head:Null<Entry<K, T>>;

	public inline function new(buckets:Array<Bucket<K, T>>) {
		this.buckets = buckets;
		bucketIdx = 0;
		head = null;
	}

	public inline function hasNext():Bool {
		return bucketIdx < buckets.length && head != null;
	}

	public inline function next():Null<T> {
		if (head == null) {
			head = buckets[bucketIdx++].head;
		}
		var v = head.value;
		head = head.next;
		return v;
	}
}
