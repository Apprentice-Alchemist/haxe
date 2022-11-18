package python;

@:native("memoryview")
extern class Memoryview implements ArrayAccess<Int> {
	function new(b:Bytearray):Void;
}