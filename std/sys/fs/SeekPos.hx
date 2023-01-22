package sys.fs;

enum SeekPos {
	SeekBegin(offset:haxe.Int64);
	SeekCurrent(offset:haxe.Int64);
	SeekEnd(offset:haxe.Int64);
}