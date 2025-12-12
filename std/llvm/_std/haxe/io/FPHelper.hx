package haxe.io;

extern class FPHelper {
	public static inline function i32ToFloat(i:haxe.Int32):Float {
		var i: llvm.UInt32 = cast i;
		return llvm.Float32.fromBits(i);
	}

	public static inline function floatToI32(f:Float):haxe.Int32 {
		var f: llvm.Float32 = f;
		return cast f.toBits();
	}

	public static inline function i64ToDouble(low:haxe.Int32, high:haxe.Int32):Float {
		var i: llvm.Int64 = haxe.Int64.make(high, low);
		return llvm.Float64.fromBits(cast i);		
	}

	public static inline function doubleToI64(v:Float):Int64 {
		var v: llvm.Float64 = v;
		return cast v.toBits();
	}
}