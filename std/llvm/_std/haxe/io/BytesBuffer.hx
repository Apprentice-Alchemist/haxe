
package haxe.io;
@:coreApi
extern class BytesBuffer {
	var length(get, never):Int;
	function new():Void;
	private function get_length():Int;
	function addByte(byte:Int):Void;
	function add(src:Bytes):Void;
	function addString(v:String, ?encoding:Encoding):Void;
	function addInt32(v:haxe.Int32):Void;
	function addInt64(v:haxe.Int64):Void;
	function addFloat(v:Float):Void;
	function addDouble(v:Float):Void;
	function addBytes(src:Bytes, pos:Int, len:Int):Void;
	function getBytes():Bytes;
}