package sys.fs;

@:structInit
@:publicFields
class OpenOptions {
	var read:Bool = true;
	var write:Bool = false;
	/** implies write access **/
	var append:Bool = false;
	/** only has effect if write access is given too **/
	var truncate:Bool = false;
	/** requires write or append to actually create a file **/
	var create:Bool = false;
	/** create a new file and fail if it exists already. **/
	var create_new:Bool = false;
}