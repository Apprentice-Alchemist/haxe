package sys.fs;

import haxe.time.SystemTime;
import haxe.Result;
import java.nio.file.Files;

@:coreApi
class Metadata {
	final path:java.nio.file.Path;

	@:allow(sys.fs)
	function new(path:java.nio.file.Path) {
		this.path = path;
	}

	public function isDir():Bool {
		return Files.isDirectory(path);
	}

	public function isFile():Bool {
		return Files.isRegularFile(path);
	}

	public function isSymlink():Bool {
		return Files.isSymbolicLink(path);
	}

	public function size():haxe.Int64 {
		return Files.size(path);
	}

	public function permissions():Permissions {
		return new Permissions(!Files.isWritable(path));
	}

	public function modified():Null<haxe.time.SystemTime> {
		return SystemTime.unixEpoch();
	}

	public function accessed():Null<haxe.time.SystemTime> {
		return SystemTime.unixEpoch();
	}

	public function created():Null<haxe.time.SystemTime> {
		return SystemTime.unixEpoch();
	}
}
