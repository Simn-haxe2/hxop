import hxop.Overload;
import hxop.ops.HxsMath;
import haxe.unit.TestCase;
import hxs.Signal;
import hxs.Signal1;
import hxs.Signal2;

class TestHxs extends TestCase, implements Overload<HxsMath>
{
	public function testArg0()
	{
		var s1 = new Signal();
		s1 += function()
			assertEquals(true, true);
		s1.dispatch();
	}
	
	public function testArg1()
	{
		var s1 = new Signal1<String>();
		s1 += function(s:String)
			assertEquals("foo", s);
		s1.dispatch("foo");
	}
	
	public function testArg2()
	{
		var s1 = new Signal2();
		s1 += function(s:String, i:Int)
		{
			assertEquals("foo", s);
			assertEquals(5, i);
		};
		s1.dispatch("foo", 5);
	}	
}