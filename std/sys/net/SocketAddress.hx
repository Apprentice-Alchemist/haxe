package sys.net;

import haxe.io.Bytes;
import sys.net.IpAddress;

@:using(sys.net.SocketAddress.SocketAddressTools)
enum SocketAddress {
	Ipv4(ip:Ipv4Addr, port:Int);
	Ipv6(ip:Ipv6Addr, port:Int, flowInfo:Int, scopeId:Int);
}

class SocketAddressTools {
	public static function getBytes(s:SocketAddress):haxe.io.Bytes {
		return switch s {
			case Ipv4(i, _): i.toBytes();
			case Ipv6(i, _, _, _): i.toBytes();
		}
	}

	public static function getPort(s:SocketAddress):Int {
		return switch s {
			case Ipv4(_, p): p;
			case Ipv6(_, p, _, _): p;
		}
	}

	public static function fromBytes(_:SocketAddress, bytes:Bytes, port:Int) {
		return switch bytes.length {
			case 4: Ipv4(Ipv4Addr.fromBytes(bytes), port);
			case 16: Ipv6(Ipv6Addr.fromBytes(bytes), port, 0, 0);
			case _: throw "invalid ip address";
		}
	}
}