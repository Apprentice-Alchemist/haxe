package sys.net;

import java.nio.channels.SelectionKey;
import java.nio.channels.spi.SelectorProvider;
import java.net.InetSocketAddress;
import java.net.InetAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import haxe.time.Duration;

@:coreApi
class TcpStream {
	public static function connect(address:SocketAddress, ?timeout:Duration):TcpStream {
		var channel = SocketChannel.open();
		if(timeout != null) {
			channel.configureBlocking(false);
			channel.connect(new InetSocketAddress(InetAddress.getByAddress(address.getBytes().getData()), address.getPort()));
			var selector = SelectorProvider.provider().openSelector();
			channel.register(selector, SelectionKey.OP_CONNECT);
			if(selector.select(timeout.toMilliseconds()) == 1) {
				channel.finishConnect();
				selector.close();
			} else {
				throw "timeout reached";
			}
			channel.configureBlocking(true);
		} else {
			channel.connect(new InetSocketAddress(InetAddress.getByAddress(address.getBytes().getData()), address.getPort()));
		}
		return new TcpStream(channel);
	}

	final channel:SocketChannel;

	@:allow(sys.net)
	function new(channel:SocketChannel) {
		this.channel = channel;
	}

	public function peerAddress():SocketAddress {
		return null;
	}

	public function localAddress():SocketAddress {
		return null;
	}

	public function shutdown(how:Shutdown):Void {
		switch how {
			case Read:
				channel.shutdownInput();
			case Write:
				channel.shutdownOutput();
			case Both:
				channel.shutdownInput();
				channel.shutdownOutput();
		}
	}

	public var readTimeout(get, set):Null<Duration>;
	public var writeTimeout(get, set):Null<Duration>;
	public var noDelay(get, set):Bool;
	public var linger(get, set):Null<Duration>;
	public var nonBlocking(get, set):Bool;
	public var timeToLive(get, set):Int;

	public function read(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		var buf = ByteBuffer.wrap(bytes.getData(), bufferOffset, bufferLength);
		return channel.read(buf);
	}

	public function write(bytes:haxe.io.Bytes, bufferOffset:Int, bufferLength:Int):Int {
		var buf = ByteBuffer.wrap(bytes.getData(), bufferOffset, bufferLength);
		return channel.write(buf);
	}

	public function close():Void {
		channel.close();
	}

	private function get_readTimeout():Null<Duration> {
		return null;
	}

	private function set_readTimeout(value:Null<Duration>):Null<Duration> {
		return null;
	}

	private function get_writeTimeout():Null<Duration> {
		return null;
	}

	private function set_writeTimeout(value:Null<Duration>):Null<Duration> {
		return null;
	}

	private function get_noDelay():Bool {
		return false;
	}

	private function set_noDelay(value:Bool):Bool {
		return false;
	}

	private function get_linger():Null<Duration> {
		return null;
	}

	private function set_linger(value:Null<Duration>):Null<Duration> {
		return null;
	}

	private function get_nonBlocking():Bool {
		return !channel.isBlocking();
	}

	private function set_nonBlocking(value:Bool):Bool {
		channel.configureBlocking(!value);
		return get_nonBlocking();
	}

	private function get_timeToLive():Int {
		return 0;
	}

	private function set_timeToLive(value:Int):Int {
		return 0;
	}
}
