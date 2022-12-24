package sys.net;

// TODO: docs

enum Shutdown {
	Read;
	Write;
	Both;
}

@:coreApi
extern class TcpStream {
	static function connect(address:SocketAddress, ?timeout:Int):Result<TcpStream, Error>;
	function peerAddress():Address;
	function localAddress():Address;
	function shutdown(how:Shutdown):Void;

	// TODO: all these operations may or may not be fallible?

	var readTimeout(get, set):Int;
	var writeTimeout(get, set):Int;
	var noDelay(get, set):Bool;
	var linger(get, set):Null<haxe.time.Duration>;
	var nonBlocking(get, set):Bool;
	var timeToLive(get, set):Int;
}
