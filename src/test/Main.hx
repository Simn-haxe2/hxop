package test;

import haxe.unit.TestRunner;

class Main
{
	 static public function main() 
	{
		var r = new TestRunner();
		r.add(new OverloadTestComplex());
		r.add(new OverloadTestQuaternion());
		r.add(new OverloadTestInt32());
		r.add(new OverloadTestInt64());
		r.add(new OverloadTestHxs());
		r.run();
	}
}