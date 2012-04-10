package deep.macro.math;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import tink.core.types.Option;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

typedef UnopFunc = {
	operator: String,
	lhs:Type,
	field:Expr
};

typedef BinopFunc = {
	> UnopFunc,
	rhs: Type,
	commutative:Bool
}

typedef IdentDef = Array<{ name : String, type : Null<ComplexType>, expr : Null<Expr> }>; 


class OverloadOperator 
{
	static public var binops:Hash<Array<BinopFunc>> = new Hash();
	static public var unops:Hash<Array<UnopFunc>> = new Hash();
	
	@:macro static public function build():Array<Field>
	{
		return new MemberTransformer().build([getMathType, overload]);
	}
	
	static function overload(ctx:ClassBuildContext)
	{
		var env = [];
		
		if (ctx.cls.superClass != null)
			getMembers(ctx.cls.superClass.t.get(), env);
			
		for (field in ctx.members)
		{
			switch(field.kind)
			{
				case FVar(t, e):
					env.push( { name:field.name, type:t, expr:null } );
				case FProp(g, s, t, e):
					env.push( { name:field.name, type:t, expr:null } );
				case FFun(func):
					if (func.ret == null)
						continue;
					var tfArgs = [];
					for (arg in func.args)
						tfArgs.push(arg.type);
					env.push( { name:field.name, type:TFunction(tfArgs, func.ret), expr:null } );				
			}
		}

		for (member in ctx.members)
		{
			if (member.meta.exists("noOverload")) continue;
			switch(member.kind)
			{
				case FFun(func):
					var innerCtx = env.copy();
					for (arg in func.args)
						innerCtx.push( { name:arg.name, type:arg.type, expr: null } );					
					func.expr = transform(func.expr, innerCtx);
				case FVar(t, e):
					var innerCtx = env.copy();
					if (e != null)
						e.expr = transform(e, innerCtx).expr;
				default:
			}
		}
	}

	static function transform(expr:Expr, initCtx:IdentDef)
	{
		return expr.map(function(e, ctx)
		{
			return switch(e.expr)
			{
				case EBinop(op, lhs, rhs):
					var assign = switch(op)
					{
						case OpAssignOp(op2):
							op = op2;
							true;
						default:
							false;
					}
					lhs = transform(lhs, ctx);
					rhs = transform(rhs, ctx);
					switch(findBinop(op, lhs, rhs, assign, ctx, e.pos))
					{
						case None:
							e;
						case Some(opFunc):
							assign ? lhs.assign(opFunc) : opFunc;
					}
				case EUnop(op, pf, e): // TODO: postfix
					e = transform(e, ctx);
					switch(findUnop(op, e, ctx, e.pos))
					{
						case None:
							e;
						case Some(opFunc):
							(op == OpIncrement || op == OpDecrement) ? e.assign(opFunc) : opFunc;
					}
				default:
					e;
			}
		}, initCtx);
	}
	
	static function findBinop(op:Binop, lhs:Expr, rhs:Expr, isAssign:Bool, ctx:IdentDef, p, ?commutative = true)
	{
		var opString = tink.macro.tools.Printer.binoperator(op) + (isAssign ? "=" : "");

		if (!binops.exists(opString))
			return None;

		var t1 = switch(lhs.typeof(ctx))
		{
			case Success(t): Context.follow(t);
			case Failure(f): Context.error("Could not determine type: " +f + " | " +lhs.toString(), p);
		}
		var t2 = switch(rhs.typeof(ctx))
		{
			case Success(t): Context.follow(t);
			case Failure(f): Context.error("Could not determine type: " +f, p);
		}

		for (opFunc in binops.get(opString))
		{
			if (!commutative && !opFunc.commutative)
				continue;

			switch(t1.isSubTypeOf(opFunc.lhs))
			{
				case Failure(_): continue;
				default:
			}

			switch(t2.isSubTypeOf(opFunc.rhs))
			{
				case Failure(_): continue;
				default:
			}	

			return Some(opFunc.field.call([lhs, rhs]));
		}
		if (commutative)
			return findBinop(op, rhs, lhs, isAssign, ctx, p, false);
		else
			return None;
	}
	
