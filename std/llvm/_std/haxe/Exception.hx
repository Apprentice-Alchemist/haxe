package haxe;

class Exception {
	public var message(get,never):String;
	private function get_message():String {return null;}

	public var stack(get,set):CallStack;
	private function get_stack():CallStack {return null;}
	private function set_stack(stack:CallStack):CallStack {return null;}

	public var previous(get,never):Null<Exception>;
	private function get_previous():Null<Exception> {return null;}

	public var native(get,never):Any;
	final private function get_native():Any {return null;}

	static private function caught(value:Any):Exception {
		return null;
	}

	static private function thrown(value:Any):Any {
		return null;
	}

	public function new(message:String, ?previous:Exception, ?native:Any):Void {}

	private function unwrap():Any {return null;}

	public function toString():String {return null;}

	public function details():String {return null;}

	/**
		If this field is defined in a target implementation, then a call to this
		field will be generated automatically in every constructor of derived classes
		to make exception stacks point to derived constructor invocations instead of
		`super` calls.
	**/
	// @:noCompletion @:ifFeature("haxe.Exception.stack") private function __shiftStack():Void;
}
