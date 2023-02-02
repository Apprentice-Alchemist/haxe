package haxe.time;

import java.lang.System;
import haxe.time.Duration;

abstract MonotonicTime(haxe.Int64) {
	/**
		The current time stamp of a monotonic clock.
	**/
	public static function now():MonotonicTime {
		return cast System.nanoTime();
	}
	/**
		How long has passed since the time represented by this object.
	**/
	public function elapsed():Duration {
		final now = System.nanoTime();
		return Duration.fromNanoseconds(now - this);
	}

	@:op(A + B) function add(b:Duration):MonotonicTime {
		return cast this + (b.toNanoseconds());
	}
	
	@:op(A - B) function sub(b:Duration):MonotonicTime {
		return cast this - (b.toNanoseconds());
	}
}

