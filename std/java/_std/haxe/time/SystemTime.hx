package haxe.time;

import haxe.time.Duration;
import java.time.Instant;

abstract SystemTime(java.time.Instant) {
	/**
		The Unix Epoch, "1970-01-01 00:00:00 UTC".
	**/
	public static function unixEpoch():SystemTime {
		return cast Instant.EPOCH;
	}

	/**
		The current system time.
	**/
	public static function now():SystemTime {
		return cast Instant.now();
	}

	/**
		How long has passed since the time represented by this object.
	**/
	public function elapsed():Duration {
		final now = Instant.now();
		final duration = java.time.Duration.between(this, now);
		return new haxe.time.Duration(duration.getSeconds(), duration.getNano());
	}

	@:op(A + B) function add(b:Duration):SystemTime {
		return null;
	}

	@:op(A - B) function sub(b:Duration):SystemTime {
		return null;
	}
}