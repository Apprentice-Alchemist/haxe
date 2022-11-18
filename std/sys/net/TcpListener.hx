package sys.net;

// TODO: docs

@:coreApi
extern class TcpListener {
	static function bind(address:SocketAddress):TcpListener;
	function localAddress():SocketAddress;
	function accept():TcpStream;

	public var ttl(get, set):Int;
	public var nonBlocking(get, set):Bool;

	function close():Void;

	private	function get_ttl():Int;
	private	function set_ttl(value:Int):Int;
	private	function get_nonBlocking():Bool;
	private	function set_nonBlocking(value:Bool):Bool;
}
