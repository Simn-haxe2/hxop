package ;
import haxe.unit.TestCase;

class TestAutoBuild extends TestCase
{
	public function testAutoBuilding()
	{
		assertEquals("hel", "hello" - 2);
		assertEquals("foofoofoo", "foo" * 3);
	}
}