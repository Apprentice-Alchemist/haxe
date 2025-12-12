@:coreApi class Math {
	public static var PI(default, null):Float = 3.14159265358979323846264338327950288;
	public static var NaN(default, null):Float = 0.0 / 0.0;
	public static var NEGATIVE_INFINITY(default, null):Float = -1.0 / 0.0;
	public static var POSITIVE_INFINITY(default, null):Float = 1.0 / 0.0;

	public extern static function abs(v:Float):Float;

	public extern static function min(a:Float, b:Float):Float;

	public extern static function max(a:Float, b:Float):Float;

	public extern static function sin(v:Float):Float;

	public extern static function cos(v:Float):Float;

	public extern static function atan2(y:Float, x:Float):Float;

	public extern static function tan(v:Float):Float;

	public extern static function exp(v:Float):Float;

	public extern static function log(v:Float):Float;

	public extern static function sqrt(v:Float):Float;

	public extern static function round(v:Float):Int;

	public extern static function floor(v:Float):Int;

	public extern static function ceil(v:Float):Int;

	public extern static function atan(v:Float):Float;

	public inline extern static function fround(v:Float):Float {
		return ffloor(v + 0.5);
	}

	public extern static function ffloor(v:Float):Float;

	public extern static function fceil(v:Float):Float;

	public extern static function asin(v:Float):Float;

	public extern static function acos(v:Float):Float;

	public extern static function pow(v:Float, exp:Float):Float;

	public extern static function random():Float;

	public extern static function isFinite(f:Float):Bool;

	public extern static function isNaN(f:Float):Bool;
}
