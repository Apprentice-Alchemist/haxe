package haxe.future;

import haxe.Future;

abstract class Context {
	public abstract function wake():Void;
}