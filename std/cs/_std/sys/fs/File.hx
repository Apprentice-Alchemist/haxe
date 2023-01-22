package sys.fs;

import cs.system.io.FileStream;
import haxe.io.Bytes;
import haxe.Result;
import sys.fs.Metadata;
import sys.Error;
import sys.fs.Path;

import cs.system.io.FileMode;
import cs.system.io.File as NativeFile;

enum SeekPos {
	SeekBegin(offset:haxe.Int64);
	SeekCurrent(offset:haxe.Int64);
	SeekEnd(offset:haxe.Int64);
}

class File {
	/**
		Opens the file in read-only mode.
	**/
	static function open(p:Path):Result<File, Error> {
		try {
			cs.system.io.File.Open(p.toString(), FileMode.Open);

		}
		return Err(Unsupported);
	}

	/**
		Opens the file in write-only mode, creating it if needed.
	**/
	static function create(p:Path):Result<File, Error> {
		return Err(Unsupported);
	}

	/**
		Opens the file in write-only mode, always creating a new one.
		Returns an error if the file already exists.
	**/
	static function createNew(p:Path):Result<File, Error> {
		return Err(Unsupported);
	}

	static function readAll(p:Path):Result<Bytes, Error> {
		return Err(Unsupported);
	}

	static function writeAll(p:Path, b:Bytes):Result<Void /* TODO */, Error> {
		return Err(Unsupported);
	}

	static function appendAll(p:Path, b:Bytes):Result<Void /* TODO */, Error> {
		return Err(Unsupported);
	}

	final stream:FileStream;

	function new(file:FileStream) {
		this.stream = file;
	}

	function syncAll():Result<Void /* TODO */, Error> {
		stream.Flush();
		return Ok((null:Void));
	}

	function syncData():Result<Void /* TODO */, Error> {
		return syncAll();
	}

	function metadata():Result<Metadata, Error> {
		return Err(Unsupported);
	}

	function setPermissions(perm:Permissions):Result<Void /* TODO */, Error> {
		return Err(Unsupported);
	}

	// TODO: technically these should all use a UInt64 type

	function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Result<haxe.Int64, Error> {
		return Err(Unsupported);
	}

	function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Result<haxe.Int64, Error> {
		return Err(Unsupported);
	}

	function seek(pos:SeekPos):Result<haxe.Int64, Error> {
		return Err(Unsupported);
	}

	function close():Void {}
}
