package hxop;

#if macro

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

class Compiler 
{
	static public function overload(paths:Array<String>, mathClass:String)
	{
		for (path in paths)
			traverse(path, "", mathClass);
	}
	
	static function traverse(cp:String, pack:String, mathClass:String)
	{
		for (file in neko.FileSystem.readDirectory(cp))
		{
			if (StringTools.endsWith(file, ".hx"))
			{
				var cl = (pack == "" ? "" : pack + ".") + file.substr(0, file.length - 3);
				try
				{
					haxe.macro.Compiler.addMetadata("@:build(hxop.engine.OverloadOperator.build('" +mathClass+ "'))", cl);
				} catch (e:Dynamic)
				{
				}
			}
			else if(neko.FileSystem.isDirectory(cp + "/" + file))
				traverse(cp + "/" + file, pack == "" ? file : pack + "." +file, mathClass);
		}
	}
}

#end