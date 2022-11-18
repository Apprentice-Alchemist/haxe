package sys.net;

import java.net.StandardSocketOptions;
import java.nio.channels.ServerSocketChannel;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;

using sys.net.SocketAddress.SocketAddressTools;

// TODO: docs
@:coreApi
class TcpListener {
	public static function bind(address:SocketAddress):TcpListener {
		var address = new InetSocketAddress(InetAddress.getByAddress(address.getBytes().getData()), address.getPort());
		var channel = ServerSocketChannel.open();
		channel.bind(address);
		return new TcpListener(channel);
	}

	final channel:ServerSocketChannel;

	function new(channel:ServerSocketChannel) {
		this.channel = channel;
	}

	public function localAddress():SocketAddress {
		return null;
	}

	public function accept():TcpStream {
		return new TcpStream(channel.accept());
	}

	public var ttl(get, set):Int;
	public var nonBlocking(get, set):Bool;

	public function close():Void {
		channel.close();
	}

	private function get_ttl():Int {
		return channel.getOption(StandardSocketOptions.IP_MULTICAST_TTL);
	}

	private function set_ttl(value:Int):Int {
		channel.setOption(StandardSocketOptions.IP_MULTICAST_TTL, value);
		return get_ttl();
	}

	private function get_nonBlocking():Bool {
		return !channel.isBlocking();
	}

	private function set_nonBlocking(value:Bool):Bool {
		channel.configureBlocking(!value);
		return !channel.isBlocking();
	}
}
