package sys.fs;

import haxe.Result;
import sys.fs.Metadata;
import sys.fs.Path;
import sys.Error;

@:coreApi
extern class Fs {
	static function metadata(path:Path):Metadata;
	/**
		Returns the metadata for `path` without following symlinks.
	**/
	static function symlinkMetadata(path:Path):Metadata;
	static function setPermissions(path:Path, perm:Permissions):Void;
	static function copy(from:Path, to:Path):Void;
	static function rename(from:Path, to:Path):Void;
	static function readDir(path:Path):Iterator<Path>;
	static function createDir(path:Path):Void;
	static function createDirRec(path:Path):Void;
	static function removeDir(path:Path):Void;
	static function removeDirRec(path:Path):Void;
	static function removeFile(path:Path):Void;
}
