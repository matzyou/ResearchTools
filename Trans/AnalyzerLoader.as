package Trans 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLVariables;
	/**
	 * ...
	 * @author matzyou
	 */
	public class AnalyzerLoader extends EventDispatcher
	{
		//ロードに失敗することがあるから　失敗した時にリロード　再リクエストできるようにするためのクラス
		public var urlRequest:URLRequest, cgiLoader:URLLoader;
		public static const LOAD_COMPLETE:String = "loadCmp";
		private static const cmpEvent:Event = new Event(LOAD_COMPLETE);
		public function AnalyzerLoader(data:URLVariables) 
		{
			urlRequest = new URLRequest("http://web4u.setsunan.ac.jp/Website/cmd/tt_win.cgi");
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = data;
			cgiLoader = new URLLoader();
			cgiLoader.dataFormat = URLLoaderDataFormat.TEXT;
		}
		
		public function load():void {
			cgiLoader.load(urlRequest);
			cgiLoader.addEventListener(Event.COMPLETE, loadCmp);
		}
		
		private function loadCmp(e:Event):void {
			cgiLoader.removeEventListener(Event.COMPLETE, loadCmp);
			dispatchEvent(cmpEvent);
		}
	}

}