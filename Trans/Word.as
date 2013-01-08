package Trans 
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author matzyou
	 */
	public class Word extends Sprite{
		
		public var cover:Sprite, back:Shape, textField:TextField,
					parse:String, //品詞の種類
					lemma:String, //その単語の元の形
					modifyVector:Vector.<String>;
		public static const INSERT:String = "INSERT", USER:String = "USER";
		private var tf:TextFormat, g:Graphics;
		//英単語を引数にして　ドラッグ可能なものを作る
		public function Word(str:String) {
			
			tf = new TextFormat();
			if (Main.mainWidth == ResolutionNumbers.HVGAW360W) tf.size = 14;
			else if (Main.mainWidth == ResolutionNumbers.QHD540W) tf.size = 18; //360x640:14 640x960:18
			else tf.size = 22;
			textField = new TextField();
			textField.text = str;
			textField.setTextFormat(tf);
			textField.autoSize = TextFieldAutoSize.LEFT;
			textField.selectable = false;
			textField.mouseEnabled = false;
			addChild(textField);
			
			back = new Shape();
			g = back.graphics;
			g.beginFill(0xffd1e8,0.1);
			g.drawRoundRect(0, 4, textField.width, textField.height - 4, 5, 5);
			g.endFill();
			addChild(back);
			swapChildren(textField, back);
			
			cover = new Sprite();
			g = cover.graphics;
			g.beginFill(0xffffff,0.01);
			g.drawRoundRect(0, 4, textField.width, textField.height - 4, 5, 5);
			g.endFill();
			addChild(cover);
			cover.doubleClickEnabled = true;
			
			modifyVector = new Vector.<String>();
			
		}
		
		public function changeWord(newWord:String):void {
			textField.text = newWord;
			textField.setTextFormat(tf);
			setParse(this.parse);
			g = cover.graphics;
			g.clear();
			g.beginFill(0xffffff,0.01);
			g.drawRoundRect(0, 4, textField.width, textField.height - 4, 5, 5);
			g.endFill();
		}
		
		public function setParse(str:String):void {
			parse = str;
			var color:uint;
			switch(parse) {
				//ユーザ定義　書き換えとか　追加した時の色　　また解析して色つけてもいい？
				case "USER": color = 0xc9ff44; break;
				case "INSERT": color = 0x00ff00; break;
				
				//動詞　V~~は動詞？ VBはbe動詞
				case "VB": case "VBD": case "VBG": case "VBN": case "VBP": case "VBZ":
					color = 0xff4388;
					modifyVector.push("am", "are", "is", "was", "were", "be", "been");
					break;
				
				//have
				case "VH": case "VHD": case "VHG": case "VHN": case "VHP": case "VHZ":
				 color = 0xff4388;
					modifyVector.push("have","has","had");
					break;
				
				//その他動詞
				case "VV": case "VVD": case "VVG": case "VVN": case "VVP": case "VVZ":
					color = 0xff4388;
					break;
				
				//人称代名詞
				case "PP": color = 0xfff344;
					if (text == "I" || text == "you" || text == "You" || text == "he" || text == "He" ||
						text == "she" || text == "She" || text == "it" || text == "It" || text == "we" || text == "We" || text == "they" || text == "They")
						modifyVector.push("I", "you", "he", "she", "it", "we", "they");
					if(text == "me" || text == "you" || text == "him" || text == "her" || text == "it" || text == "us" || text == "them")
						modifyVector.push("me", "you", "him", "her", "it", "us", "them");
					break;
				//case "PP$": color = 0xfff344; break;
				case "PP$": color = 0xff0000; break;
				
				//?
				case "WDT": color = 0x4188ff; break;
				case "WP": color = 0x4188ff; break;
				case "WP$": color = 0x4188ff; break;
				case "WRB": color = 0x4188ff; break;
				
				//?
				case "CC": color = 0x41f3ff; break;
				case "IN": color = 0x41f3ff; break;
				case "TO": color = 0x41f3ff; break;
				
				//助動詞 can will
				case "MD": color = 0x63da64; break;
				
				//?
				case "JJ": color = 0xffb643; break;
				case "JJR": color = 0xffb643; break;
				case "JJS": color = 0xffb643; break;
				
				//?
				case "RB": color = 0xc641ff; break;
				case "RBR": color = 0xc641ff; break;
				case "RBS": color = 0xc641ff; break;
				
				default: color = 0xcccccc;
			}
			g = back.graphics;
			g.clear();
			g.beginFill(color,0.5);
			g.drawRoundRect(0, 2, textField.width, textField.height - 4, 5, 5);
			g.endFill();
		}
		
		//ComposeArea内にドロップされた時に調べる　極力使う回数を減らす　結果が反映されるまで右クリックしても空白だけどしょうがない
		public function setModify():void {
			var loader:URLLoader = new URLLoader();
			loader.load(new URLRequest("http://glosbe.com/en/en/" + lemma));//元の形がわかってるのでこっちで調べる
			loader.addEventListener(Event.COMPLETE, modifyCmp);
		}
		private function modifyCmp(e:Event):void {
			e.target.removeEventListener(Event.COMPLETE, modifyCmp);
			var str:String, strArray:Array, strArrayLength:int, vLength:int, flag:Boolean;
			str = String(e.target.data).split(/additional-data">/)[1].split(/<\/div>/)[0];
			if (str == null) return;
			strArray = str.match(/<b>.*?<\/b>/g);
			if (strArray == null) return;
			strArrayLength = strArray.length;
			
			modifyVector.push(text);
			for (var i:int = 0; i < strArrayLength; i++) {
				flag = true;
				vLength = modifyVector.length;
				str = strArray[i].replace("<b>", "").replace("</b>", "");
				if (str.length > 30) continue;
				for (var j:int = 0; j < vLength ; j++) { //同じ単語は登録しない
					if (str == modifyVector[j]) flag = false;
				}
				if (flag) modifyVector.push(str);
			}
		}
		
		public function get text():String {
			return textField.text;
		}
	}

}