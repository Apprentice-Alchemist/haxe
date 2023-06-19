package sys.fs;

import haxe.Result;
import sys.fs.Metadata;
import cs.system.io.File as CsFile;

class Fs {
	static function metadata(path:Path):Metadata {
		return new Metadata(path.toString(), true);
	}

	/**
		Returns the metadata for `path` without following symlinks.
	**/
	static function symlinkMetadata(path:Path):Metadata {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function setPermissions(path:Path, perm:Permissions):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function copy(from:Path, to:Path):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function rename(from:Path, to:Path):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function readDir(path:Path):Iterator<DirEntry> {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function createDir(path:Path):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function createDirRec(path:Path):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function removeDir(path:Path):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function removeDirRec(path:Path):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	static function removeFile(path:Path):Void {
		throw new haxe.exceptions.NotImplementedException();
	}
}
