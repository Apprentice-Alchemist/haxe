import llvm.BaseType;

@:publicFields
@:coreApi class Type {
	static function getClass<T>(o:T):Null<Class<T>> {
		var t = llvm.TypeInfo.ofDynamic(o);
		if (t.kind() == Object)
			return cast t.type();
		return null;
	}

	static function getEnum(o:EnumValue):Null<Enum<Dynamic>> {
		return cast (cast o: llvm.EnumPtr).type();
	}

	static inline function getSuperClass(c:Class<Dynamic>):Null<Class<Dynamic>> {
		var cl:BaseClass = cast c;
		return cast cl.superClass;
	}

	static inline function getClassName(c:Class<Dynamic>):String {
		var cl:BaseClass = cast c;
		return cl.name;
	}

	static inline function getEnumName(e:Enum<Dynamic>):String {
		var cl:BaseEnum = cast e;
		return cl.name;
	}

	static function resolveClass(name:String):Null<Class<Dynamic>> {
		return null;
	}

	static function resolveEnum(name:String):Null<Enum<Dynamic>> {
		return null;
	}

	static inline function createInstance<T>(cl:Class<T>, args:Array<Dynamic>):T {
		var cl:BaseClass = cast cl;
		var instance = cl.createEmptyInstance();
		// TODO: call constructor
		return cast instance;
	}

	static inline function createEmptyInstance<T>(cl:Class<T>):T {
		var cl:BaseClass = cast cl;
		return cast cl.createEmptyInstance();
	}

	static function createEnum<T>(e:Enum<T>, constr:String, ?params:Array<Dynamic>):T {
		return null;
	}

	static function createEnumIndex<T>(e:Enum<T>, index:Int, ?params:Array<Dynamic>):T {
		return null;
	}

	static function getInstanceFields(c:Class<Dynamic>):Array<String> {
		return [];
	}

	static function getClassFields(c:Class<Dynamic>):Array<String> {
		return [];
	}

	static function getEnumConstructs(e:Enum<Dynamic>):Array<String> {
		return [];
	}

	static function typeof(v:Dynamic):ValueType {
		return TUnknown;
	}

	static inline function enumEq<T:EnumValue>(a:T, b:T):Bool {
		var a = (cast a : llvm.EnumPtr);
		var b = (cast b : llvm.EnumPtr);
		if (a.index() == b.index()) {
			return true; // TODO: deep equality
		} else {
			return false;
		}
	}

	static inline function enumConstructor(e:EnumValue):String {
		return "";
	}

	static inline function enumParameters(e:EnumValue):Array<Dynamic> {
		return [];
	}

	static inline function enumIndex(e:EnumValue):Int {
		return (cast e : llvm.EnumPtr).index();
	}

	static function allEnums<T>(e:Enum<T>):Array<T> {
		return [];
	}
}

enum ValueType {
	TNull;
	TInt;
	TInt64;
	TFloat;
	TBool;
	TObject;
	TFunction;
	TClass(c:Class<Dynamic>);
	TEnum(e:Enum<Dynamic>);
	TUnknown;
}
