package sys.net;

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
}