	static function findUnop(op:Unop, lhs:Expr, ctx:IdentDef, p)
	{
		var opString = tink.macro.tools.Printer.unoperator(op);
		if (!unops.exists(opString))
			return None;
		
		var t1 = switch(lhs.typeof(ctx))
		{
			case Success(t): t;
			case Failure(f): Context.error("Could not determine type: " +f + " | " +lhs.toString(), p);
		}

		for (opFunc in unops.get(opString))
		{
			switch(t1.isSubTypeOf(opFunc.lhs))
			{
				case Failure(s): continue;
				default:
			}

			return Some(opFunc.field.call([lhs]));
		}
		return None;
	}	
	
	static function getMembers(cls:ClassType, ctx:IdentDef)
	{
		for (field in cls.fields.get())
			ctx.push( { name:field.name, type:null, expr: null } ); // TODO: this might be dirty
		if (cls.superClass != null)
			getMembers(cls.superClass.t.get(), ctx);
	}
	
	static function getMathType(ctx:ClassBuildContext)
	{
		var type = getDataType(ctx.cls).reduce();
		var fields = switch(type.getStatics())
		{
			case Success(fields):
				fields;
			case Failure(e):
				Context.error(e, Context.currentPos());
		}

		for (field in fields)
		{
			if (!field.meta.has("op"))
				continue;

			for (meta in field.meta.get().getValues("op"))
			{
				var operator = switch(meta[0].getString())
				{
					case Success(operator):
						operator;
					case Failure(_):
						Context.warning("Argument to @:op must be String.", meta[0].pos);
						continue;
				}

				var commutative = meta.length == 1 ? true : switch(meta[1].getIdent())
				{
					case Success(b):
						switch(b)
						{
							case "true": true;
							case "false": false;
							default:
								Context.warning("Second argument to @:op must be Bool.", meta[0].pos);
								true;
						}
					case Failure(f):
						Context.warning("Second argument to @:op must be Bool.", meta[0].pos);
						true;
				}
				
				var args = switch(field.type.reduce())
				{
					case TFun(args, ret):
						args;
					default:
						Context.warning("Only functions can be used as operators.", field.pos);
						continue;						
				};
				
				if (args.length > 2 || args.length == 0)
				{
					Context.warning("Only unary and binary operators are supported.", field.pos);
					continue;
				}
				
				if (args.length == 1)
				{
					if (!unops.exists(operator))
						unops.set(operator, []);
					unops.get(operator).push( {
						operator: operator,
						lhs: args[0].t,
						field: type.getID().resolve().field(field.name)
					});
				}
				else
				{
					if (commutative && args[0].t.isSubTypeOf(args[1].t).isSuccess())
					{
						//Context.warning("Found commutative definition, but types are equal.", field.pos);
						commutative = false;
					}

					if (!binops.exists(operator))
						binops.set(operator, []);
					binops.get(operator).push( {
						operator: operator,
						lhs: monofy(args[0].t),
						field: type.getID().resolve().field(field.name),
						rhs: monofy(args[1].t),
						commutative: commutative
					});
				}
			}
		}
	}
	
	static function monofy(t:Type)
	{
		return switch(t)
		{
			case TInst(cl, params):
				if (cl.get().kind == KTypeParameter)
					TPath({ name: "Dynamic", pack: [], params: [], sub: null }).toType().sure();
				else
				{
					var newParams = [];
					for (param in params)
						newParams.push(monofy(param));
					TInst(cl, newParams);
				}
			case TFun(args, ret):
				var newArgs = [];
				for (arg in args)
					newArgs.push( { name:arg.name, opt:arg.opt, t:monofy(arg.t) } );
				TFun(newArgs, monofy(ret));
			default:
				t;
		}
	}
	
	static function getDataType(cls:haxe.macro.Type.ClassType):haxe.macro.Type
	{
		for (i in cls.interfaces)
			if (i.t.get().name == "IOverloadOperator") return i.params[0];
		
		return Context.error("Must implement IOverloadOperator.", Context.currentPos());
	}
}