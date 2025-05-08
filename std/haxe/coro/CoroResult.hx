package haxe.coro;

enum CoroResult<Y, R> {
	Yield(e:Y);
	Ret(e: R);
}