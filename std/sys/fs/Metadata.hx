package sys.fs;

@:coreApi
extern class Metadata {
	function isDir():Bool;
	function isFile():Bool;
	function isSymlink():Bool;
	function size():haxe.Int64;
	function modified():Null<haxe.time.SystemTime>;
	function accessed():Null<haxe.time.SystemTime>;
	function created():Null<haxe.time.SystemTime>;
}
