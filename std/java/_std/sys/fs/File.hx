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
	/**
		Opens the file in read-only mode.
	**/
	public static function open(p:Path):Result<File, Error> {
		var read:OpenOption = cast StandardOpenOption.READ;
		return openImpl(p, read);
	}

	/**
		Opens the file in write-only mode, creating it if needed.
	**/
	public static function create(p:Path):Result<File, Error> {
		var create:OpenOption = cast StandardOpenOption.CREATE;
		var write:OpenOption = cast StandardOpenOption.WRITE;
		return openImpl(p, create, write);
	}

	/**
		Opens the file in write-only mode, always creating a new one.
		Returns an error if the file already exists.
	**/
	public static function createNew(p:Path):Result<File, Error> {
		var createNew:OpenOption = cast StandardOpenOption.CREATE_NEW;
		var write:OpenOption = cast StandardOpenOption.WRITE;
		return openImpl(p, createNew, write);
	}

	public static function readAll(p:Path):Result<Bytes, Error> {
		var file = switch open(p) {
			case Ok(file): file;
			case Err(e): return Err(e);
		}
		var size = file.channel.size();
		var bytes = haxe.io.Bytes.alloc(Int64.toInt(size));
		file.read(bytes, 0, bytes.length);
		return Ok(bytes);
	}

	public static function writeAll(p:Path, b:Bytes):Result<Void /* TODO */, Error> {
		return Err(Unsupported);
	}

	public static function appendAll(p:Path, b:Bytes):Result<Void /* TODO */, Error> {
		return Err(Unsupported);
	}

	static function openImpl(path:Path, ...options:OpenOption):Result<File, Error> {
		final path = java.nio.file.Paths.get(path.toString());
		return try Ok(new File(path, FileChannel.open(path, ...options))) catch (e) {
			Err(Unknown);
		};
	}

	final path:java.nio.file.Path;
	final channel:FileChannel;

	function new(path:java.nio.file.Path, channel:FileChannel) {
		this.path = path;
		this.channel = channel;
	}

	public function syncAll():Result<Void /* TODO */, Error> {
		try {
			channel.force(true);
			return Ok((null : Void));
		} catch (e:ClosedChannelException) {
			return Err(Closed);
		} catch (e:IOException) {
			return Err(Unknown);
		}
	}

	public function syncData():Result<Void /* TODO */, Error> {
		try {
			channel.force(false);
			return Ok((null : Void));
		} catch (e:ClosedChannelException) {
			return Err(Closed);
		} catch (e:IOException) {
			return Err(Unknown);
		}
	}

	public function metadata():Result<Metadata, Error> {
		// TODO: timestamps, error handling?
		return Ok(new Metadata(path));
	}

	public function setPermissions(perm:Permissions):Result<Void /* TODO */, Error> {
		try {
			if (path.toFile().setWritable(true)) {
				return Err(NoPermissions);
			}
			return Ok((null : Void));
		} catch (e:SecurityException) {
			return Err(NoPermissions);
		}
	}

	public function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Result<Int, Error> {
		try {
			var i = channel.read(ByteBuffer.wrap(bytes.getData(), bufferOffset, bufferLength));
			return Ok(i);
		} catch(e) {
			return Err(Unknown);
		}
	}

	public function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Result<Int, Error> {
		try {
			var i = channel.write(ByteBuffer.wrap(bytes.getData(), bufferOffset, bufferLength));
			return Ok(i);
		} catch (e) {
			return Err(Unknown);
		}
	}

	public function seek(pos:SeekPos):Result<haxe.Int64, Error> {
		try {
			var realPos = switch pos {
				case SeekBegin(offset): offset;
				case SeekCurrent(offset): channel.position() + offset;
				case SeekEnd(offset): channel.size() + offset;
			}
			channel.position(realPos);
			return Ok(channel.position());
		} catch (e) {
			return Err(Unknown);
		}
	}

	public function close():Void {
		channel.close();
	}
}
