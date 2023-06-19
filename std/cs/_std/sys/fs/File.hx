package sys.fs;

import cs.system.io.SeekOrigin;
import cs.system.io.FileStream;
import cs.system.io.FileAccess;
import cs.system.io.FileMode;
import haxe.Int64;
import cs.system.io.File as CsFile;
import haxe.time.SystemTime;
import haxe.io.Bytes;
import haxe.Result;
import sys.fs.Metadata;
import sys.Error;
import sys.fs.Path;
import sys.fs.SeekPos;

@:coreApi
class File {
	public static function open(p:Path, ?options:OpenOptions):File {
		options ??= {read: true};
		var mode:FileMode = if (options.append) Append else if (options.truncate) Truncate else if (options.create_new) CreateNew else if (options.create)
			Create else Open;
		var access:FileAccess = if (options.read && options.write) ReadWrite else if (options.write) Write else if (options.read) Read else
			throw "can never read nor write to file";
		final stream = CsFile.Open(p.toString(), mode, access);
		return new File(p.toString(), stream);
	}

	public static function create(p:Path):File {
		return open(p, {write: true});
	}

	public static function createNew(p:Path):File {
		return open(p, {write: true, create_new: true});
	}

	public static function readAll(p:Path):Bytes {
		return Bytes.ofData(CsFile.ReadAllBytes(p.toString()));
	}

	public static function writeAll(p:Path, b:Bytes):Void {
		CsFile.WriteAllBytes(p.toString(), b.getData());
	}

	public static function appendAll(p:Path, b:Bytes):Void {
		final file = open(p, {append: true, write: true});
		file.write(b, 0, b.length);
		file.close();
	}

	final path:String;
	final stream:FileStream;

	function new(path:String, stream:FileStream) {
		this.path = path;
		this.stream = stream;
	}

	public function syncAll():Void {
		stream.Flush();
	}

	public function syncData():Void {
		stream.Flush();
	}

	public function metadata():Metadata {
		return new Metadata(path, true);
	}

	public function setPermissions(perm:Permissions):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		return stream.Read(bytes.getData(), bufferOffset, bufferLength);
	}

	public function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		var prevPos = stream.Position;
		stream.Write(bytes.getData(), bufferOffset, bufferLength);
		return (cast stream.Position - prevPos:Int);
	}

	public function seek(pos:SeekPos):Int64 {
		var origin:SeekOrigin;
		var offset:cs.StdTypes.Int64;
		switch pos {
			case SeekBegin(_offset):
				offset = _offset;
				origin = Begin;
			case SeekCurrent(_offset):
				offset = _offset;
				origin = Current;
			case SeekEnd(_offset):
				offset = _offset;
				origin = End;
		}

		return stream.Seek(offset, origin);
	}

	public function close():Void {
		stream.Close();
	}
}
