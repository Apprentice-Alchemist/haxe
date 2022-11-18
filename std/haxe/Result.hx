package haxe;

@:mustUse("Result should not be ignored.") // TODO: implement in compiler
@:using(haxe.Result.ResultTools)
enum Result<V, E> {
	Ok(v:V);
	Err(e:E);
}

class ResultTools {
	public static function isOk<V, E>(r:Result<V, E>):Bool {
		return r.match(Ok(_));
	}

	public static function isErr<V, E>(r:Result<V, E>):Bool {
		return r.match(Err(_));
	}

	public static function expectOk<V, E>(r:Result<V, E>):V {
		return switch r {
			case Ok(v): v;
			case Err(e): throw 'Expected Ok, found Err($e)';
		}
	}

	public static function expectErr<V, E>(r:Result<V, E>):E {
		return switch r {
			case Ok(v): throw 'Expected error, found Ok($v)';
			case Err(e): e;
		}
	}
}
