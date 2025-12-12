import llvm.UInt8;

private function isUtf8CharBoundary(val:llvm.UInt8) {
	// equivalent to: val < 128 || val >= 192
	return (cast val : llvm.Int8) >= cast -0x40;
}

private inline var TAG_CONT:llvm.UInt8 = cast 0b1000_0000;
private inline var TAG_TWO_B:llvm.UInt8 = cast 0b1100_0000;
private inline var TAG_THREE_B:llvm.UInt8 = cast 0b1110_0000;
private inline var TAG_FOUR_B:llvm.UInt8 = cast 0b1111_0000;

private inline var MASK_CONT:llvm.UInt8 = cast 0b111111;
private inline var MASK_TWO_B:llvm.UInt8 = cast 0b11111;
private inline var MASK_THREE_B:llvm.UInt8 = cast 0b1111;
private inline var MASK_FOUR_B:llvm.UInt8 = cast 0b111;

private inline var MAX_ONE_B:llvm.UInt32 = cast 0x80;
private inline var MAX_TWO_B:llvm.UInt32 = cast 0x800;
private inline var MAX_THREE_B:llvm.UInt32 = cast 0x10000;

final class String {
	public var length(default, null):Int;

	private var data:llvm.Ptr<llvm.UInt8>;

	public function new(string:String):Void {
		this.length = string.length;
		this.data = string.data;
	}

	public function toUpperCase():String {
		return this;
	}

	public function toLowerCase():String {
		return this;
	}

	public function charAt(index:Int):String {
		return null;
	}

	public function charCodeAt(index:Int):Null<Int> {
		if (index < length && index > 0) {
			var byte0 = data[index];
			if (byte0 <= 0x7F) {
				return byte0;
			} else if (byte0 & TAG_TWO_B == TAG_TWO_B) {
				if (index + 1 < length) {
					var byte1 = data[index + 1];
					return (byte1 & MASK_CONT) | ((byte0 & MASK_TWO_B) << 6);
				} else {
					throw "invalid utf8";
				}
			} else if (byte0 & TAG_THREE_B == TAG_THREE_B) {
				if (index + 2 < length) {
					var byte1 = data[index + 1];
					var byte2 = data[index + 2];
					return (byte2 & MASK_CONT) | ((byte1 & MASK_CONT) << 6) | ((byte0 & MASK_TWO_B) << 12);
				} else {
					throw "invalid utf8";
				}
			} else if (byte0 & TAG_FOUR_B == TAG_FOUR_B) {
				if (index + 3 < length) {
					var byte1 = data[index + 1];
					var byte2 = data[index + 2];
					var byte3 = data[index + 3];
					return (byte3 & MASK_CONT) | ((byte2 & MASK_CONT) << 6) | ((byte1 & MASK_CONT) << 12) | ((byte0 & MASK_TWO_B) << 24);
				} else {
					throw "invalid utf8";
				}
			} else {
				throw "invalid index: not a char boundary";
			}
		} else {
			return null;
		}
	}

	public function indexOf(str:String, ?startIndex:Int):Int {
		var startIndex:Int = startIndex ?? 0;
		for (i in startIndex...length) {
			if (data[i] == str.data[0]) {
				for (i2 in 1...str.length) {
					if (data[i + i2] != str.data[i2]) {
						break;
					}
				}
				return i;
			}
		}
		return -1;
	}

	public function lastIndexOf(str:String, ?startIndex:Int):Int {
		var startIndex:Int = startIndex ?? 0;
		for (i in 0...startIndex + length) {
			var realI = (startIndex + length) - i - 1;
			if (data[realI] == str.data[str.length - 1]) {
				for (i2 in 1...str.length) {
					var i2 = str.length - i2 - 1;
					if (data[i + i2] != str.data[i2]) {
						break;
					}
				}
				return i;
			}
		}
		return -1;
	}

	public function split(delimiter:String):Array<String> {
		return [];
	}

	public function substr(pos:Int, ?len:Int):String {
		if (pos >= length || pos < 0) {
			throw "out of bounds";
		}

		var len:Int = len ?? (length - pos);
		if (len > (length - pos)) {
			throw "out of bounds";
		}
		var s = Type.createEmptyInstance(String);
		var newData = llvm.Ptr.alloc(len);
		newData.copyFrom(data.offset(pos), len);
		s.data = newData;
		s.length = len;
		return s;
	}

	public function substring(startIndex:Int, ?endIndex:Int):String {
		return "";
	}

	public function toString():String {
		return this;
	}

	@:pure public static function fromCharCode(code:Int):String {
		var length:Int;
		if (code < 0) {
			throw "invalid char code";
		}
		if (code <= 0x7F) {
			length = 1;
		} else if (code <= 0x7FF) {
			length = 2;
		} else if (code <= 0xFFFF) {
			length = 3;
		} else if (code <= 0x10FFFF) {
			length = 4;
		} else {
			throw "invalid char code";
		}
		var data:llvm.Ptr<llvm.UInt8> = llvm.Ptr.alloc(length);

		if (length == 1) {
			data[0] = cast code;
		} else {
			var last1: llvm.UInt8 = (cast (code >> 0 & 0x3F): llvm.UInt8) | TAG_CONT;
			var last2: llvm.UInt8 = (cast (code >> 6 & 0x3F): llvm.UInt8) | TAG_CONT;
			var last3: llvm.UInt8 = (cast (code >> 12 & 0x3F): llvm.UInt8) | TAG_CONT;
			var last4: llvm.UInt8 = (cast (code >> 18 & 0x3F): llvm.UInt8) | TAG_FOUR_B;

			if (length == 2) {
				data[0] = last2 | TAG_TWO_B;
				data[1] = last1;
			} else if (length == 3) {
				data[0] = last3 | TAG_THREE_B;
				data[1] = last2;
				data[2] = last1;
			} else if (length == 4) {
				data[0] = last4;
				data[1] = last3;
				data[2] = last2;
				data[3] = last1;
			}
		}

		var s = Type.createEmptyInstance(String);
		s.data = data;
		s.length = length;
		return s;
	}

	@:keep static function eq(a: String, b: String): Bool {
		if (a.length != b.length) {
			return false;
		}

		for (i in 0...a.length) {
			if (a.data[i] != b.data[i]) {
				return false;
			}
		}

		return true;
	}

	@:keep static function cmp(a: String, b: String): Int {
		final l = a.length > b.length ? b.length : a.length;
		for (i in 0...l) {
			final val_a = a.data[i];
			final val_b = b.data[i];
			final result = val_a.compare(val_b);
			if (result != 0) {
				return result;
			}
		}

		return a.length > b.length ? 1 : (a.length == b.length ? 0 : -1);
	}

	@:keep static function add(a: String, b: String): String {
		var ret = Type.createEmptyInstance(String);
		var data = llvm.Ptr.alloc(a.length + b.length);
		data.copyFrom(a.data, a.length);
		data.offset(a.length).copyFrom(b.data, b.length);
		
		ret.data = data;
		ret.length = a.length + b.length;
		return ret;
	}

	static function fromPtrCopied(ptr: llvm.Ptr<UInt8>, len: Int): String {
		var data = llvm.Ptr.alloc(len);
		data.copyFrom(ptr, len);
		var s = Type.createEmptyInstance(String);
		s.data = data;
		s.length = len;
		return s;
	}
}
