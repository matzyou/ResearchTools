package Trans 
{
	import fl.controls.Button;
	import fl.controls.TextInput;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import fl.events.ComponentEvent;
	import flash.system.System;
	import flash.events.FocusEvent;
	import flash.system.IME;
	import flash.system.IMEConversionMode;
	/**
	 * ...
	 * @author matzyou
	 */
	public class ComposeArea extends Sprite
	{
		public var composeSprite:Sprite, words:Vector.<Word>, composeWords:Vector.<Word>,
					outputButton:Button, insertButton:Button, clearButton:Button, tf:TextField,
					areaWidth:int, areaHeight:int;
		private var clipboard:Clipboard = Clipboard.generalClipboard, g:Graphics;
		public static const INSERT_WORD_EVENT:String = "insertWord", DONE_EVENT:String = "doneEvent";
		private static const insertWordEvent:Event = new Event(INSERT_WORD_EVENT), doneEvent:Event = new Event(DONE_EVENT);
		
		public function ComposeArea(windowWidth:int, windowHeight:int) {
			areaWidth = windowWidth - 10;
			areaHeight = (windowHeight >> 2) - 10;
			
			graphics.beginFill(0xf8f4e6);
			graphics.drawRoundRect(0, 0, areaWidth, areaHeight, 5, 5);
			graphics.endFill();
			
			composeSprite = new Sprite();
			g = composeSprite.graphics;
			composeSprite.name = "composeSprite";
			g.beginFill(0xf0f0f0);
			g.drawRoundRect(4, 4, areaWidth - 8, areaHeight - 8, 5, 5);
			g.endFill();
			addChild(composeSprite);
			composeWords = new Vector.<Word>();
			
			buttonSet();
			dialogLayerSet();
		}
		
		//word郡を整列させる
		/*複数行になった時とそうじゃない時とで場合分けが必要な気がする
		 * yは5,25,45,65の4段階かな
		 * 全文ドロップした時には一括でセットするようなのを作る
		*/
		private var multiLineNum:int = 0;//行数カウントだけど便宜上0スタート
		public function alignWords():void {
			composeWords = new Vector.<Word>();
			var tmpNum:int;
			for (var i:int = 0; i < composeSprite.numChildren; i++) {
				if (multiLineNum > 0) {//複数行 一列に整列させてしまう
					tmpNum = (composeSprite.getChildAt(i).y - 5) / 20;
					composeSprite.getChildAt(i).x += tmpNum * areaWidth;
					composeSprite.getChildAt(i).y = 5;
					composeWords.push(composeSprite.getChildAt(i));
				}else {//単数行
					composeSprite.getChildAt(i).y = 5;
					composeWords.push(composeSprite.getChildAt(i));
				}
			}
			composeWords.sort(vectSortX);
			var XOffset:int = 5;
			var YOffset:int = 5;
			multiLineNum = 0;
			for (var j:int = 0; j < composeWords.length; j++) {
				composeWords[j].x = XOffset + 5;
				composeWords[j].y = YOffset;
				if (composeWords[j].x + composeWords[j].textField.width > areaWidth - 10) {//追加して超えてたら折り返す
					YOffset += 22;
					XOffset = 5;
					composeWords[j].y = YOffset;
					composeWords[j].x = XOffset + 5;
					++multiLineNum;
				}
				XOffset += composeWords[j].textField.width + 5;
				
			}
			//trace(getSentence());
		}
		
		//vectorのsort用比較関数　オブジェクトのX座標で比較するように設定
		private function vectSortX(x:Object, y:Object):Number {return x.x - y.x;}
		
		//composeAreaにある単語を結合して返す
		public function getSentence():String {
			var res:String = "";
			for (var j:int = 0; j < composeWords.length; j++) {
				res += composeWords[j].text + " ";
			}
			return res;
		}
		
		//●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
		//ボタンの設定
		private function buttonSet():void {
			outputButton = new Button();
			outputButton.label = "Done";
			outputButton.width = areaWidth / 7;
			outputButton.height = areaHeight / 8;
			addChild(outputButton);
			outputButton.x = areaWidth - outputButton.width - 3;//297 = 350 - 50 - 3
			outputButton.y = areaHeight - outputButton.height - 5; //93 = 120 - 25 - 5
			outputButton.addEventListener(MouseEvent.CLICK, outputClick);
			
			insertButton = new Button();
			insertButton.label = "Add";
			insertButton.width = outputButton.width;
			insertButton.height = outputButton.height;
			addChild(insertButton);
			insertButton.x = outputButton.x - insertButton.width - 5;
			insertButton.y = outputButton.y;
			insertButton.addEventListener(MouseEvent.CLICK, insertClick);
			
			clearButton = new Button();
			clearButton.label = "Clear";
			clearButton.width = outputButton.width;
			clearButton.height = outputButton.height;
			addChild(clearButton);
			clearButton.x = insertButton.x - clearButton.width - 5;
			clearButton.y = outputButton.y;
			clearButton.addEventListener(MouseEvent.CLICK, clearClick);
			
		}
		private function outputClick(e:MouseEvent):void {
			//クリップボードにコピー
			clipboard.setData(ClipboardFormats.TEXT_FORMAT, getSentence());
			trace("copy to clipboard --> " + getSentence());
			//ここで全てのタブの日本語とコピーした英文をセットで登録する
			//明日　晴れ　と　いいな　で検索して　I hope tomorrow is sunny!　を作ったらそれを登録
			dispatchEvent(doneEvent);
		}
		private function insertClick(e:MouseEvent):void {dialogLayerOpen();}
		private function clearClick(e:MouseEvent):void {
			composeSprite.removeChildren();
			composeWords = new Vector.<Word>();
			System.gc();
		}
		
		//▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼ Dialog Functions ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		private var dialogLayer:Sprite, dialogTF:TextField, wordInput:TextInput, 
					ok:Button, cancel:Button, isChangeWord:Boolean, targetWord:Word;
		private function dialogLayerSet():void {
			dialogLayer = new Sprite();
			dialogLayer.graphics.beginFill(0x000000, 0.3);
			dialogLayer.graphics.drawRoundRect(0, 0, areaWidth, areaHeight, 5, 5);
			dialogLayer.graphics.endFill();
			addChild(dialogLayer);
			
			var areaSprite:Sprite = new Sprite(), tfm:TextFormat;
			g = areaSprite.graphics;
			g.beginFill(0xf5f5f5,0.7);
			g.drawRoundRect((areaWidth >> 1) - areaWidth * 5 / 14, (areaHeight >> 1) - ((areaHeight * 3) >> 3), areaWidth * 5 / 7, ((areaHeight * 3) >> 2), 5, 5);
			g.endFill();
			dialogLayer.addChild(areaSprite);
			
			tfm = new TextFormat();
			tfm.size = 22;
			tfm.color = 0x0000cd;
			tfm.align = "center";
			
			wordInput = new TextInput();
			wordInput.setStyle("textFormat", tfm);
			areaSprite.addChild(wordInput);
			wordInput.textField.backgroundColor = 0xfffacd;
			wordInput.width = areaWidth * 3 / 7;
			wordInput.height = areaHeight / 6;
			wordInput.x = (areaWidth >> 1) - (wordInput.width >> 1);
			wordInput.y = (areaSprite.height >> 1) - (wordInput.height >> 1);
			wordInput.addEventListener(ComponentEvent.ENTER, dialogOK);
			wordInput.textField.addEventListener(FocusEvent.FOCUS_IN,focusIn);
			
			ok = new Button();
			ok.label = "OK";
			ok.width = areaWidth / 7;
			ok.height = areaHeight >> 3;
			areaSprite.addChild(ok);
			ok.x = (areaWidth >> 1) - ok.width / 5 - ok.width;
			ok.y = (areaSprite.height * 3) >> 2;
			ok.addEventListener(MouseEvent.CLICK, dialogOK);
			
			cancel = new Button();
			cancel.label = "Cancel";
			cancel.width = areaWidth / 7;
			cancel.height = areaHeight >> 3;
			areaSprite.addChild(cancel);
			cancel.x = (areaWidth >> 1) + cancel.width / 5;
			cancel.y = ok.y;
			cancel.addEventListener(MouseEvent.CLICK, dialogCancel);
			
			dialogLayer.visible = false;
		}
		public function dialogLayerOpen(str:String = "", flag:Boolean = false , word:Word = null ):void {
			dialogLayer.visible = true;
			wordInput.text = str;
			this.stage.focus = wordInput;
			isChangeWord = flag;
			targetWord = word;
			trace(word);
		}
		private function dialogLayerClose():void {
			dialogLayer.visible = false;
			wordInput.text = "";
		}
		private function dialogOK(e:MouseEvent):void {
			if (wordInput.text != "") {
				if(!isChangeWord){
					var tmp:Word = new Word(wordInput.text);
					tmp.setParse("USER");
					composeSprite.addChild(tmp);
					//エリア外ならいい　800，800はどの解像度でもエリア外
					tmp.x = 800;
					tmp.y = 800;
					composeSprite.dispatchEvent(insertWordEvent);
				}
				else {
					targetWord.changeWord(wordInput.text);
					targetWord.setParse("USER"); //変更するともうそれがなんなのか判定つかないからUSER設定にする
					alignWords();
				}
			}else {
				
			}
			dialogLayerClose();
		}
		private function dialogCancel(e:MouseEvent):void {dialogLayerClose();}
		private function focusIn(e:Event):void {IME.enabled = false;}
		//▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲ Dialog Functions ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
	}

}