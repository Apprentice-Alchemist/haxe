package llvm;

@:llvm.struct
@:structInit
@:publicFields
final class Timespec {
	var tv_sec:llvm.Int64;
	var tv_nsec:llvm.Int64;
}

enum abstract ClockId(Int) {
	#if true
	/* Identifier for system-wide realtime clock.  */
	var CLOCK_REALTIME = 0;
	/* Monotonic system-wide clock.  */
	var CLOCK_MONOTONIC = 1;
	/* High-resolution timer from the CPU.  */
	var CLOCK_PROCESS_CPUTIME_ID = 2;
	/* Thread-specific CPU-time clock.  */
	var CLOCK_THREAD_CPUTIME_ID = 3;
	/* Monotonic system-wide clock, not adjusted for frequency scaling.  */
	var CLOCK_MONOTONIC_RAW = 4;
	/* Identifier for system-wide realtime clock, updated only on ticks.  */
	var CLOCK_REALTIME_COARSE = 5;
	/* Monotonic system-wide clock, updated only on ticks.  */
	var CLOCK_MONOTONIC_COARSE = 6;
	/* Monotonic system-wide clock that includes time spent in suspension.  */
	var CLOCK_BOOTTIME = 7;
	/* Like CLOCK_REALTIME but also wakes suspended system.  */
	var CLOCK_REALTIME_ALARM = 8;
	/* Like CLOCK_BOOTTIME but also wakes suspended system.  */
	var CLOCK_BOOTTIME_ALARM = 9;
	/* Like CLOCK_REALTIME but in International Atomic Time.  */
	var CLOCK_TAI = 11;
	#elseif macos
	var CLOCK_REALTIME = 0;
	var CLOCK_MONOTONIC = 6;
	var CLOCK_MONOTONIC_RAW = 4;
	var CLOCK_MONOTONIC_RAW_APPROX = 5;
	var CLOCK_UPTIME_RAW = 8;
	var CLOCK_UPTIME_RAW_APPROX = 9;
	var CLOCK_PROCESS_CPUTIME_ID = 12;
	var CLOCK_THREAD_CPUTIME_ID = 16;
	#end
}

extern class Libc {
	public static inline final STDIN_FILENO:Int = 0;
	public static inline final STDOUT_FILENO:Int = 1;
	public static inline final STDERR_FILENO:Int = 2;

	@:native("getenv")
	public static function getenv(name: llvm.Ptr<llvm.UInt8>): llvm.Ptr<UInt8>;

	@:native("puts")
	public static extern function puts(data:llvm.Ptr<llvm.UInt8>):Int;

	@:native("read")
	public static extern function read(fd:Int, buf:llvm.Ptr<llvm.UInt8>, count:llvm.UInt64):llvm.Int64;

	@:native("write")
	public static extern function write(fd:Int, buf:llvm.Ptr<llvm.UInt8>, count:llvm.UInt64):llvm.Int64;

	@:native("exit")
	@:llvm.noreturn
	public static extern function exit(data:Int):Void;

	@:native("clock_gettime")
	public static function clock_gettime(id:ClockId, tp:llvm.Ptr<Timespec>):Int;

	@:native("strlen")
	public static function strlen(ptr: llvm.Ptr<UInt8>): Int64;

	@:native("nanosleep")
	public static function nanosleep(duration: llvm.Ptr<Timespec>, rem: Null<llvm.Ptr<Timespec>> = null): Int;

	@:native("readlink")
	public static function readlink(path: llvm.Ptr<UInt8>, buf: llvm.Ptr<UInt8>, bufsiz: llvm.UInt64): llvm.Int64;
}
