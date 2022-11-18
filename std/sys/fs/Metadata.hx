package sys.fs;

import haxe.Result;

extern class Metadata {
	function isDir():Bool;
	function isFile():Bool;
	function isSymlink():Bool;
	function size():haxe.Int64;
	function permissions():Permissions;
	function modified():Result<Int, Error>; // TODO don't use Int
	function accessed():Result<Int, Error>;
	function created():Result<Int, Error>;
}

extern class Permissions {
	/**
		Note that this does not affect the file, use `Fs.setPermissions`.
	**/
	var readonly(get, set):Bool;
}