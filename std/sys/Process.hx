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

package sys.io;

enum Stdio {
	Inherit;
	Null;
	Piped;
}

typedef ProcessOptions = {
	/**
		Arguments to be passed to the process.

		These arguments are not passed through the shell, and thus will not be escaped or subjected to command substitution.
	**/
	var args:Array<String> = [];
	// TODO: exact behaviour wrt existing env vars?
	/**
		Environment variables to pass to the process.
	**/
	var env:Map<String, String> = [];

	var stdin:Stdio = Inherit;
	var stdout:Stdio = Inherit;
	var stderr:Stdio = Inherit;

	/**
		The working directory for the process.
	**/
	var workingDirectory:Null<String> = null;
};

@:coreApi
extern class Process {
	static function spawn(cmd:String, opts:ProcessOptions = {}):Result<Process, Error>;


	/**
		Standard output. The output stream where a process writes its output data.
	**/
	var stdout(default, null):haxe.io.Input;

	/**
		Standard error. The output stream to output error messages or diagnostics.
	**/
	var stderr(default, null):haxe.io.Input;

	/**
		Standard input. The stream data going into a process.
	**/
	var stdin(default, null):haxe.io.Output;

	/**
		Return the process ID.
	**/
	function getPid():Int;

	/**
		Waits for the process to end, and returns the exit code.

		This function will close the stdin stream to avoid deadlocks.
	**/
	function wait():Result<Int, Error>;
	/**
		Checks wether the process has existed, and returns either null or the exitcode.

		This function will not close the stdin stream.
	**/
	function tryWait():Result<Null<Int>, Error>

	/**
		Close the process handle and release the associated resources.
		All `Process` fields should not be used after `close()` is called.
	**/
	function close():Void;

	/**
		Kill the process.
	**/
	function kill():Void;
}
