Haxe operator overloading
=============

This library enables overloading of unary and binary haxe operators. It can be used to allow mathematical operations on complex data structures, or give a whole new meaning to the array access operator []. 

Usage
-------

Working with this library consists of two steps:

1. Create a class `YourOperatorClass` defining the operators and
2. add implements `IOverloadOperator<YourOperatorClass>` where you want to use it

Bundled with this library are a few operator-defining classes, which include

* `Int32` and `Int64`: use haxe.Int32 and haxe.Int64 as if they were normal Ints
* `Point`: support for nme's Point data structure
* `Complex`: use concise infix notation on complex numbers
* `Quaternion`: if you want to rotate things in funny ways, this math is for you
* `Reflection`: translate o["field"] to matching Reflect calls

Defining and using operators
-------

You create your own operators by defining a class with static fields annotated by @op("operator"). As a non-mathematical example, assume that you have a class Signal that dispatches events to registered listeners. You like C#'s += operator, so you want to mimic this in haxe:

* SignalMath.hx

```

class SignalMath
{
	@op("+=") static public function add(lhs:Signal, rhs:Void->Void)
	{
		lhs.add(rhs);
		return lhs;
	}
}

```

With just that you can start using your += operator like so:

* Main.hx

```

class Main implements opover.IOverloadOperator<SignalMath>
{
	static public function main()
	{
		var signal = new Signal();
		s1 += function()
		{
			trace("I was called today.");
		}
		s1.dispatch();
	}
}

```

Remarks
-------

* `@op` accepts a second argument of type `Bool`, which defaults to false and defines if an operator is commutative. For example, if you define an operator + that adds `Float` and `Point`, you likely want to allow this on both `(Float + Point)` and `(Point + Float)`, so you would set this argument to true. Note that this only makes sense if your operands are of different types.
* If you have a situation where you want to disable overloading for a specific function of a class implementing `IOperatorOverload`, you can annotate it with `@noOverload`.
* Usually, assignment operators such as += and *= generate an assignment of their return value to the left hand side argument. If you wish to disable it for certain operators, you can add the `@noAssign` metadata.