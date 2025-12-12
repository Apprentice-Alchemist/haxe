class Reflect {
	/**
		Tells if structure `o` has a field named `field`.

		This is only guaranteed to work for anonymous structures. Refer to
		`Type.getInstanceFields` for a function supporting class instances.

		If `o` or `field` are null, the result is unspecified.
	**/
	public static function hasField(o:Dynamic, field:String):Bool {
		return false;
	}

	/**
		Returns the value of the field named `field` on object `o`.

		If `o` is not an object or has no field named `field`, the result is
		null.

		If the field is defined as a property, its accessors are ignored. Refer
		to `Reflect.getProperty` for a function supporting property accessors.

		If `field` is null, the result is unspecified.
	**/
	public static function field(o:Dynamic, field:String):Dynamic {
		return null;
	}

	/**
		Sets the field named `field` of object `o` to value `value`.

		If `o` has no field named `field`, this function is only guaranteed to
		work for anonymous structures.

		If `o` or `field` are null, the result is unspecified.
	**/
	public static function setField(o:Dynamic, field:String, value:Dynamic):Void {}

	/**
		Returns the value of the field named `field` on object `o`, taking
		property getter functions into account.

		If the field is not a property, this function behaves like
		`Reflect.field`, but might be slower.

		If `o` or `field` are null, the result is unspecified.
	**/
	public static function getProperty(o:Dynamic, field:String):Dynamic {
        return null;
    }

	/**
		Sets the field named `field` of object `o` to value `value`, taking
		property setter functions into account.

		If the field is not a property, this function behaves like
		`Reflect.setField`, but might be slower.

		If `field` is null, the result is unspecified.
	**/
	public static function setProperty(o:Dynamic, field:String, value:Dynamic):Void {}

	/**
		Call a method `func` with the given arguments `args`.

		The object `o` is ignored in most cases. It serves as the `this`-context in the following
		situations:

		* (neko) Allows switching the context to `o` in all cases.
		* (macro) Same as neko for Haxe 3. No context switching in Haxe 4.
		* (js, lua) Require the `o` argument if `func` does not, but should have a context.
			This can occur by accessing a function field natively, e.g. through `Reflect.field`
			or by using `(object : Dynamic).field`. However, if `func` has a context, `o` is
			ignored like on other targets.
	**/
	public static function callMethod(o:Dynamic, func:haxe.Constraints.Function, args:Array<Dynamic>):Dynamic {
		return null;
	}

	/**
		Returns the fields of structure `o`.

		This method is only guaranteed to work on anonymous structures. Refer to
		`Type.getInstanceFields` for a function supporting class instances.

		If `o` is null, the result is unspecified.
	**/
	public static function fields(o:Dynamic):Array<String> {
		return [];
	}

	public static function isFunction(f:Dynamic):Bool {
		return llvm.TypeInfo.ofDynamic(f).kind() == Closure;
	}

	/**
		Compares `a` and `b`.

		If `a` is less than `b`, the result is negative. If `b` is less than
		`a`, the result is positive. If `a` and `b` are equal, the result is 0.

		This function is only defined if `a` and `b` are of the same type.

		If that type is a function, the result is unspecified and
		`Reflect.compareMethods` should be used instead.

		For all other types, the result is 0 if `a` and `b` are equal. If they
		are not equal, the result depends on the type and is negative if:

		- Numeric types: a is less than b
		- String: a is lexicographically less than b
		- Other: unspecified

		If `a` and `b` are null, the result is 0. If only one of them is null,
		the result is unspecified.
	**/
	public static function compare<T>(a:T, b:T):Int {
		if (a is String && b is String) {
			var a:String = cast a;
			var b:String = cast b;
			return @:privateAccess String.cmp(a, b);
		}
		return -1;
	}

	/**
		Compares the functions `f1` and `f2`.

		If `f1` or `f2` are null, the result is false.
		If `f1` or `f2` are not functions, the result is unspecified.

		Otherwise the result is true if `f1` and the `f2` are physically equal,
		false otherwise.

		If `f1` or `f2` are member method closures, the result is true if they
		are closures of the same method on the same object value, false otherwise.
	**/
	public static function compareMethods(f1:Dynamic, f2:Dynamic):Bool {
		return false;
	}

	public static function isObject(v:Dynamic):Bool {
        if (v == null) {
            return false;
        }
		return switch (llvm.TypeInfo.ofDynamic(v).kind()) {
			case DynObj | Object: true;
			default: false;
		}
	}

	public static function isEnumValue(v:Dynamic):Bool {
		return llvm.TypeInfo.ofDynamic(v).kind() == EnumInstance;
	}

	/**
		Removes the field named `field` from structure `o`.

		This method is only guaranteed to work on anonymous structures.

		If `o` or `field` are null, the result is unspecified.
	**/
	public static function deleteField(o:Dynamic, field:String):Bool {
        return false;
    }

	/**
		Copies the fields of structure `o`.

		This is only guaranteed to work on anonymous structures.

		If `o` is null, the result is `null`.
	**/
	public static function copy<T>(o:Null<T>):Null<T> {
        return o;
    }

	/**
		Transform a function taking an array of arguments into a function that can
		be called with any number of arguments.
	**/
	public static function makeVarArgs<T>(f:Array<Dynamic>->T):Dynamic {
        return null;
    }
}
