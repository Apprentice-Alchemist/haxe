package sys.fs;

@:coreApi
extern class Permissions {
	/**
		Note that this does not affect the file, use `Fs.setPermissions`.
	**/
	var readonly(get, set):Bool;
}