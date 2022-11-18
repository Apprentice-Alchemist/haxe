package haxe.time;

/**
	A span of time.
**/
@:coreApi abstract Duration {
	@:op(A + B) function add(b:Duration):Duration;
	@:commutative @:op(A * b) function imul(b:Int):Duration;
	@:op(A * b) function dmul(b:Duration):Duration;
	@:op(A - B) function sub(b:Duration):Duration;
	@:op(A / B) function div(b:Int):Duration;
}

