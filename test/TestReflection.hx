import opover.IOverloadOperator;
import opover.math.ReflectionMath;
import haxe.unit.TestCase;

class TestReflection extends TestCase, implements IOverloadOperator<ReflectionMath>
{
	public function testBasic()
	{
		var o = { v:"foo", w:6, q:19 };
		assertEquals("foo", o["v"]);		
		assertEquals(6, o["w"]);
		o["v"] = "bar";
		assertEquals("bar", o["v"]);
		assertEquals(19, Reflect.field(o, "q"));
		assertEquals("bar", Reflect.field(o, "v"));
		assertEquals(6, Reflect.field(o, "w"));
		o["w"] = o["q"] = 133;
		assertEquals(133, Reflect.field(o, "q"));
		assertEquals(133, Reflect.field(o, "w"));
	}
	
	public function testAdvanced()
	{
		var o = { i: 9, j: 5 }
		o["i"] += 1;
		assertEquals(10, o.i);
		o["j"] = o["i"] += 1;
		assertEquals(11, o.i);
		assertEquals(11, o.j);
		assertEquals(22, o["i"] + o["i"]);
		
		assertEquals(11, function() { [0];  return o; } ()["j"]);
		assertEquals("bar", ( { [0]; { foo:"bar" }; } )["foo"]);
	}
	
	public function testOperators()
	{
		var o = { i: 9 }
		o["i"] -= 2;
		assertEquals(7, o.i);
		o["i"] *= 4;
		assertEquals(28, o.i);
		o["i"] /= 14;
		assertEquals(2, o.i);		
	}

	public function testLValueCases()
	{
		var o = { i: 7 };
		( { o; } )["i"] += 2;
		assertEquals(9, o.i);
		function() { return o; } ()["i"] += 2;
		assertEquals(11, o.i);
		function() { return o; } ()["i"] = 2;
		assertEquals(2, o.i);		
	}
	
	public function testUnary()
	{
		var o = { i:9 };
		assertEquals(9, o["i"]++);
		assertEquals(10, o.i);
		assertEquals(11, ++o["i"]);
		assertEquals(11, o.i);
		assertEquals(11, o["i"]--);
		assertEquals(10, o.i);
		assertEquals(9, --o["i"]);
		assertEquals(9, o.i);
	}
}