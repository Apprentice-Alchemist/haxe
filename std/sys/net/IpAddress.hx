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

import haxe.io.Bytes;

@:using(sys.net.IpAddress.IpAddressTools)
enum IpAddress {
	Ipv4(a:Ipv4Addr);
	Ipv6(a:Ipv6Addr);
}

private function u16toBE(i:Int):Int {
	return (i & 0xFF) << 8 | ((i & 0xFF00) >> 8);
}

abstract Ipv4Addr(Bytes) {
	/**
		The local host address, `127.0.0.1`.
	**/
	public static final LOCALHOST = new Ipv4Addr(127, 0, 0, 1);

	/**
		Create an Ipv4 address from four eight-bit octets.
	**/
	public function new(a:Int, b:Int, c:Int, d:Int) {
		this = haxe.io.Bytes.alloc(4);
		this.set(0, a);
		this.set(1, b);
		this.set(2, c);
		this.set(3, d);
	}

	/**
		These bytes are expected to contain a network order (big endian) representation of an ipv4 address.
	**/
	public static function fromBytes(b:Bytes):Ipv4Addr {
		if(b.length != 4) {
			throw "invalid ipv4 address";
		}
		return cast b.sub(0, 4);
	}

	public function toBytes():Bytes {
		return this.sub(0, 4);
	}

	// TODO: ipv6 conversion, utility methods to determine address type (global, broadcast, etc)
}

abstract Ipv6Addr(Bytes) {
	/**
		The local host address, `::1`.
	**/
	public static final LOCALHOST = new Ipv6Addr(0, 0, 0, 0, 0, 0, 0, 1);

	public function new(a:Int, b:Int, c:Int, d:Int, e:Int, f:Int, g:Int, h:Int) {
		#if python
		// ! is network order, H is unsigned short
		var bytes = python.lib.Struct.pack("!HHHHHHHH", a, b, c, d, e, f, g, h);
		this = haxe.io.Bytes.ofData(bytes);
		#elseif php
		var bytes = php.Global.pack("nnnnnnnn", a, b, c, d, e, f, g, h);
		this = haxe.io.Bytes.ofData(bytes);
		#else
		final littleEndian:Bool =
		#if java
		// it appears java is always big endian?
		false;
		#elseif cs
		cs.system.BitConverter.IsLittleEndian;
		#else
		// assume little-endian
		true;
		#end
		this = haxe.io.Bytes.alloc(16);
		if(littleEndian) {
			this.setUInt16(0, u16toBE(a));
			this.setUInt16(2, u16toBE(b));
			this.setUInt16(4, u16toBE(c));
			this.setUInt16(6, u16toBE(d));
			this.setUInt16(8, u16toBE(e));
			this.setUInt16(10, u16toBE(f));
			this.setUInt16(12, u16toBE(g));
			this.setUInt16(14, u16toBE(h));
		} else {
			this.setUInt16(0, a);
			this.setUInt16(2, b);
			this.setUInt16(4, c);
			this.setUInt16(6, d);
			this.setUInt16(8, e);
			this.setUInt16(10, f);
			this.setUInt16(12, g);
			this.setUInt16(14, h);
		}

		#end
	}

	/**
		These bytes are expected to contain a network order (big endian) representation of an ipv6 address.
	**/
	public static function fromBytes(b:Bytes):Ipv6Addr {
		if (b.length != 16) {
			throw "invalid ipv6 address";
		}
		return cast b.sub(0, 16);
	}

	public function toBytes():Bytes {
		return this.sub(0, 16);
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

	public static function toBytes(i:IpAddress):Bytes {
		return switch i {
			case Ipv4(a): a.toBytes();
			case Ipv6(a): a.toBytes();
		}

	}

	// TODO: this static extension doesn't actually work :(
	public static function fromBytes(_:Enum<IpAddress>, b:Bytes) {
		switch b.length {
			case 4: return Ipv4(Ipv4Addr.fromBytes(b));
			case 16: return Ipv6(Ipv6Addr.fromBytes(b));
			case _: throw "invalid ip address";
		}
	}
}
