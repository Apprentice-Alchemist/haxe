package haxe.time;

// TODO: for the elapsed methods, how to handle times in the future?

/**
	Time measured from a monotonic clock.
**/
@:coreApi extern abstract MonotonicTime {
	/**
		The current time stamp of a monotonic clock.
	**/
	public static function now():MonotonicTime;
	/**
		How long has passed since the time represented by this object.
	**/
	public function elapsed():Duration;
	@:op(A + B) function add(b:Duration):MonotonicTime;
	@:op(A - B) function sub(b:Duration):MonotonicTime;
}

