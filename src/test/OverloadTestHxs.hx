package test;

import deep.macro.math.IOverloadOperator;
import deep.math.HxsMath;
import haxe.unit.TestCase;
import hxs.Signal;
import hxs.Signal1;

class OverloadTestHxs extends TestCase, implements IOverloadOperator<HxsMath>
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
}