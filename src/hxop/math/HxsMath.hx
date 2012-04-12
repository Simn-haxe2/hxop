package hxop.math;
import hxs.Signal;
import hxs.Signal1;

class HxsMath
{
	@op("+=") static public function add0(lhs:Signal, rhs:Void->Void)
	{
		lhs.add(rhs);
		return lhs;
	}
	
	@op("+=") static public function add1<T>(lhs:Signal1<T>, rhs:T->Void)
	{
		lhs.add(rhs);
		return lhs;
	}	
}