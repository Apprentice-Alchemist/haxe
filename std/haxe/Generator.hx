package haxe;

import haxe.coro.CoroResult;

private class GeneratorIterator<T> {
	var fun:() -> CoroResult<T, Unit>;
	var value:CoroResult<T, Unit>;

	public inline function new(fun, value) {
		this.fun = fun;
		this.value = value;
	}

	public inline function hasNext() {
		return value.match(Yield(_));
	}

	public inline function next() {
		var ret = switch value {
			case Yield(val): val;
			case Ret(_): throw ".next called after end";
		}
		this.value = this.fun();
		return ret;
	}
}

abstract Generator<T>(() -> CoroResult<T, Unit>) {
	public inline function iterator():Iterator<T> {
		return new GeneratorIterator(this, this());
	}

	public inline function resume():CoroResult<T, Unit> {
		return this();
	}

	public static function fromFun<T>(f:() -> CoroResult<T, Unit>):Generator<T> = cast f;
}