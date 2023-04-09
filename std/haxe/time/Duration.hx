package haxe.time;

private class DurationInner {
	public final seconds:haxe.Int64;
	public final nanoseconds:Int;

	public inline function new(seconds:haxe.Int64, nanos:Int) {
		this.seconds = seconds;
		this.nanoseconds = nanos;
	}
}

private inline var NANOSECONDS_PER_SECOND = 1_000_000_000;

/**
	A span of time.
**/
abstract Duration(DurationInner) from DurationInner {
	public static function fromNanoseconds(nanos:haxe.Int64):Duration {
		final seconds = nanos / NANOSECONDS_PER_SECOND;
		final nanos = nanos % NANOSECONDS_PER_SECOND;
		return new DurationInner(seconds, Int64.toInt(nanos));
	}

	public function new(seconds:haxe.Int64, nanos:Int) {
		this = new DurationInner(seconds, nanos);
	}

	public function seconds():haxe.Int64 {
		return this.seconds;
	}

	public function subSecondNanos():Int {
		return this.nanoseconds;
	}

	@:op(A + B) function add(b:Duration):Duration {
		var seconds = this.seconds + b.seconds();
		var nanos = this.nanoseconds + b.subSecondNanos();
		seconds += Std.int(nanos / NANOSECONDS_PER_SECOND);
		nanos %= NANOSECONDS_PER_SECOND;
		return new Duration(seconds, nanos);
	}

	@:commutative @:op(A * b) function imul(b:Int):Duration {
		var nanos = this.nanoseconds * b;
		var extra_seconds = Std.int(nanos / NANOSECONDS_PER_SECOND);
		nanos %= NANOSECONDS_PER_SECOND;
		return new Duration(this.seconds * b + extra_seconds, nanos);
	}

	// @:op(A * b) function dmul(b:Duration):Duration;

	// @:op(A - B) function sub(b:Duration):Duration;

	// @:op(A / B) function div(b:Int):Duration;

	// TODO: overflow behaviour?
	public function toNanoseconds():haxe.Int64 {
		return this.seconds * NANOSECONDS_PER_SECOND + this.nanoseconds;
	}
}
