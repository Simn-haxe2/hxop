package opover.engine;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

import tink.core.types.Option;

import opover.engine.Types;

using tink.macro.tools.TypeTools;
using tink.macro.tools.ExprTools;

class OperatorManager 
{
	var binops:Hash<Array<BinopFunc>>;
	var unops:Hash<Array<UnopFunc>>;
		
	public function new()
	{
		unops = new Hash();
		binops = new Hash();
	}
	
	public function addBinop(op:BinopFunc)
	{
		if (!binops.exists(op.operator))
			binops.set(op.operator, []);
		binops.get(op.operator).push(op);
	}
	
	public function addUnop(op:UnopFunc)
	{
		if (!unops.exists(op.operator))
			unops.set(op.operator, []);
		unops.get(op.operator).push(op);
	}
	
	public function findBinop(op:BinopExt, lhs:Expr, rhs:Expr, isAssign:Bool, ctx:IdentDef, p, ?commutative = true)
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
	
	public function findUnop(op:UnopExt, postfix:Bool, lhs:Expr, ctx:IdentDef, p)
	{
		var opString = switch(op)
		{
			case Unop(op): tink.macro.tools.Printer.unoperator(op);
			case OpNew: "new";
		}
		
		if (!unops.exists(opString))
			return None;
		
		var t1 = switch(lhs.typeof(ctx))
		{
			case Success(t): t;
			case Failure(f): Context.error("Could not determine type: " +f + " | " +lhs.toString(), p);
		}

		for (opFunc in unops.get(opString))
		{
			if (postfix && !opFunc.postfix || !postfix && !opFunc.prefix) continue;
			
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
	
	public function findNew(tp:TypePath, args, ctx, p)
	{
		if (!unops.exists("new"))
			return None;
			
		var t1 = switch(TPath(tp).toType())
		{
			case Success(t): t;
			case Failure(f): Context.error("Could not determine type: " +f + " | " +tp, p);
		}
		
		for (opFunc in unops.get("new"))
		{
			switch(t1.isSubTypeOf(opFunc.lhs))
			{
				case Failure(s): continue;
				default:
			}
			return Some(opFunc.field.call(args));
		}
		return None;
	}
}