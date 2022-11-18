package haxe.time;

// TODO: for the elapsed methods, how to handle times in the future?

/**
	Time measured from the system clock, used for eg file timestamps.
	Not monotonic, use MonotonicTime.now and MonotonicTime for that.
**/
@:coreType extern abstract SystemTime {
	/**
		The Unix Epoch, "1970-01-01 00:00:00 UTC".
	**/
	public static function unixEpoch():SystemTime;

	/**
		The current system time.
	**/
	public static function now():SystemTime;

	/**
		How long has passed since the time represented by this object.
	**/
	public function elapsed():Duration;

	@:op(A + B) function add(b:Duration):SystemTime;

	@:op(A - B) function sub(b:Duration):SystemTime;
}