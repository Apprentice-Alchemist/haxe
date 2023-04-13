package sys.net;

import haxe.time.Duration;

@:coreApi
extern class TcpStream {
	static function connect(address:SocketAddress, ?timeout:Int):TcpStream;
	function peerAddress():SocketAddress;
	function localAddress():SocketAddress;
	function shutdown(how:Shutdown):Void;

	var readTimeout(get, set):Null<Duration>;
	var writeTimeout(get, set):Null<Duration>;
	var noDelay(get, set):Bool;
	var linger(get, set):Null<Duration>;
	var nonBlocking(get, set):Bool;
	var timeToLive(get, set):Int;

	function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int;
	function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int;

	function close():Void;

	private function get_readTimeout():Null<Duration>;
	private function set_readTimeout(value:Null<Duration>):Null<Duration>;
	private function get_writeTimeout():Null<Duration>;
	private function set_writeTimeout(value:Null<Duration>):Null<Duration>;
	private function get_noDelay():Bool;
	private function set_noDelay(value:Bool):Bool;
	private function get_linger():Null<Duration>;
	private function set_linger(value:Null<Duration>):Null<Duration>;
	private function get_nonBlocking():Bool;
	private function set_nonBlocking(value:Bool):Bool;
	private function get_timeToLive():Int;
	private function set_timeToLive(value:Int):Int;
}
