package sys.fs;

@:structInit class OpenOptions {
	var read:Bool = true;
	var write:Bool = false;
	var append:Bool = false;
	var truncate:Bool = false;
	var create:Bool = false;
	var create_new:Bool = false;
}