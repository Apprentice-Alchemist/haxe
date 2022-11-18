package sys.fs;

import haxe.Result;

extern class Metadata {
	function isDir():Bool;
	function isFile():Bool;
	function isSymlink():Bool;
	function size():haxe.Int64;
	function permissions():Permissions;
	function modified():Null<haxe.Time.SystemTime>;
	function accessed():Null<haxe.Time.SystemTime>;
	function created():Null<haxe.Time.SystemTime>;
}

extern class Permissions {
	/**
		Note that this does not affect the file, use `Fs.setPermissions`.
	**/
	var readonly(get, set):Bool;
}