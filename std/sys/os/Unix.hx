package sys.os;

import haxe.exceptions.NotImplementedException;
import sys.fs.Permissions;
import sys.fs.Metadata;
import sys.fs.Fs;
import sys.fs.File;

// TODO: document which targets support this, and which return nonsense even on Unix.

/**
	Unix specific extensions to sys.fs.Metadata

	On Windows and other non-Unix platforms these methods will not return consistent values.
**/
class MetadataExt {
	public static function uid(p:Metadata):Int {
		return 0;
	}

	public static function gid(p:Metadata):Int {
		return 0;
	}

	public static function dev(p:Metadata):haxe.Int64 // should be UInt64
	{
		return 0;
	}

	public static function ino(p:Metadata):haxe.Int64 // should be UInt64
	{
		return 0;
	}

	public static function nlink(p:Metadata):haxe.Int64 // should be UInt64
	{
		return 0;
	}

	public static function mode(p:Metadata):UInt {
		return 0;
	}

	public static function isBlockDevice(m:Metadata):Bool {
		return false;
	}

	public static function isCharDevice(m:Metadata):Bool {
		return false;
	}

	public static function isFifo(m:Metadata):Bool {
		return false;
	}

	public static function isSocket(m:Metadata):Bool {
		return false;
	}
}

/**
	Unix specific extensions to sys.fs.Permissions

	On Windows and other non-Unix platforms these methods will not return consistent values.
**/
class PermissionsExt {
	public static function mode(p:Permissions):UInt {
		return 0;
	}

	public static function setMode(p:Permissions):UInt {
		return 0;
	}
}

/**
	Unix specific extensions to sys.fs.File

	On Windows and other non-Unix platforms these methods will not return consistent values.
**/
class FileExt {
	public static function openWithModeAndFlags(_:Class<sys.fs.File>, mode:UInt, flags:Int):haxe.Result<File, sys.Error> {
		throw new NotImplementedException();
	}
}
