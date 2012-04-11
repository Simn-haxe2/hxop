package opover.engine;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import tink.core.types.Option;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

enum Binop
{
	Binop(op:haxe.macro.Expr.Binop);
	OpArray;
}

typedef UnopFunc = {
	operator: String,
	lhs: Type,
	field: Expr,
	noAssign: Bool
};

typedef BinopFunc = {
	> UnopFunc,
	rhs: Type,
	commutative: Bool
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

	static function transform(expr:Expr, initCtx:IdentDef, lValue = false)
	{
		return expr.map(function(e, ctx)
		{
			var e = switch(e.expr)
			{
				case EArray(lhs, rhs):
					lhs = transform(lhs, ctx, lValue);
					rhs = transform(rhs, ctx);
					switch(findBinop(OpArray, lhs, rhs, lValue, ctx, e.pos))
					{
						case None:
							e;
						case Some(opFunc):
							lValue && !opFunc.noAssign ? lhs.assign(opFunc.func) : opFunc.func;
					}					
				case EBinop(op, lhs, rhs):
					var info = switch(op)
					{
						case OpAssignOp(op2):
							{ op:op2, assign: true };
						default:
							{ op:op, assign: false };
					}
					lhs = transform(lhs, ctx, info.assign || info.op == OpAssign);
					rhs = transform(rhs, ctx);
					switch(findBinop(Binop(info.op), lhs, rhs, info.assign, ctx, e.pos))
					{
						case None:
							e;
						case Some(opFunc):
							info.assign && !opFunc.noAssign ? lhs.assign(opFunc.func) : opFunc.func;
					}
				case EUnop(op, pf, e): // TODO: postfix
					var assign = (op == OpIncrement || op == OpDecrement);
					e = transform(e, ctx, assign);
					switch(findUnop(op, e, ctx, e.pos))
					{
						case None:
							e;
						case Some(opFunc):
							assign && !opFunc.noAssign ? e.assign(opFunc.func) : opFunc.func;
					}
				default:
					e;
			};
			lValue = false;
			return e;
		}, initCtx);
	}
	
	static function findBinop(op:Binop, lhs:Expr, rhs:Expr, isAssign:Bool, ctx:IdentDef, p, ?commutative = true)
	{
		var opString = (switch(op)
		{
			case Binop(op): tink.macro.tools.Printer.binoperator(op);
			case OpArray: "[]";
		}) + (isAssign ? "=" : "");

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
			if (t1.isDynamic() && !opFunc.lhs.isDynamic()) continue;
			
			switch(t2.isSubTypeOf(opFunc.rhs))
			{
				case Failure(_): continue;
				default:
			}	
			if (t2.isDynamic() && !opFunc.rhs.isDynamic()) continue;

			return Some({noAssign:opFunc.noAssign, func:opFunc.field.call([lhs, rhs])});
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
			if (t1.isDynamic() && !opFunc.lhs.isDynamic()) continue;
			return Some({noAssign:opFunc.noAssign, func:opFunc.field.call([lhs]) });
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

				var commutative = meta.length == 1 ? false : switch(meta[1].getIdent())
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
						field: type.getID().resolve().field(field.name),
						noAssign: field.meta.has("noAssign")
					});
				}
				else
				{
					if (commutative && args[0].t.isSubTypeOf(args[1].t).isSuccess())
					{
						Context.warning("Found commutative definition, but types are equal.", field.pos);
						commutative = false;
					}

					if (!binops.exists(operator))
						binops.set(operator, []);
					binops.get(operator).push( {
						operator: operator,
						lhs: monofy(args[0].t),
						field: type.getID().resolve().field(field.name),
						rhs: monofy(args[1].t),
						commutative: commutative,
						noAssign: field.meta.has("noAssign")
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