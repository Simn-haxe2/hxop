import haxe.unit.TestRunner;

class TestMain
{
	 static public function main() 
	{
		var r = new TestRunner();
		r.add(new TestComplex());
		r.add(new TestQuaternion());
		#if !cpp
		r.add(new TestInt32());
		#end
		r.add(new TestInt64());
		r.add(new TestHxs());
		r.add(new TestReflection());
		r.run();
	}
}