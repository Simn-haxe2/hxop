package opover.math;

typedef ReflectionValue = Dynamic;
typedef ReflectionFunc = ?ReflectionValue -> ReflectionValue;

class ReflectionMath
{
	static inline function access(base:Dynamic, access:String, ?value:Dynamic)
	{
		if (value == null)
			return Reflect.field(base, access);
		else
		{
			Reflect.setField(base, access, value);
			return value;
		}
	}
	
	@op("[]") static public inline function read(base:Dynamic, access:String):Dynamic
	{
		return Reflect.field(base, access);
	}
	
	@op("[]=") @noAssign static public function write(base:Dynamic, access:String):ReflectionFunc
	{
		return callback(ReflectionMath.access, base, access);
	}
		
	@op("=") static public inline function assign(lhs:ReflectionValue, rhs:Dynamic):Dynamic
	{
		return lhs( rhs );
	}
	
	@op("+=") @noAssign static public inline function assignAdd(lhs:ReflectionFunc, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() + rhs );
	}
	
	@op("-=") @noAssign static public inline function assignSub(lhs:ReflectionFunc, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() - rhs );
	}
	
	@op("*=") @noAssign static public inline function assignMul(lhs:ReflectionFunc, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() * rhs );
	}
	
	@op("/=") @noAssign static public inline function assignDiv(lhs:ReflectionFunc, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() / rhs );
	}
	
	@op("++") @noAssign static public inline function inc(lhs:ReflectionFunc):Dynamic
	{
		return lhs(lhs() + 1);
	}
	
	@op("--") @noAssign static public inline function dec(lhs:ReflectionFunc):Dynamic
	{
		return lhs(lhs() - 1);
	}	
}