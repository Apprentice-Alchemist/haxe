package sys.net;

import haxe.io.Bytes;
import sys.net.IpAddress;

/**
	A User Datagram Protocol socket.
**/
@:coreApi
extern class DatagramSocket {
	public static function bind(address:SocketAddress):DatagramSocket;

	public var broadcast(get, set):Bool;
	public var multicastLoopV4(get, set):Bool;
	public var multicastLoopV6(get, set):Bool;
	public var ttl(get, set):Int;
	public var onlyV6(get, set):Bool;

	public function joinMulticastV4(multiaddr:Ipv4Addr, inter:Ipv4Addr):Void;
	public function joinMulticastV6(multiaddr:Ipv6Addr, inter:Int):Void;
	public function leaveMulticastV4(multiaddr:Ipv4Addr):Void;
	public function leaveMulticastV6(multiaddr:Ipv6Addr):Void;

	public function sendTo(buf:Bytes, bufOffset:Int, bufSize:Int, address:SocketAddress):Int;
	public function receiveFrom(buf:Bytes, bufOffset:Int, bufSize:Int):{bytesRead:Int, address:SocketAddress};

	public function connect(address:SocketAddress):Void;
	public function send(buf:Bytes, bufOffset:Int, bufSize:Int):Int;
	public function receive(buf:Bytes, bufOffset:Int, bufSize:Int):Int;

	private function get_broadcast():Bool;

	private function set_broadcast(value:Bool):Bool;

	private function get_multicastLoopV4():Bool;

	private function set_multicastLoopV4(value:Bool):Bool;

	private function get_multicastLoopV6():Bool;

	private function set_multicastLoopV6(value:Bool):Bool;

	private function get_ttl():Int;

	private function set_ttl(value:Int):Int;

	private function get_onlyV6():Bool;

	private function set_onlyV6(value:Bool):Bool;
}
