package haxe.time;

private class DurationInner {
	final seconds:haxe.Int64;
	final nanoseconds:Int;

	public inline function new(seconds:haxe.Int64, nanos:Int) {
		this.seconds = seconds;
		this.nanoseconds = nanos;
	}
}

private inline var NANOSECONDS_PER_SECOND = 1_000_000_000;
/**
	A span of time.
**/
abstract Duration(DurationInner) {
	public function new(seconds:haxe.Int64, nanos:Int) {
		this = new DurationInner(seconds, nanos);
	}
	@:op(A + B) function add(b:Duration):Duration {
		var seconds = this.seconds + b.seconds;
		var nanos = this.nanoseconds + b.nanoseconds;
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
	@:op(A * b) function dmul(b:Duration):Duration;
	@:op(A - B) function sub(b:Duration):Duration;
	@:op(A / B) function div(b:Int):Duration;
}

