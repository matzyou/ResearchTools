package Trans 
{
	import flash.events.Event;
	import flash.html.HTMLLoader;
	
	/**
	 * ...
	 * @author matzyou
	 */
	public class SearchEvent extends Event 
	{
		private var DATA:Object, ID:int, LOADER:HTMLLoader;
		public static const SEARCH_COMPLETE:String = "searchComplete";
		public function SearchEvent(type:String, data:Object, id:int, loader:HTMLLoader=null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			DATA = data;
			ID = id;
			LOADER = loader;
		} 
		
		public override function clone():Event 
		{ 
			return new SearchEvent(type, DATA, ID, LOADER, bubbles, cancelable);
		}
		
		public override function toString():String 
		{ 
			return formatToString("SearchEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get data():Object { return DATA; }
		public function get id():int { return ID; }
		public function get loader():HTMLLoader { return LOADER; }
	}
	
}