package llvm;

@:integer(min = -128, max = 127)
@:coreType abstract Int8 {
	@:op(a >= b) function geq(b: llvm.Int8): Bool;
}