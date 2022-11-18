package sys.net;

import sys.net.IpAddress;

enum SocketAddress {
	Ipv4(ip:Ipv4Addr, port:Int);
	Ipv6(ip:Ipv6Addr, port:Int, flowInfo:Int, scopeId:Int);
}