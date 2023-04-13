package sys.net;

import java.net.ServerSocket;

// TODO: docs

@:coreApi
class TcpListener {
	public static function bind(address:SocketAddress):TcpListener {
		var sock = new ServerSocket();
		// sock.bind()
		return null;
	}
	public function localAddress():SocketAddress {
		return null;
	}
	public function accept():TcpStream {
		return null;
	}

	public var ttl(get, set):Int;
	public var nonBlocking(get, set):Bool;

	public function close():Void {}

	private	function get_ttl():Int {
		return cast null;
	}
	private	function set_ttl(value:Int):Int {
		return cast null;
	}
	private	function get_nonBlocking():Bool {
		return cast null;
	}
	private	function set_nonBlocking(value:Bool):Bool {
		return cast null;
	}
}
