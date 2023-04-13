package sys.process;

@:publicFields
@:structInit class ProcessOptions {
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

	var stdin:Stdio = Piped;
	var stdout:Stdio = Piped;
	var stderr:Stdio = Piped;

	/**
		The working directory for the process.
	**/
	var workingDirectory:Null<String> = null;
}
