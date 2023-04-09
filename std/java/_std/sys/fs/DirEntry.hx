package sys.fs;

class DirEntry {
	final p:Path;

	@:allow(sys.fs)
	function new(p:Path) {
		this.p = p;
	}

	public function path():Path {
		return this.p;
	}

	public function metadata():Metadata {
		return new Metadata(Fs.getPath(this.p));
	}
}
