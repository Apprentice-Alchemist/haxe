package sys.fs;

import haxe.io.Bytes;
import haxe.Result;
import sys.fs.Metadata;

extern class File {
	static function open(p:Path):Result<File, Error>;
	static function create(p:Path):Result<File, Error>;
	static function readAll(p:Path):Bytes;
	static function writeAll(p:Path, b:Bytes):Result<Void /* TODO */, Error>;
	static function appendAll(p:Path, b:Bytes):Result<Void /* TODO */, Error>;

	function syncAll():Result<Void /* TODO */, Error>;
	function syncData():Result<Void /* TODO */, Error>;
	function metadata():Result<Metadata, Error>;
	function setPermissions(perm:Permissions):Result<Void /* TODO */, Error>;
	// TODO: figure out a nice read/write interface
}
