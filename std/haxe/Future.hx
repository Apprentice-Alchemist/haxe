package haxe;

import haxe.coro.CoroResult;

enum Poll<T> {
	Pending;
	Ready(val:T);
}

typedef FutureContext = () -> Void;

abstract Future<T>((FutureContext) -> CoroResult<Unit, T>) {
	public function poll(ctx:FutureContext):Poll<T> {
		switch this(ctx) {
			case Yield(_): return Pending;
			case Ret(val): return Ready(val);
		}
	}

	public static function fromFun<T>(f:(FutureContext) -> CoroResult<Unit, T>) = cast f;
}
