final buffer = new haxe.ds.VecDeque<Int>();

buffer.pushBack(1);
buffer.pushBack(2);
buffer.pushBack(3);
buffer.pushBack(4);

1 == buffer.popFront();
2 == buffer.popFront();
3 == buffer.popFront();
buffer.pushBack(5);
buffer.pushBack(6);
buffer.pushBack(7);
buffer.pushBack(8);
4 == buffer.popFront();
5 == buffer.popFront();

final buffer = new haxe.ds.VecDeque<Int>();

buffer.pushBack(1);
buffer.pushBack(2);
buffer.pushBack(3);
buffer.pushBack(4);

buffer.removeAt(1);
buffer.pushBack(5);
buffer.removeAt(buffer.length - 1);

1 == buffer.popFront();
buffer.pushFront(1);
buffer.pushFront(-1);
buffer.pushFront(-2);
trace(buffer, @:privateAccess buffer.storage);
0 == buffer.indexOf(-2);
1 == buffer.indexOf(-1);

buffer.popFront();
buffer.popFront();
buffer.pushBack(6);
6 == buffer.popBack();
buffer.pushBack(6);
buffer.pushBack(7);
buffer.pushBack(8);
buffer.pushBack(9);
buffer.pushBack(10);
10 == buffer.popBack();

0 == buffer.indexOf(1);
1 == buffer.indexOf(3);
6 == buffer.indexOf(9);


1 == buffer.popFront();
3 == buffer.popFront();
4 == buffer.popFront();
6 == buffer.popFront();
7 == buffer.popFront();
8 == buffer.popFront();
9 == buffer.popFront();
