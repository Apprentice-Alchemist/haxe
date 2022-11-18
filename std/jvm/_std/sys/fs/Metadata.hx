package sys.fs;

import java.nio.file.attribute.BasicFileAttributes;
import haxe.time.SystemTime;
import java.nio.file.Files;

@:coreApi
class Metadata {
	final attr:BasicFileAttributes;

	@:allow(sys.fs)
	function new(path:java.nio.file.Path, followLinks:Bool = false) {
		if (followLinks) {
			this.attr = Files.readAttributes(path, java.Lib.toNativeType(BasicFileAttributes));
		} else {
			this.attr = Files.readAttributes(path, java.Lib.toNativeType(BasicFileAttributes), NOFOLLOW_LINKS);
		}
	}

	public function isDir():Bool {
		return attr.isDirectory();
	}

	public function isFile():Bool {
		return attr.isRegularFile();
	}

	public function isSymlink():Bool {
		return attr.isSymbolicLink();
	}

	public function size():haxe.Int64 {
		return attr.size();
	}

	public function modified():Null<haxe.time.SystemTime> {
		return attr.lastModifiedTime().toInstant();
	}

	public function accessed():Null<haxe.time.SystemTime> {
		return attr.lastAccessTime().toInstant();
	}

	public function created():Null<haxe.time.SystemTime> {
		return attr.creationTime().toInstant();
	}
}
