package sys.fs;


@:coreApi
class Permissions {
	@:isVar
	public var readonly(get, set):Bool;

	@:allow(sys.fs)
	function new(readonly:Bool) {
		this.readonly = readonly;
	}

	function get_readonly():Bool {
		return this.readonly;
	}

	function set_readonly(v:Bool):Bool {
		return this.readonly = v;
	}
}
