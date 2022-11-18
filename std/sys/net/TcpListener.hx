package sys.net;

import haxe.Result;

// TODO: docs

@:coreApi
extern class TcpListener {
	static function bind(address:SocketAddress):Result<TcpListener, Error>;
	function localAddress():Address;
	function accept():TcpStream;

	public var ttl(get, set):Int;
	public var nonBlocking(get, set):Bool;
}
