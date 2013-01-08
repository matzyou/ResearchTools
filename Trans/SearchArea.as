package Trans 
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.text.*;
	import flash.net.URLRequest;
	import fl.controls.*;
	import fl.events.*;
	import flash.system.IME;
	import flash.system.IMEConversionMode;
	/**
	 * ...
	 * @author matzyou
	 */
	public class SearchArea extends Sprite
	{
		public var queryTextInput:TextInput, searchButton:Button,
					areaWidth:int, areaHeight:int;
		
		public function SearchArea(windowWidth:int, windowHeight:int) {
			areaWidth = windowWidth - 10;
			areaHeight = (windowHeight >> 4) - 5;
			graphics.beginFill(0xd6e9ca);
			//graphics.drawRoundRect(0, 0, 350, 40, 5, 5);
			graphics.drawRoundRect(0, 0, areaWidth, (areaHeight + 5) * 2 / 3, 5, 5);
			graphics.endFill();
			
			var txfmt:TextFormat = new TextFormat(), tfm:TextFormat = new TextFormat();
			if(Main.mainWidth == ResolutionNumbers.HVGAW360W) txfmt.size = 10; //360x640
			else if (Main.mainWidth == ResolutionNumbers.QHD540W) txfmt.size = 22;
			else txfmt.size = 30;
			txfmt.color = 0x001e43;
			txfmt.leftMargin = 4;
			txfmt.font = "小塚ゴシック　Pro　R";
			
			queryTextInput = new TextInput();
			queryTextInput.setStyle("textFormat", txfmt);
			addChild(queryTextInput);
			queryTextInput.textField.embedFonts = true;
			queryTextInput.textField.backgroundColor = 0xdbd0e6;
			queryTextInput.x = 10;
			queryTextInput.y = 5;
			queryTextInput.width = (areaWidth << 1) / 3;
			queryTextInput.height = ((areaHeight + 5) << 1) / 3 - 10;
			queryTextInput.textField.addEventListener(FocusEvent.FOCUS_IN,focusIn);
			
			searchButton = new Button();
			addChild(searchButton);
			searchButton.x = queryTextInput.x + queryTextInput.width + 10;
			searchButton.y = 5;
			searchButton.width = areaWidth - searchButton.x - 5;
			searchButton.height = queryTextInput.height;
			
			if(Main.mainWidth == ResolutionNumbers.HVGAW360W) tfm.size = 10; //360x640
			else if (Main.mainWidth == ResolutionNumbers.QHD540W) tfm.size = 18;
			else tfm.size = 30;
			searchButton.setStyle("textFormat", tfm);
			searchButton.label = "Seach";
			
		}
		
		public function focusIn(e:Event):void {
			IME.conversionMode = IMEConversionMode.JAPANESE_HIRAGANA;
		}
		
		public function get query():String { return queryTextInput.text; }
		public function set query(str:String):void { queryTextInput.text = str; }
		
		public function setQueryURL(engine:String):URLRequest {
			switch(engine) {
				case SearchManager.ALC: return setALCQueryURL();
				case SearchManager.GLOSBE: return setGlosbeQueryURL();
			}
			return null;
		}
		
		//ALCにqueryTextInputの中身をクエリとして変換
		public function setALCQueryURL():URLRequest {
			return new URLRequest("http://eow.alc.co.jp/search?q=" + query);
		}
		
		//tm?~~で例文検索　translate?~~で単語　　tm?~~で &page=n でnページ目の検索結果に飛べる
		public function setGlosbeQueryURL():URLRequest {
			return new URLRequest("http://glosbe.com/gapi/tm?from=jpn&dest=eng&format=xml&phrase="+query);
		}

	}

}