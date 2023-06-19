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

private final READ:OpenOption = cast StandardOpenOption.READ;
private final WRITE:OpenOption = cast StandardOpenOption.WRITE;
private final CREATE:OpenOption = cast StandardOpenOption.CREATE;
private final CREATE_NEW:OpenOption = cast StandardOpenOption.CREATE_NEW;
private final APPEND:OpenOption = cast StandardOpenOption.APPEND;
private final TRUNCATE_EXISTING:OpenOption = cast StandardOpenOption.TRUNCATE_EXISTING;

@:coreApi
class File {
	public static function open(p:Path, ?options:OpenOptions):File {
		options ??= {read: true};
		var opts = new java.util.HashSet();
		if(options.read) opts.add(READ);
		if(options.write) opts.add(WRITE);
		if(options.create) opts.add(CREATE);
		if(options.create_new) opts.add(CREATE_NEW);
		if(options.append) opts.add(APPEND);
		if(options.truncate) opts.add(TRUNCATE_EXISTING);
		final path = java.nio.file.Paths.get(p.toString());
		return try new File(path, FileChannel.open(path, opts)) catch (e) {
			throw e;
		};
	}

	public static function create(p:Path):File {
		return open(p, {write: true});
	}

	public static function createNew(p:Path):File {
		return open(p, {write: true, create_new: true});
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
