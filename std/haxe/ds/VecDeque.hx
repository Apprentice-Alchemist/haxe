package haxe.ds;

import haxe.ds.Vector;

/**
	A double-ended queue implemented as a growable ring buffer.
**/
class VecDeque<T> {
	var storage:Vector<T>;
	var head:Int;

	/**
		The number of elements in the deque.
	**/
	public var length(default, null):Int;

	/**
		Creates an empty deque with space for at least `capacity` elements
	**/
	public function new(capacity: Int = 0) {
		storage = new Vector(capacity);
		head = 0;
		length = 0;
	}

	/**
		Returns the number of elements the deque can hold without reallocating.
	**/
	public inline function capacity():Int {
		return storage.length;
	}

	/**
		Shrinks the capacity of the deque as much as possible.
	**/
	public function shrinkToFit(): Void {
		shrinkTo(0);
	}

	/**
		Shrinks the capacity of the deque with a lower bound.

		The capacity will remain at least as large as both the length and the supplied value.

		If the current capacity is less than the lower limit, this is a no-op.
	**/
	public function shrinkTo(minCapacity: Int): Void {
		var old_capacity = storage.length;
		var new_capacity = minCapacity > length ? minCapacity : length;
		if (old_capacity <= new_capacity) {
			return;
		}
		var new_storage = new Vector(new_capacity);

		if (head + length < old_capacity) {
			Vector.blit(storage, head, new_storage, 0, length);
		} else {
			Vector.blit(storage, head, new_storage, 0, old_capacity - head);
			Vector.blit(storage, 0, new_storage, old_capacity - head, length - (old_capacity - head));
		}

		this.storage = new_storage;
		this.head = 0;
	}

	inline function isFull() {
		return length == capacity();
	}

	inline function computeIndex(idx:Int) {
		if (head + idx >= capacity()) {
			return head + idx - capacity();
		} else {
			return head + idx;
		}
	}

	function grow() {
		var old_capacity = storage.length;
		var new_capacity = if (old_capacity == 0) {
			1;
		} else {
			old_capacity * 2;
		};
		var new_storage = new Vector(new_capacity);
		if (head + length < old_capacity) {
			Vector.blit(storage, head, new_storage, 0, length);
		} else {
			Vector.blit(storage, head, new_storage, 0, old_capacity - head);
			Vector.blit(storage, 0, new_storage, old_capacity - head, length - (old_capacity - head));
		}
		this.storage = new_storage;
		this.head = 0;
	}

	/**
		Returns the value at the given index.

		Element at index 0 is the front of the queue.
	**/
	public function get(idx:Int):T {
		if (idx > length || idx < 0) {
			throw "out of bounds";
		}

		return storage[computeIndex(idx)];
	}

	/**
		Sets the value at the given index to `value`.

		Element at index 0 is the front of the queue.
	**/
	public function set(idx:Int, value:T):T {
		if (idx > length || idx < 0) {
			throw "out of bounds";
		}

		return storage[computeIndex(idx)] = value;
	}

	/**
		Returns position of the first occurrence of `value` in this deque, searching front to back.

		If `value` is found by checking standard equality, the function returns its index.

		If `value` is not found, the function returns -1.
	**/
	public function indexOf(value:T):Int {
		for (i in 0...length) {
			if (storage[computeIndex(i)] == value) {
				return i;
			}
		}

		return -1;
	}

	/**
		Returns the last element of the deque or `null` if it is empty.
	**/
	public function peekBack(): Null<T> {
		if (length == 0) {
			return null;
		}
		return storage[computeIndex(length - 1)];
	}

	/**
		Returns the first element of the deque or `null` if it is empty.
	**/
	public function peekFront(): Null<T> {
		if (length == 0) {
			return null;
		}
		return storage[head];
	}

	/**
		Appends an element to the back of the deque.

		Returns the index of the new element.
	**/
	public function pushBack(value:T): Int {
		if (isFull()) {
			grow();
		}

		storage[computeIndex(length++)] = value;
		return length - 1;
	}

	/**
		Prepends an element to the deque.
	**/
	public function pushFront(value:T) {
		if (isFull()) {
			grow();
		}

		if (head == 0) {
			head = capacity() - 1;
			length++;
		} else {
			head--;
			length++;
		}

		storage[head] = value;
	}

	/**
		Removes the last element from the deque and returns it, or `null` if it is empty.
	**/
	public function popBack():Null<T> {
		if (length == 0) {
			return null;
		} else {
			this.length--;
			final storage_idx = computeIndex(length);
			final value = storage[storage_idx];
			storage[storage_idx] = null;
			return value;
		}
	}

	/**
		Removes the first element of the deque and returns it, or `null` if it is empty.
	**/
	public function popFront():Null<T> {
		if (length == 0) {
			return null;
		} else {
			var old_head = head;
			this.head = computeIndex(1);
			this.length--;
			final value = storage[old_head];
			storage[old_head] = null;
			return value;
		}
	}

	/**
		Removes and returns the element at index from the deque.
		Returns `null` if index is out of bounds.

		Element at index 0 is the front of the queue.
	**/
	public function removeAt(idx:Int):Null<T> {
		if (length <= idx) {
			return null;
		} else {
			var storage_idx = computeIndex(idx);
			var value = storage[storage_idx];
			if (storage_idx >= head) {
				Vector.blit(storage, head, storage, head + 1, storage_idx - head);
				storage[head] = null;
				head++;
				length--;
			} else { // storage_idx < head
				Vector.blit(storage, storage_idx + 1, storage, storage_idx, length - idx - 1);
				storage[storage_idx + length - idx - 1] = null;
				length--;
			}
			return value;
		}
	}

	/**
		Returns an iterator of the values in this deque.
	**/
	public function iterator():Iterator<T> {
		return new VecDequeIterator(this);
	}

	/**
		Returns a string representation of `this` VecDeque.
	**/
	public function toString() {
		var b = new StringBuf();
		b.addChar("[".code);
		for (i in 0...length) {
			if (i > 0)
				b.addChar(",".code);
			b.add(storage[computeIndex(i)]);
		}
		b.addChar("]".code);
		return b.toString();
	}
}

private class VecDequeIterator<T> {
	var d:VecDeque<T>;
	var idx:Int;

	public inline function new(d:VecDeque<T>) {
		this.d = d;
		this.idx = 0;
	}

	public inline function hasNext():Bool {
		return idx < d.length;
	}

	public inline function next():T {
		return @:privateAccess d.storage[d.computeIndex(idx++)];
	}
}