import llvm.BaseType;
import llvm.UInt64;
import llvm.UInt32;
import llvm.UInt8;
import llvm.Libc;

class Std {
	@:deprecated('Std.is is deprecated. Use Std.isOfType instead.')
	public static function is(v:Dynamic, t:Dynamic):Bool {
		return isOfType(v, t);
	}
	public static function isOfType(v:Dynamic, t:Dynamic):Bool {
		var v_info = llvm.TypeInfo.ofDynamic(v);
		var t_base_type: llvm.BaseType = t;
		if (v_info.kind() == Object && t_base_type.typeInfo.kind() == Object) {
			var v_t:BaseClass = cast v_info.type();
			while (v_t != null) {
				if (v_t == t_base_type) {
					return true;
				}
				v_t = v_t.superClass;
			}
			return false;
		} else {
			return v_info.type() == t_base_type;
		}
	}
	public static inline function downcast<T:{}, S:T>(value:T, c:Class<S>):Null<S> {
		return isOfType(value, c) ? cast value : null;
	}

	@:deprecated('Std.instance() is deprecated. Use Std.downcast() instead.')
	public static function instance<T:{}, S:T>(value:T, c:Class<S>):Null<S> {
		return downcast(value, c);
	}
	public static function string(s:Dynamic):String {
		if (s == null) {
			return "null";
		} else if (s is Bool) {
			return (s:Bool) ? "true" : "false";
		} else if (s is String) {
			return s;
		} else if (s is Int) {
			var n:Int = s;
			final is_neg = if (n < 0) {
				n = -n;
				true;
			} else {
				false;
			}
			final len = if (n == 0) 1 else {
				var l = 0;
				var n:UInt32 = cast n;
				while (n > 0u32) {
					n /= 10u32;
					l++;
				}
				l;
			};
			final len: Int = len + (is_neg ? 1 : 0);
			final ptr: llvm.Ptr<llvm.UInt8> = llvm.Ptr.alloc(len);
			final zero: llvm.UInt8 = cast '0'.code;
			var cur = len;
			var n:UInt32 = cast n;
			while(cur >= 0) {
				cur -= 1;
				var v = zero + (cast(n % 10u32) : llvm.UInt8);
				ptr[cur] = v;
				n = n / 10u32;
				if (n == 0u32) {
					break;
				}
			}
			if (is_neg) {
				ptr[0] = cast '-'.code;
			}
			var s = Type.createEmptyInstance(String);
			@:privateAccess {
				s.data = ptr;
				s.length = len;
			}
			return s;
		} else if (s is llvm.Int64) {
			var n:llvm.Int64 = s;
			final is_neg = if (n < (cast 0: llvm.Int64)) {
				n = -n;
				true;
			} else {
				false;
			}
			final uzero = (cast 0 : llvm.UInt64);
			final ten = (cast 10 : llvm.UInt64);
			final len = if (n == (cast 0: llvm.Int64)) 1 else {
				var l = 0;
				var n:UInt64 = cast n;
				while (n > uzero) {
					n /= ten;
					l++;
				}
				l;
			};
			final len: Int = len + (is_neg ? 1 : 0);
			final ptr: llvm.Ptr<llvm.UInt8> = llvm.Ptr.alloc(len);
			final zero: llvm.UInt8 = cast '0'.code;
			var cur = len;
			var n:UInt64 = cast n;
			while(cur >= 0) {
				cur -= 1;
				var v = zero + (cast(n % ten) : llvm.UInt8);
				ptr[cur] = v;
				n = n / ten;
				if (n == uzero) {
					break;
				}
			}
			if (is_neg) {
				ptr[0] = cast '-'.code;
			}
			var s = Type.createEmptyInstance(String);
			@:privateAccess {
				s.data = ptr;
				s.length = len;
			}
			return s;
		} else if (s is llvm.Ptr) {
			return "<ptr>";
		} else if (s is Array) {
			return (s: Array<Dynamic>).toString();
		}
		return "<dyn>";
	}
	public static inline function int(x:Float):Int {
		// the LLVM backend codegens a cast from Float to Int as `fptosi`
		return cast x;
	}
	public static function parseInt(x:String):Null<Int> {
		return 0;
	}
	public static function parseFloat(x:String):Float {
		return 0.0;
	}
	public static function random(x:Int):Int {
		return 4; // chosen by random dice roll, TODO: proper rng
	}
}
