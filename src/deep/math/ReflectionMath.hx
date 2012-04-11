package deep.math;

typedef ReflectionValue<T> = Dynamic;

class ReflectionMath
{
	static function _access(base:Dynamic, access:String, ?value:Dynamic)
	{
		if (value == null)
			return Reflect.field(base, access);
		else
			Reflect.setField(base, access, value);
			return value;
	}
	
	@op("[]") static public function read(base:Dynamic, access:String):ReflectionValue<Dynamic>
	{
		return Reflect.field(base, access);
	}
	
	@op("[]=") @noAssign static public function write(base:Dynamic, access:String):ReflectionValue<Dynamic>
	{
		return callback(_access, base, access);
	}
		
	@op("=") static public inline function assign(lhs:ReflectionValue<Dynamic>, rhs:Dynamic):Dynamic
	{
		return lhs( rhs );
	}
	
	@op("+=") @noAssign static public inline function assignAdd(lhs:ReflectionValue<Dynamic>, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() + rhs );
	}
	
	@op("-=") @noAssign static public inline function assignSub(lhs:ReflectionValue<Dynamic>, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() - rhs );
	}
	
	@op("*=") @noAssign static public inline function assignMul(lhs:ReflectionValue<Dynamic>, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() * rhs );
	}
	
	@op("/=") @noAssign static public inline function assignDiv(lhs:ReflectionValue<Dynamic>, rhs:Dynamic):Dynamic
	{
		return lhs( lhs() / rhs );
	}	
}