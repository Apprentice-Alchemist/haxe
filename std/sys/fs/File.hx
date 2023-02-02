package sys.fs;

import haxe.io.Bytes;
import haxe.Result;
import sys.fs.Metadata;

/**
	All methods may throw (a subclass of) sys.Error.
**/
@:coreApi
extern class File {
	/**
		Opens the file in read-only mode.
	**/
	static function open(p:Path):File;
	/**
		Opens the file in write-only mode, creating it if needed.
	**/
	static function create(p:Path):File;
	/**
		Opens the file in write-only mode, always creating a new one.
		Returns an error if the file already exists.
	**/
	static function createNew(p:Path):File;
	static function readAll(p:Path):Bytes;
	static function writeAll(p:Path, b:Bytes):Void;
	static function appendAll(p:Path, b:Bytes):Void;

	function syncAll():Void;
	function syncData():Void;
	function metadata():Metadata;
	function setPermissions(perm:Permissions):Void;
	// TODO: technically these should all use a Int64 or even uint64 type, but `haxe.io.Bytes` uses an int length, so...

	function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int;
	function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int;
	function seek(pos:SeekPos):haxe.Int64;

	function close():Void;
}
