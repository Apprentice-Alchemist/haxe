package sys.fs;

import haxe.io.Bytes;

abstract Path(Bytes) from Bytes {
	@:from static function fromString(s:String):Path {
		return haxe.io.Bytes.ofString(s);
	}

	public function toString() {
		return this.toString();
	}
}
