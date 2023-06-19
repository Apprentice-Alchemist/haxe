package sys.fs;

import cs.system.DateTime;
import cs.system.io.FileInfo;
import cs.system.io.FileAttributes;
import haxe.Result;
import cs.system.io.File as CsFile;

class Metadata {
	final path:String;
	final followSymlinks:Bool;
	final attributes:FileAttributes;
	final fileInfo:FileInfo;

	@:allow(sys.fs)
	function new(path:String, followSymlinks:Bool) {
		this.path = path;
		this.followSymlinks = followSymlinks;
		this.attributes = CsFile.GetAttributes(this.path);
		fileInfo = new FileInfo(path);
		#if (cs_ver>=6)
		if(followSymlinks && fileInfo.LinkTarget != null) {
			fileInfo = fileInfo.ResolveTarget(true);
		}
		#end
	}

	private inline function contains(attr:FileAttributes):Bool {
		return untyped (attributes & attr) == attr;
	}

	function isDir():Bool {
		return contains(Directory);
	}

	function isFile():Bool {
		return !isDir() && !isSymlink();
	}

	function isSymlink():Bool {
		#if (cs_ver >= 6)
		return fileInfo.LinkTarget != null
		#else
		return false;
		#end
	}

	function size():haxe.Int64 {
		return fileInfo.Length;
	}

	function permissions():Permissions {
		throw new haxe.exceptions.NotImplementedException();
	}

	function modified():Null<haxe.time.SystemTime> {
		// return fileInfo.LastWriteTime;
		throw new haxe.exceptions.NotImplementedException();
	}

	function accessed():Null<haxe.time.SystemTime> {
		throw new haxe.exceptions.NotImplementedException();
	}

	function created():Null<haxe.time.SystemTime> {
		throw new haxe.exceptions.NotImplementedException();
	}
}

private function SystemTimeFromDateTime(date:DateTime) {
	// DateTime.UnixEpoch;
	// return new haxe.time.SystemTime(date);
}

// extern class Permissions {
// 	/**
// 		Note that this does not affect the file, use `Fs.setPermissions`.
// 	**/
// 	var readonly(get, set):Bool;
// }
