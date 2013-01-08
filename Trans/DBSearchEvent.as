package Trans 
{
	import flash.data.SQLResult;
	import flash.events.Event;
	/**
	 * ...
	 * @author matzyou
	 */
	public class DBSearchEvent extends Event
	{
		private var results:SQLResult, ID:int;
		public static const SEARCH_COMPLETE:String = "searchComplete";
		public function DBSearchEvent(type:String, value:SQLResult, id:int, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			results = value;
			ID = id;
		} 
		public override function clone():Event 
		{ 
			return new DBSearchEvent(type, results, ID, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DBSearchEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get sqlResult():SQLResult { return results; }
		public function get id():int { return ID; }
	}

}