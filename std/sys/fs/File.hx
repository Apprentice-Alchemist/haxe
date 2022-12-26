package sys.fs;

import haxe.io.Bytes;
import haxe.Result;
import sys.fs.Metadata;

enum SeekPos {
	SeekBegin(offset:Int);
	SeekCurrent(offset:Int);
	SeekEnd(offset:Int);
}

extern class File {
	/**
		Opens the file in read-only mode.
	**/
	static function open(p:Path):Result<File, Error>;
	/**
		Opens the file in write-only mode, creating it if needed.
	**/
	static function create(p:Path):Result<File, Error>;
	/**
		Opens the file in write-only mode, always creating a new one.
		Returns an error if the file already exists.
	**/
	static function createNew(p:Path):Result<File, Error>;
	static function readAll(p:Path):Result<Bytes, Error>;
	static function writeAll(p:Path, b:Bytes):Result<Void /* TODO */, Error>;
	static function appendAll(p:Path, b:Bytes):Result<Void /* TODO */, Error>;

	function syncAll():Result<Void /* TODO */, Error>;
	function syncData():Result<Void /* TODO */, Error>;
	function metadata():Result<Metadata, Error>;
	function setPermissions(perm:Permissions):Result<Void /* TODO */, Error>;
	// TODO: these should all use Int64's (uint64's even)

	function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Result<Int, Error>;
	function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Result<Int, Error>;
	function seek(pos:SeekPos):Result<Int, Error>;

	function close():Void;
}
