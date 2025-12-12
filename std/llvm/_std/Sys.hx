import haxe.io.Encoding;
import llvm.Ptr;
import haxe.io.Error;
import haxe.io.Bytes;
import llvm.Libc;

private class FdInput extends haxe.io.Input {
	private var fd:Int;

	public inline function new(fd:Int) {
		this.fd = fd;
	}

	inline override function readByte():Int {
		var b:llvm.UInt8 = cast 0;
		if (Libc.read(fd, Ptr.ref(b), 1) == 0i64) {
			throw new haxe.io.Eof();
		}
		return cast b;
	}

	inline override function readBytes(s:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > s.length)
			throw Error.OutsideBounds;
		var d = s.getData();
		var read = Libc.read(fd, d.bytes.offset(pos), cast len);
		if (read == 0i64) {
			throw new haxe.io.Eof();
		}
		return cast read;
	}
}

private class FdOutput extends haxe.io.Output {
	private var fd:Int;

	public inline function new(fd:Int) {
		this.fd = fd;
	}

	override function writeByte(c:Int) {
		var b:llvm.UInt8 = cast c;
		Libc.write(fd, Ptr.ref(b), 1);
	}

	public override function writeBytes(s:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > s.length)
			throw Error.OutsideBounds;
		var d = s.getData();
		var written = Libc.write(fd, d.bytes.offset(pos), cast len);
		return cast written;
	}

	public override function writeString(s:String, ?encoding:Encoding) {
		@:privateAccess Libc.write(fd, s.data, cast s.length);
	}
}

@:native("__haxe_init_args")
@:keep
private function init(argc: Int, argv: llvm.Ptr<llvm.Ptr<llvm.UInt8>>) {
	Sys.argc = argc;
	Sys.argv = argv;
}

@:require(sys)
class Sys {
	@:allow(Sys)
	private static var argc: Int = 0;
	@:allow(Sys)
	private static var argv: llvm.Ptr<llvm.Ptr<llvm.UInt8>> = null;

	public static function print(v:Dynamic):Void {
		var s:String = Std.string(v);
		@:privateAccess Libc.write(Libc.STDOUT_FILENO, s.data, s.length);
	}

	public static function println(v:Dynamic):Void {
		print(v);
		print("\n");
	}

	public static function args():Array<String> {
		final arr = new Array();
		for (i in 0...argc) {
			arr.push(@:privateAccess String.fromPtrCopied(argv[i], cast Libc.strlen(argv[i])));
		}
		return arr;
	}

	public static function getEnv(s:String):Null<String> {
		var r = Libc.getenv(@:privateAccess s.data);
		if (r == null) {
			return null;
		}
		return @:privateAccess String.fromPtrCopied(r, cast Libc.strlen(r));
	}

	public static function putEnv(s:String, v:Null<String>):Void {}

	public static function environment():Map<String, String> {
		return [];
	}

	public static function sleep(seconds:Float):Void {
		var secs: llvm.Int64 = cast seconds;
		var nanosecs: llvm.Int64 = (cast ((seconds - (cast secs: Float)) * 1e9): llvm.Int64);
		var ts: Timespec = {
			tv_sec: secs,
			tv_nsec: nanosecs,
		};
		Libc.nanosleep(llvm.Ptr.ref(ts));
	}

	public static function setTimeLocale(loc:String):Bool {
		return false;
	}

	public static function getCwd():String {
		return "/";
	}

	public static function setCwd(s:String):Void {}

	public static function systemName():String {
		return "Unknown";
	}

	public static function command(cmd:String, ?args:Array<String>):Int {
		return 0;
	}

	public static function exit(code:Int):Void {
		Libc.exit(code);
	}

	public static function time():Float {
		var ts: Timespec = null;
		Libc.clock_gettime(CLOCK_MONOTONIC, Ptr.ref(ts));
		return (cast ts.tv_sec: Float) + (cast ts.tv_nsec: Float) / 1.0e9;
	}

	public static function cpuTime():Float {
		var ts:Timespec = null;
		Libc.clock_gettime(CLOCK_THREAD_CPUTIME_ID, Ptr.ref(ts));
		return (cast ts.tv_sec : Float) + (cast ts.tv_nsec : Float) / 1.0e9;
	}

	@:deprecated("Use programPath instead") public static function executablePath():String {
		return programPath();
	}

	public static function programPath():String {
		return "";
	}

	public static function getChar(echo:Bool):Int {
		// TODO: raw mode?
		var c = stdin().readByte();
		if (echo) {
			stdout().writeByte(c);
		}
		return c;
	}

	public static function stdin():haxe.io.Input {
		return new FdInput(Libc.STDIN_FILENO);
	}

	public static function stdout():haxe.io.Output {
		return new FdOutput(Libc.STDOUT_FILENO);
	}

	public static function stderr():haxe.io.Output {
		return new FdOutput(Libc.STDERR_FILENO);
	}
}
