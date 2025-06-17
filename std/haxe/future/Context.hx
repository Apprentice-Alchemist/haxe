package haxe.future;

import haxe.Future;

abstract class Context {
	#if sys
	public final eventLoop:sys.thread.EventLoop;
	#end
	public abstract function wake():Void;
}