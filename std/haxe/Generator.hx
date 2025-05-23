package haxe;

import haxe.coro.CoroResult;

private class GeneratorIterator<T> {
	var gen:Generator<T>;
	var value:CoroResult<T, Unit>;

	public inline function new(gen: Generator<T>) {
		this.gen = gen;
		this.value = gen.resume();
	}

	public inline function hasNext() {
		return value.match(Yield(_));
	}

	public inline function next() {
		var ret = switch value {
			case Yield(val): val;
			case Ret(_): throw ".next called after end";
		}
		this.value = this.gen.resume();
		return ret;
	}
}

abstract Generator<T>(() -> CoroResult<T, Unit>) {
	public inline function iterator():Iterator<T> {
		// using `abstract` causes a typing error
		return new GeneratorIterator(cast this);
	}

	public inline function resume():CoroResult<T, Unit> {
		return this();
	}

	public static function fromFun<T>(f:() -> CoroResult<T, Unit>):Generator<T> = cast f;
}