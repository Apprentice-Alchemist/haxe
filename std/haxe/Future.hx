package haxe;

import haxe.coro.CoroResult;
import haxe.future.Context;

enum Poll<T> {
	Pending;
	Ready(val:T);
}

abstract Future<T>((Context) -> CoroResult<Unit, T>) {
	public function poll(ctx:Context):Poll<T> {
		switch this(ctx) {
			case Yield(_): return Pending;
			case Ret(val): return Ready(val);
		}
	}

	public static function fromFun<T>(f:(Context) -> CoroResult<Unit, T>):Future<T> = cast f;
}
