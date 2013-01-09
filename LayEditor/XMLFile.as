package  
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	/**
	 * ...
	 * @author MatzYou
	 */
	public class XMLFile extends EventDispatcher{
		
		private var file:File;
		private var stream:FileStream;
		private var str:String;
		private var XMLDATA:XML;
		private var loader:URLLoader;
		
		
		public function XMLFile() {
			str = new String();
			loader = new URLLoader();
			
		}
		
		public function openFile():void {
			try {
				var filter:FileFilter = new FileFilter("XML","*.xml");
				var filter2:FileFilter = new FileFilter("TXT", "*.txt");
				file = new File();
				file.browseForOpen("Open",[filter,filter2]);
				file.addEventListener(Event.SELECT, onOpenSelected);
			}catch (e:Error){
				trace("error",e.message);
			}
		}
		
		private function onOpenSelected(e:Event):void {
			trace(file.url);
			if (file.extension == "txt") {
				//txtなら別の処理するかも
			}
			else if(file.extension == "xml"){
				var url:URLRequest = new URLRequest(file.url);
				file.removeEventListener(Event.SELECT, onOpenSelected);
				loader.addEventListener(Event.COMPLETE, onLoaded);
				loader.load(url);
			}
			else trace("---------unknown extension---------");
			
		}
		
		private function onLoaded(e:Event):void {
			XMLDATA = new XML(loader.data);
			loader.removeEventListener(Event.COMPLETE, onLoaded);
			var loadCompEvent:FileEvent = new FileEvent("loadComplete");
			loadCompEvent.fileName = file.name;
			this.dispatchEvent(loadCompEvent);
		}
		
		public function saveFile(data:XML):void {
			/* save 
			 * これって書き出しが必要だから，最後の方に回したほうが良さそう
			 * */
			file = new File();
			XMLDATA = data;
			//とりあえずこれで書き出せるからこれでいいや　xml整形はメイン側でやる
			file.browseForSave("Save as　*.xml");
			
			//file.save(data);
			file.addEventListener(Event.SELECT, onSaveSelected);
		}
		
		public function onSaveSelected(e:Event):void {
			var newfile:File = e.target as File;
			
			if (newfile.extension != "xml") {
				trace(newfile.extension);
				newfile.nativePath += ".xml";
				trace(newfile.nativePath);
			}
			
			stream = new FileStream();
			stream.open(newfile,FileMode.WRITE);
			stream.writeUTFBytes(XMLDATA);
			stream.close();
			trace("save done");
			var saveCompEvent:FileEvent = new FileEvent("saveComplete");
			saveCompEvent.fileName = newfile.name;
			this.dispatchEvent(saveCompEvent);
		}
		
		public function get xml():XML {
			return XMLDATA;
		}
		
	}

}