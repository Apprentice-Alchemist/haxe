/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package sys.net;

@:using(sys.net.IpAddress.IpAddressTools)
enum IpAddress {
	Ipv4(a:Ipv4Addr);
	Ipv6(a:Ipv6Addr);
}

class Ipv4Addr {
	/**
		The local host address, `127.0.0.1`.
	**/
	public static final LOCALHOST = new Ipv4Addr(127, 0, 0, 1);

	/**
		The adress as an integer.
	**/
	public var addr(default, null):Int;

	/**
		Create an Ipv4 address from four eight-byte octets.
	**/
	public function new(a:Int, b:Int, c:Int, d:Int) {
		this.addr = a << 24 | b << 16 | c << 8 | d;
	}

	// TODO: ipv6 conversion, utility methods to determine address type (global, broadcast, etc)
}

class Ipv6Addr {
	/**
		The local host address, `::1`.
	**/
	public static final LOCALHOST = new Ipv6Addr(0, 0, 0, 0, 0, 0, 0, 1);

	var a:Int;
	var b:Int;
	var c:Int;
	var d:Int;
	var e:Int;
	var f:Int;
	var g:Int;
	var h:Int;

	public function new(a:Int, b:Int, c:Int, d:Int, e:Int, f:Int, g:Int, h:Int) {
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.e = e;
		this.f = f;
		this.g = g;
		this.h = h;
	}

	// TODO: utility methods, etc
}

class IpAddressTools {
	public static function toSocketAddress(i:IpAddress, port:Int):SocketAddress {
		return switch i {
			case Ipv4(a): Ipv4(a, port);
			case Ipv6(a): Ipv6(a, port, 0, 0);
		}
	}
}