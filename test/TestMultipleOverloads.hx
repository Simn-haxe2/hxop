package ;
import haxe.unit.TestCase;
import hxop.ops.Quaternion;
import hxop.ops.QuaternionOps;
import hxop.ops.ReflectionOps;
import hxop.Overload;

class TestMultipleOverloads extends TestCase, implements Overload<ReflectionOps>, implements Overload<QuaternionOps>
{
	public function test1()
	{
		var o = { val1: new Quaternion(1, 2, 3, 4), val2: new Quaternion(1, 2, 3, 4) };
		var val = cast(o["val1"], Quaternion) + cast(o["val2"], Quaternion);
		assertTrue(val == new Quaternion(2, 4, 6, 8));
	}
}