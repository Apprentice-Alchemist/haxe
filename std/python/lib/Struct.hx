package python.lib;

@:pythonImport("struct")
extern class Struct {
	static function pack(format:String, ...args:Dynamic):python.Bytes;
	static function unpack(format:String, bytes:python.Bytes):Tuple<Dynamic>;
}