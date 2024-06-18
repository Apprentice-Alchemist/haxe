package sys.fs;

import haxe.exceptions.NotImplementedException;
import python.lib.Os;

@:coreApi
class Metadata {
	final stat:Stat;

	@:allow(sys.fs)
	function new(path:String, followSymlinks:Bool) {
		stat = followSymlinks ? Os.stat(path) : Os.lstat(path);
	}

	public function isDir():Bool {
		return Stat.S_ISDIR(stat.st_mode) != 0;
	}
	
	public function isFile():Bool {
		return !isDir() && !isSymlink();
	}
	
	public function isSymlink():Bool {
		return Stat.S_ISLNK(stat.st_mode) != 0;
	}

	public function size():haxe.Int64 {
		return stat.st_size
	}

	public function modified():Null<haxe.time.SystemTime> {
		throw new NotImplementedException();
	}

	public function accessed():Null<haxe.time.SystemTime> {
		throw new NotImplementedException();
	}

	public function created():Null<haxe.time.SystemTime> {
		throw new NotImplementedException();
	}
}
