package sys.net;

import haxe.time.Duration;

// TODO: docs

enum Shutdown {
	Read;
	Write;
	Both;
}

@:coreApi
extern class TcpStream {
	static function connect(address:SocketAddress, ?timeout:Int):TcpStream;
	function peerAddress():Address;
	function localAddress():Address;
	function shutdown(how:Shutdown):Void;

	var readTimeout(get, set):Int;
	var writeTimeout(get, set):Int;
	var noDelay(get, set):Bool;
	var linger(get, set):Null<haxe.time.Duration>;
	var nonBlocking(get, set):Bool;
	var timeToLive(get, set):Int;

	function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int;
	function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int;

	function close():Void;

	private function get_readTimeout():Int;
	private function set_readTimeout(value:Int):Int;
	private function get_writeTimeout():Int;
	private function set_writeTimeout(value:Int):Int;
	private function get_noDelay():Bool;
	private function set_noDelay(value:Bool):Bool;
	private function get_linger():Null<Duration>;
	private function set_linger(value:Null<Duration>):Null<Duration>;
	private function get_nonBlocking():Bool;
	private function set_nonBlocking(value:Bool):Bool;
	private function get_timeToLive():Int;
	private function set_timeToLive(value:Int):Int;
}
