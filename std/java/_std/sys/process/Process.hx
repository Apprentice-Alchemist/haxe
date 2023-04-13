package sys.process;

import haxe.io.BytesBuffer;
import java.io.NativeOutput;
import java.io.NativeInput;
import java.io.File;
import haxe.io.Bytes;
import java.lang.ProcessBuilder;

using StringTools;

@:coreApi
class Process {
	public static function spawn(cmd:String, ?opts:ProcessOptions):Process {
		// a nice hack to be able to support Java < 9
		static final NUL_FILE = new File((java.lang.System.getProperty("os.name").startsWith("Windows") ? "NUL" : "/dev/null"));
		opts ??= {};
		var a = [cmd].concat(opts.args);
		var builder = new ProcessBuilder(...a);
		if (opts.workingDirectory != null) {
			builder.directory(new File(opts.workingDirectory));
		}
		var envMap = builder.environment();
		for (key => value in opts.env) {
			envMap.put(key, value);
		}
		switch opts.stdin {
			case Inherit:
				builder.redirectInput((cast INHERIT : ProcessBuilder_Redirect));
			case Null:
				builder.redirectInput(NUL_FILE);
			case Piped:
				builder.redirectInput((cast PIPE : ProcessBuilder_Redirect));
		}
		switch opts.stdout {
			case Inherit:
				builder.redirectOutput((cast INHERIT : ProcessBuilder_Redirect));
			case Null:
				builder.redirectOutput(NUL_FILE);
			case Piped:
				builder.redirectOutput((cast PIPE : ProcessBuilder_Redirect));
		}
		switch opts.stderr {
			case Inherit:
				builder.redirectError((cast INHERIT : ProcessBuilder_Redirect));
			case Null:
				builder.redirectError(NUL_FILE);
			case Piped:
				builder.redirectError((cast PIPE : ProcessBuilder_Redirect));
		}
		return new Process(builder.start());
	}

	private final process:java.lang.Process;

	private function new(process:java.lang.Process) {
		this.process = process;
		this.stdin = new NativeOutput(process.getOutputStream());
		this.stdout = new NativeInput(process.getInputStream());
		this.stderr = new NativeInput(process.getErrorStream());
	}

	public var stdout(default, null):Null<haxe.io.Input>;

	public var stderr(default, null):Null<haxe.io.Input>;

	public var stdin(default, null):Null<haxe.io.Output>;

	public function getPid():Int {
		// TODO: figure out how to do this, see also https://github.com/HaxeFoundation/haxe/issues/10938
		return 0;
	}

	public function wait():Int {
		return process.waitFor();
	}

	public function tryWait():Null<Int> {
		return try process.exitValue() catch (e) null;
	}

	public function waitWithOutput():{code:Int, stdout:Bytes, stderr:Bytes} {
		var stdoutBuf = new BytesBuffer();
		var stderrBuf = new BytesBuffer();

		stdin.close();

		var code = null;

		while (code == null) {
			stdoutBuf.add(stdout.readAll());
			stderrBuf.add(stderr.readAll());
			code = tryWait();
		}

		return {code: code, stdout: stdoutBuf.getBytes(), stderr: stderrBuf.getBytes()};
	}

	public function close():Void {
		stdin.close();
		stdout.close();
		stderr.close();
		process.destroy();
	}

	public function kill():Void {
		process.destroy();
	}
}
