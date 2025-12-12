package haxe.io;

class Bytes {
	public var length(default, null):Int;

	var b:llvm.Ptr<llvm.UInt8>;

	function new(length, b) {
		this.length = length;
		this.b = b;
	}

	public inline function get(pos:Int):Int {
		if (pos < 0 || pos >= length)
			throw Error.OutsideBounds;
		return b[pos];
	}

	public inline function set(pos:Int, v:Int):Void {
		if (pos < 0 || pos >= length)
			throw Error.OutsideBounds;
		b[pos] = (cast v: llvm.UInt8);
	}
	public function blit(pos:Int, src:Bytes, srcpos:Int, len:Int):Void {
		if (pos < 0 || srcpos < 0 || len < 0 || pos + len > length || srcpos + len > src.length)
			throw Error.OutsideBounds;
		b.offset(pos).copyFrom(src.b.offset(srcpos), len);
	}

	public function fill(pos:Int, len:Int, value:Int) {
		// TODO: memset
		for (i in 0...len)
			set(pos++, value);
	}

	public function sub(pos:Int, len:Int):Bytes {
		if (pos < 0 || len < 0 || pos + len > length)
			throw Error.OutsideBounds;
		var newData = llvm.Ptr.alloc(len);
		newData.copyFrom(b.offset(pos), len);
		return new Bytes(len, newData);
	}

	public function compare(other:Bytes):Int {
		var b1 = b;
		var b2 = other.b;
		var len = (length < other.length) ? length : other.length;
		for (i in 0...len)
			if (b1[i] != b2[i])
				return untyped b1[i] - b2[i];
		return length - other.length;
	}

	public function getDouble(pos:Int):Float {
		return FPHelper.i64ToDouble(getInt32(pos), getInt32(pos + 4));
	}

	public function getFloat(pos:Int):Float {
		return FPHelper.i32ToFloat(getInt32(pos));
	}

	public function setDouble(pos:Int, v:Float):Void {
		var i = FPHelper.doubleToI64(v);
		setInt32(pos, i.low);
		setInt32(pos + 4, i.high);
	}


	public function setFloat(pos:Int, v:Float):Void {
		setInt32(pos, FPHelper.floatToI32(v));
	}

	public inline function getUInt16(pos:Int):Int {
		return get(pos) | (get(pos + 1) << 8);
	}

	public inline function setUInt16(pos:Int, v:Int):Void {
		set(pos, v);
		set(pos + 1, v >> 8);
	}

	public inline function getInt32(pos:Int):haxe.Int32 {
		return get(pos) | (get(pos + 1) << 8) | (get(pos + 2) << 16) | (get(pos + 3) << 24);
	}

	public inline function getInt64(pos:Int):haxe.Int64 {
		return haxe.Int64.make(getInt32(pos + 4), getInt32(pos));
	}

	public inline function setInt32(pos:Int, v:haxe.Int32):Void {
		set(pos, v);
		set(pos + 1, v >> 8);
		set(pos + 2, v >> 16);
		set(pos + 3, v >>> 24);
	}

	public inline function setInt64(pos:Int, v:haxe.Int64):Void {
		setInt32(pos, v.low);
		setInt32(pos + 4, v.high);
	}

	public function getString(pos:Int, len:Int, ?encoding:Encoding):String {
		if (pos < 0 || len < 0 || pos + len > length)
			throw Error.OutsideBounds;
		var s = "";
		var b = b;
		var fcc = String.fromCharCode;
		var i = pos;
		var max = pos + len;
		// utf8-decode and utf16-encode
		while (i < max) {
			var c = b[i++];
			if (c < 0x80) {
				if (c == 0)
					break;
				s += fcc(c);
			} else if (c < 0xE0)
				s += fcc(((c & 0x3F) << 6) | (b[i++] & 0x7F));
			else if (c < 0xF0) {
				var c2 = b[i++];
				s += fcc(((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (b[i++] & 0x7F));
			} else {
				var c2 = b[i++];
				var c3 = b[i++];
				var u = ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 & 0x7F) << 6) | (b[i++] & 0x7F);
				// surrogate pair
				s += fcc((u >> 10) + 0xD7C0);
				s += fcc((u & 0x3FF) | 0xDC00);
			}
		}
		return s;
	}

	@:deprecated("readString is deprecated, use getString instead")
	@:noCompletion
	public inline function readString(pos:Int, len:Int):String {
		return getString(pos, len);
	}

	public function toString():String {
		return getString(0, length);
	}

	public function toHex():String {
		var s = new StringBuf();
		var chars = [];
		var str = "0123456789abcdef";
		for (i in 0...str.length)
			chars.push(str.charCodeAt(i));
		for (i in 0...length) {
			var c = get(i);
			s.addChar(chars[c >> 4]);
			s.addChar(chars[c & 15]);
		}
		return s.toString();
	}

	public inline function getData():BytesData {
		return new BytesData(b, length);
	}

	public static function alloc(length:Int):Bytes {
		return new Bytes(length, llvm.Ptr.alloc(length));
	}

	@:pure
	public static function ofString(s:String, ?encoding:Encoding):Bytes {
		var newData = llvm.Ptr.alloc(s.length);
		newData.copyFrom(@:privateAccess s.data, s.length);
		return new Bytes(s.length, newData);
	}

	public static function ofData(b:BytesData) {
		return new Bytes(b.length, b);
	}

	public static function ofHex(s:String):Bytes {
		var len:Int = s.length;
		if ((len & 1) != 0)
			throw "Not a hex string (odd number of digits)";
		var ret:Bytes = Bytes.alloc(len >> 1);
		for (i in 0...ret.length) {
			var high = StringTools.fastCodeAt(s, i * 2);
			var low = StringTools.fastCodeAt(s, i * 2 + 1);
			high = (high & 0xF) + ((high & 0x40) >> 6) * 9;
			low = (low & 0xF) + ((low & 0x40) >> 6) * 9;
			ret.set(i, ((high << 4) | low) & 0xFF);
		}

		return ret;
	}

	public inline static function fastGet(b:BytesData, pos:Int):Int {
		return b[pos];
	}
}
