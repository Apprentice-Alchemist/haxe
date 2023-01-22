package sys.fs;

import haxe.Result;
import sys.fs.Metadata;

extern class Fs {
	static function metadata(path:Path):Result<Metadata, Error>;
	/**
		Returns the metadata for `path` without following symlinks.
	**/
	static function symlinkMetadata(path:Path):Result<Metadata, Error>;
	static function setPermissions(path:Path, perm:Permissions):Result<Void /* TODO */, Error>;
	static function copy(from:Path, to:Path):Result<Void /* TODO */, Error>;
	static function rename(from:Path, to:Path):Result<Void /* TODO */, Error>;
	static function readDir(path:Path):Result<Iterator<Result<Path, Error>>, Error>;
	static function createDir(path:Path):Result<Void /* TODO */, Error>;
	static function createDirRec(path:Path):Result<Void /* TODO */, Error>;
	static function removeDir(path:Path):Result<Void /* TODO */, Error>;
	static function removeDirRec(path:Path):Result<Void /* TODO */, Error>;
	static function removeFile(path:Path):Result<Void /* TODO */, Error>;
}
