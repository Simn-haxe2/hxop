package ;

class OddStringTools
{
	@op("-") static public function weirdSubtring(s:String, i:Int)
	{
		return s.substr(0, -i);
	}
	
	@op("*") static public function repeat(s:String, i:Int)
	{
		return StringTools.lpad("", s, s.length * i);
	}
}