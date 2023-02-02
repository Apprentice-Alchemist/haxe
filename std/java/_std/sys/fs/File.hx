package sys.fs;

import haxe.Int64;
import java.nio.ByteBuffer;
import java.lang.SecurityException;
import haxe.time.SystemTime;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.channels.ClosedChannelException;
import java.io.IOException;
import java.nio.file.OpenOption;
import java.nio.file.StandardOpenOption;
import java.nio.channels.FileChannel;
import java.nio.channels.AsynchronousFileChannel;
import java.io.RandomAccessFile;
import haxe.io.Bytes;
import haxe.Result;
import sys.fs.Metadata;
import sys.Error;
import sys.fs.Path;
import sys.fs.SeekPos;
import java.io.File as NativeFile;

@:coreApi
class File {
	public static function open(p:Path):File {
		var read:OpenOption = cast StandardOpenOption.READ;
		return openImpl(p, read);
	}

	public static function create(p:Path):File {
		var create:OpenOption = cast StandardOpenOption.CREATE;
		var write:OpenOption = cast StandardOpenOption.WRITE;
		return openImpl(p, create, write);
	}

	public static function createNew(p:Path):File {
		var createNew:OpenOption = cast StandardOpenOption.CREATE_NEW;
		var write:OpenOption = cast StandardOpenOption.WRITE;
		return openImpl(p, createNew, write);
	}

	public static function readAll(p:Path):Bytes {
		var file = open(p);
		var size = file.channel.size();
		var bytes = haxe.io.Bytes.alloc(Int64.toInt(size));
		file.read(bytes, 0, bytes.length);
		return bytes;
	}

	public static function writeAll(p:Path, b:Bytes):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	public static function appendAll(p:Path, b:Bytes):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function openImpl(path:Path, ...options:OpenOption):File {
		final path = java.nio.file.Paths.get(path.toString());
		return try new File(path, FileChannel.open(path, ...options)) catch (e) {
			throw e;
		};
	}

	final path:java.nio.file.Path;
	final channel:FileChannel;

	function new(path:java.nio.file.Path, channel:FileChannel) {
		this.path = path;
		this.channel = channel;
	}

	public function syncAll():Void {
		try {
			channel.force(true);
			// return Ok((null : Void));
		} catch (e:ClosedChannelException) {
			// return Err(Closed);
		} catch (e:IOException) {
			// return Err(Unknown);
		}
	}

	public function syncData():Void {
		try {
			channel.force(false);
			// return Ok((null : Void));
		} catch (e:ClosedChannelException) {
			// return Err(Closed);
		} catch (e:IOException) {
			// return Err(Unknown);
		}
	}

	public function metadata():Metadata {
		return new Metadata(path);
	}

	public function setPermissions(perm:Permissions):Void {
		try {
			if (path.toFile().setWritable(true)) {
				// return Err(NoPermissions);
			}
			// return Ok((null : Void));
		} catch (e:SecurityException) {
			// return Err(NoPermissions);
		}
	}

	public function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		try {
			return channel.read(ByteBuffer.wrap(bytes.getData(), bufferOffset, bufferLength));
			// return Ok(i);
		} catch (e) {
			throw e;
			// return Err(Unknown);
		}
	}

	public function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		return channel.write(ByteBuffer.wrap(bytes.getData(), bufferOffset, bufferLength));
	}

	public function seek(pos:SeekPos):Int64 {
		var realPos = switch pos {
			case SeekBegin(offset): offset;
			case SeekCurrent(offset): channel.position() + offset;
			case SeekEnd(offset): channel.size() + offset;
		}
		channel.position(realPos);
		return channel.position();
	}

	public function close():Void {
		channel.close();
	}
}
