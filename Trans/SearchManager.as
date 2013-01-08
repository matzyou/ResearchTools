package Trans 
{
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	/**
	 * ...
	 * @author matzyou
	 */
	public class SearchManager extends EventDispatcher
	{
		public static const ALC:String = "alc", GLOSBE:String = "glosbe";
		private var ENGINE:String, ID:int, htmlLoader:HTMLLoader, urlLoader:URLLoader;
		public function SearchManager(engine:String, id:int) 
		{
			ENGINE = engine;
			ID = id;
			switch(ENGINE) {
				case ALC:
					htmlLoader = new HTMLLoader();
					break;
				case GLOSBE:
					urlLoader = new URLLoader();
					break;
				default : trace("undefined type")
			}
		}
		
		public function load(url:URLRequest):void {
			switch(ENGINE) {
				case ALC:
					htmlLoader.load(url);
					htmlLoader.addEventListener(Event.COMPLETE, loadCmp);
					htmlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
					break;
				case GLOSBE:
					urlLoader.load(url);
					urlLoader.addEventListener(Event.COMPLETE, loadCmp);
					urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
					break;
				default : trace("undefined type")
			}
		}
		
		private function loadCmp(e:Event):void {
			e.target.removeEventListener(Event.COMPLETE, loadCmp);
			switch(ENGINE) {
				case ALC:
					dispatchEvent(new SearchEvent(SearchEvent.SEARCH_COMPLETE, null, id, htmlLoader));
					break;
				case GLOSBE:
					dispatchEvent(new SearchEvent(SearchEvent.SEARCH_COMPLETE, e.target.data, id));
					break;
				default : trace("undefined type")
			}
		}
		
		private function loadError(e:IOErrorEvent):void {
			trace("-- load io error --");
		}
		
		public function get id():int { return ID; }
		public function get engine():String { return ENGINE; }
	}

}