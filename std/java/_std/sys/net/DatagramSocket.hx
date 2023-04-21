package sys.net;

import sys.net.SocketAddress;
import java.net.DatagramPacket;
import java.nio.ByteBuffer;
import java.net.InetSocketAddress;
import java.net.InetAddress;
import java.nio.channels.DatagramChannel;
import haxe.io.Bytes;
import sys.net.IpAddress;

@:coreApi
class DatagramSocket {
	public static function bind(address:SocketAddress):DatagramSocket {
		var address = new InetSocketAddress(InetAddress.getByAddress(address.getBytes().getData()), address.getPort());
		var channel = DatagramChannel.open();
		channel.bind(address);
		return new DatagramSocket(channel);
	}

	final channel:DatagramChannel;

	function new(channel:DatagramChannel) {
		this.channel = channel;
	}

	public var broadcast(get, set):Bool;
	public var multicastLoopV4(get, set):Bool;
	public var multicastLoopV6(get, set):Bool;
	public var ttl(get, set):Int;
	public var onlyV6(get, set):Bool;

	public function joinMulticastV4(multiaddr:Ipv4Addr, inter:Ipv4Addr):Void {
		// channel.join()
	}
	public function joinMulticastV6(multiaddr:Ipv6Addr, inter:Int):Void {}
	public function leaveMulticastV4(multiaddr:Ipv4Addr):Void {}
	public function leaveMulticastV6(multiaddr:Ipv6Addr):Void {}

	public function sendTo(buf:Bytes, bufOffset:Int, bufSize:Int, address:SocketAddress):Int {
		var buf = ByteBuffer.wrap(buf.getData(), bufOffset, bufSize);
		var address = new InetSocketAddress(InetAddress.getByAddress(address.getBytes().getData()), address.getPort());
		return channel.send(buf, address);
	}

	public function receiveFrom(buf:Bytes, bufOffset:Int, bufSize:Int):{bytesRead:Int, address:SocketAddress} {
		// channel.receive doesn't give information about the lenght of received data
		var packet = new DatagramPacket(buf.getData(), bufOffset, bufSize);
		channel.socket().receive(packet);
		return {
			bytesRead: packet.getLength(),
			address: SocketAddressTools.fromBytes(null, Bytes.ofData(packet.getAddress().getAddress()), packet.getPort())
		};
	}

	public function connect(address:SocketAddress):Void {
		var address = new InetSocketAddress(InetAddress.getByAddress(address.getBytes().getData()), address.getPort());
		channel.connect(address);
	}

	public function send(buf:Bytes, bufOffset:Int, bufSize:Int):Int {
		var buf = ByteBuffer.wrap(buf.getData(), bufOffset, bufSize);
		return channel.write(buf);
	}
	public function receive(buf:Bytes, bufOffset:Int, bufSize:Int):Int {
		var buf = ByteBuffer.wrap(buf.getData(), bufOffset, bufSize);
		return channel.read(buf);
	}

	function get_broadcast():Bool {
		return false;
	}

	function set_broadcast(value:Bool):Bool {
		return false;
	}

	function get_multicastLoopV4():Bool {
		return false;
	}

	function set_multicastLoopV4(value:Bool):Bool {
		return false;
	}

	function get_multicastLoopV6():Bool {
		return false;
	}

	function set_multicastLoopV6(value:Bool):Bool {
		return false;
	}

	function get_ttl():Int {
		return 0;
	}

	function set_ttl(value:Int):Int {
		return 0;
	}

	function get_onlyV6():Bool {
		return false;
	}

	function set_onlyV6(value:Bool):Bool {
		return false;
	}
}
