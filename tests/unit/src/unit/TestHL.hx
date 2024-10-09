package unit;

import hl.Ref;

class TestHL extends Test {
	private function refTestAssign(i:hl.Ref<Int>):Void {
		i.set(2);
	}

	public function testRef() {
		var i = 10;
		refTestAssign(i);
		eq(i, 2);
	}

	function take<T>(o:T) {}

	public function testObjFieldRef() {
		var o = {foo: 10};
		take(o); // prevent the compiler from optimizing o into a local variable
		var ref = hl.Ref.fieldRef(o.foo);
		ref.set(5);
		eq(o.foo, 5);
		o.foo = 4;
		eq(ref.get(), 4);
	}

	public function testClassFieldRef() {
		var c:Foo = {foo: 10};
		var ref = hl.Ref.fieldRef(c.foo);
		ref.set(5);
		eq(c.foo, 5);
		c.foo = 4;
		eq(ref.get(), 4);
	}

	public function testInterfaceFieldRef() {
		var i:IFoo = ({foo: 10} : Foo);
		var ref = hl.Ref.fieldRef(i.foo);
		ref.set(5);
		eq(i.foo, 5);
		i.foo = 4;
		eq(ref.get(), 4);
	}

	// public function testDynamicFieldRef() {
	// 	var d:Dynamic = ({foo: 10}:Foo);
	// 	var ref:Ref<Int> = hl.Ref.fieldRef(d.foo);
	// 	ref.set(5);
	// 	eq(d.foo, 5);
	// 	d.foo = 4;
	// 	eq(ref.get(), 4);
	// }

	private function testGenericFieldRef() {
		var obj = {foo: 10};
		bar(obj);
		eq(obj.foo, 3);
		foo(obj, 2);
		eq(obj.foo, 2);
	}
}

@:generic function bar<T:{foo:Int}>(obj:T) {
	var ref = hl.Ref.fieldRef(obj.foo);
	ref.set(3);
}

@:generic function foo<T>(obj:{foo:T}, val:T) {
	var ref = hl.Ref.fieldRef(obj.foo);
	ref.set(val);
}

private interface IFoo {
	var foo:Int;
}

@:structInit
private class Foo implements IFoo {
	public var foo:Int;
}
