import opover.IOverloadOperator;
import opover.math.Int32Math;
import haxe.Int32;
import haxe.unit.TestCase;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

class TestInt32 extends TestCase, implements IOverloadOperator<Int32Math>
{

	public function new() 
	{
		super();
	}
	
	function test1()
	{
		
		var i1 = Int32.ofInt(30);
		var i2 = Int32.ofInt(3000);

		assertTrue(i1 + i2 == 3030);
		assertTrue(i1 < i2);
		assertFalse(i1 > i2);
		assertTrue(i2 > i1);
		assertFalse(i2 < i1);
		
		assertTrue(i1 == 30);
		assertTrue(i2 == 3000);
		assertTrue(i1 != i2);
		
		assertTrue(i1 * i2 == 90000);
		assertTrue(i2 / i1 == 100);
		
		assertTrue(i2 % i1 == 0);
		assertTrue(i1 % i2 == 30);
		
		assertTrue(i1 << 1 == 60);
		assertTrue(i2 >> 1 == 1500);
		
		assertTrue( -i2 >> 1 == -1500);
		
		i1 <<= 2;
		assertTrue(Int32.ofInt(120) == i1);
		i1 >>= 2;
		assertTrue(i1 == 30);
		
		i1++;
		assertTrue(Int32.ofInt(31) == i1);
		--i1;
		assertTrue(i1 == 30);
		
		i1 += 10;
		assertTrue(i1 == 40);
		i1 -= 10;
		assertTrue(i1 == 30);
		
		assertTrue( -i1 == -30);
		
		assertTrue(i1 & i2 == 30 & 3000);
		assertTrue(i1 | i2 == 30 | 3000);
		assertTrue(i1 ^ i2 == 30 ^ 3000);
		
		var i3 = Int32.ofInt(6);
		var i4 = i3++;
		var i5 = ++i3;
		assertTrue(i3 == 8);
		assertTrue(i4 == 6);
		assertTrue(i5 == 8);
	}
	
}