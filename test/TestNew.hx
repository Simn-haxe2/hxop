package ;
import haxe.unit.TestCase;
import hxop.Overload;

class MyClass
{
	static public var numNewCalled = 0;
	
	public var a:String;
	public var b:Int;
	
	public function new(a:String, b:Int)
	{
		numNewCalled++;
		this.a = a;
		this.b = b;
	}
	
	static var objects = new Array<MyClass>();
	@op("new") static public function create(a:String, b:Int):MyClass
	{
		if (objects.length == 1) return objects[0];
		
		var c = new MyClass(a, b);
		objects.push(c);
		return c;
	}
	
	@op("new") static public function createList<T>(a:Array<T>):List<T>
	{
		var l = new List();
		for (el in a)
			l.add(el);
		return l;
	}
}

#if !macro
class TestNew extends TestCase, implements Overload<MyClass>
{
	public function testBasic()
	{
		var c = new MyClass("foo", 13);
		assertEquals("foo", c.a);
		assertEquals(13, c.b);
		assertEquals(1, MyClass.numNewCalled);
		var c2 = new MyClass("bar", 26);
		assertEquals("foo", c2.a);
		assertEquals(13, c2.b);
		assertEquals(1, MyClass.numNewCalled);
		
		var list = new List([1, 2, 3]);
		assertEquals(1, list.pop());
		assertEquals(2, list.pop());
		assertEquals(3, list.pop());
		
		var l = new List();
	}
}
#end