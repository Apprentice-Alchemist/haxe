package sys.fs;

import haxe.time.SystemTime;
import haxe.Result;
import java.nio.file.Files;

@:coreApi
class Metadata {
	final path:java.nio.file.Path;
	final followLinks:Bool;

	@:allow(sys.fs)
	function new(path:java.nio.file.Path, followLinks:Bool = false) {
		this.path = path;
		this.followLinks = followLinks;
	}

	public function isDir():Bool {
		return if(followLinks) Files.isDirectory(path) else Files.isDirectory(path, NOFOLLOW_LINKS);
	}

	public function isFile():Bool {
		return if (followLinks) Files.isRegularFile(path) else Files.isRegularFile(path, NOFOLLOW_LINKS);
	}

	public function isSymlink():Bool {
		return Files.isSymbolicLink(path);
	}

	public function size():haxe.Int64 {
		return Files.size(path);
	}

	public function modified():Null<haxe.time.SystemTime> {
		return SystemTime.unixEpoch(); // TODO
	}

	public function accessed():Null<haxe.time.SystemTime> {
		return SystemTime.unixEpoch(); // TODO
	}

	public function created():Null<haxe.time.SystemTime> {
		return SystemTime.unixEpoch(); // TODO
	}
}
