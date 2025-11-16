package haxe.io;

import python.lib.Struct;

class FPHelper {
	public static function i32ToFloat(i:Int):Float {
		return Struct.unpack("=f", Struct.pack("=i", i))[0];
	}

	public static function floatToI32(f:Float):Int {
		return Struct.unpack("=i", Struct.pack("=f", f))[0];
	}

	public static function i64ToDouble(low:Int, high:Int):Float {
		return Struct.unpack("<d", Struct.pack("<ii", low, high))[0];
	}

	public static function doubleToI64(v:Float):Int64 {
		return Struct.unpack("=q", Struct.pack("=d", v))[0];
	}
}
