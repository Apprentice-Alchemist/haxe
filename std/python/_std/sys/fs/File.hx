package sys.fs;

import python.Memoryview;
import python.lib.Builtins;
import python.lib.io.RawIOBase;
import haxe.exceptions.NotImplementedException;
import haxe.io.Bytes;
import sys.fs.Metadata;
import python.lib.Os;

@:coreApi
class File {
	public static function open(p:Path, ?options:OpenOptions):File {
		options ??= {read: true};
		var mode = switch [options.read, options.write, options.append] {
			case [true, false, false]: "r";
			case [false, true, false]: if (options.truncate) "w" else "r+";
			case [true, true, false]: if (options.truncate) "w+" else "r+";
			case [false, _, true]: "a";
			case [true, _, true]: "rwa";
			case [false, false, false]: throw "invalid OpenOptions combinations";
		}

		if (options.create_new) {
			mode += "x";
		}

		mode += "b";

		return new File(p.toString(), cast Builtins.open(p.toString(), mode));
	}

	public static function create(p:Path):File {
		throw new NotImplementedException();
	}

	public static function createNew(p:Path):File {
		throw new NotImplementedException();
	}

	public static function readAll(p:Path):Bytes {
		throw new NotImplementedException();
	}

	public static function writeAll(p:Path, b:Bytes):Void {
		throw new NotImplementedException();
	}

	public static function appendAll(p:Path, b:Bytes):Void {
		throw new NotImplementedException();
	}

	final path:String;
	final file:RawIOBase;

	function new(path:String, file:RawIOBase) {
		this.path = path;
		this.file = file;
	}

	public function syncAll():Void {
		file.flush();
		Os.fsync(file.fileno());
	}

	public function syncData():Void {
		if (Builtins.hasattr(Os, "fdatasync")) {
			file.flush();
			Os.fdatasync(file.fileno());
		} else {
			syncAll();
		}
	}

	public function metadata():Metadata {
		throw new NotImplementedException();
	}

	public function setPermissions(perm:Permissions):Void {
		throw new NotImplementedException();
	}

	// TODO: technically these should all use a Int64 or even uint64 type, but `haxe.io.Bytes` uses an int length, so...

	public function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		final view:Memoryview = python.Syntax.arrayAccess(new Memoryview(bytes.getData()), [bufferOffset, bufferOffset + bufferLength]);
		return file.readinto(view);
	}

	public function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		final view:Memoryview = python.Syntax.arrayAccess(new Memoryview(bytes.getData()), [bufferOffset, bufferOffset + bufferLength]);
		return file.write(view);
	}

	public function seek(pos:SeekPos):haxe.Int64 {
		switch pos {
			case SeekBegin(offset):
				return file.seek(haxe.Int64.toInt(offset), SeekSet);
			case SeekCurrent(offset):
				return file.seek(haxe.Int64.toInt(offset), SeekSet);
			case SeekEnd(offset):
				return file.seek(haxe.Int64.toInt(offset), SeekSet);
		}
	}

	public function close():Void {
		throw new NotImplementedException();
	}
}
