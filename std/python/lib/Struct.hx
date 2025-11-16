package python.lib;

import python.Bytes;

@:pythonImport("struct")
extern class Struct {
	static function pack(format: String, ...args: Dynamic): Bytes;
	static function unpack(format:String, buffer: Bytes): python.Tuple<Dynamic>;
}