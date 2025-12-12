package llvm;

@:keep abstract class BaseType {
	public var typeInfo:llvm.TypeInfo;
	public var name:String;
}

@:keep abstract class BaseClass extends BaseType {
	public var superClass:Null<BaseClass>;

	public abstract function createEmptyInstance():ObjectPtr;
}

@:keep abstract class BaseEnum extends BaseType {
}