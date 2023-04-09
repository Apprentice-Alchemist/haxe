package sys.fs;

import java.nio.file.attribute.BasicFileAttributes;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.FileVisitor;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.Path as JavaPath;
import sys.fs.Metadata;
import sys.fs.Path;
import sys.Error;
import sys.fs.DirEntry;

@:coreApi
class Fs {
	@:allow(sys.fs)
	static function getPath(path:Path):java.nio.file.Path {
		return Paths.get(path.toString());
	}

	public static function metadata(path:Path):Metadata {
		var path = Paths.get(path.toString());
		if (Files.exists(path)) {
			return new Metadata(path, true);
		} else {
			throw "doesn't exist";
		}
	}

	public static function symlinkMetadata(path:Path):Metadata {
		var path = Paths.get(path.toString());
		if (Files.exists(path)) {
			return new Metadata(path, false);
		} else {
			throw "doesn't exist";
		}
	}

	public static function setPermissions(path:Path, perm:Permissions):Void {}

	public static function copy(from:Path, to:Path):Void {
		Files.copy(getPath(from), getPath(to));
	}

	public static function rename(from:Path, to:Path):Void {
		Files.move(getPath(from), getPath(to));
	}

	public static function readDir(path:Path):Iterator<DirEntry> {
		return new DirIterator(path);
	}

	public static function createDir(path:Path):Void {
		Files.createDirectory(getPath(path));
	}

	public static function createDirRec(path:Path):Void {
		Files.createDirectories(getPath(path));
	}

	public static function removeDir(path:Path):Void {
		Files.delete(getPath(path));
	}

	public static function removeDirRec(path:Path):Void {
		Files.walkFileTree(getPath(path), new RecursiveDeleter());
	}

	public static function removeFile(path:Path):Void {
		Files.delete(getPath(path));
	}
}

private class RecursiveDeleter implements FileVisitor<java.nio.file.Path> {
	public function new() {}

	public function visitFile(file, attrs) {
		Files.delete(file);
		return FileVisitResult.CONTINUE;
	}

	public function postVisitDirectory(path, e) {
		if (e == null) {
			Files.delete(path);
			return CONTINUE;
		} else {
			throw e;
		}
	}

	public function preVisitDirectory(param1:java.nio.file.Path, param2:BasicFileAttributes):FileVisitResult {
		return FileVisitResult.CONTINUE;
	}

	public function visitFileFailed(param1:java.nio.file.Path, param2:IOException):FileVisitResult {
		return FileVisitResult.CONTINUE;
	}
}

private class DirIterator {
	final stream:DirectoryStream<JavaPath>;
	final iter:java.util.Iterator<JavaPath>;

	public function new(path:Path) {
		this.stream = Files.newDirectoryStream(Fs.getPath(path));
		this.iter = stream.iterator();
	}

	public function hasNext() {
		return iter.hasNext();
	}

	public function next() {
		return new DirEntry(untyped iter.next().toString());
	}
}
