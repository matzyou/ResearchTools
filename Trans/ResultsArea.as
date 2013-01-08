package Trans 
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.system.System;
	import fl.controls.Button;
	/**
	 * ...
	 * @author matzyou
	 */
	/*
	 * 
	 * */
	public class ResultsArea extends Sprite
	{
		public var sentenceSprite:Sprite, sentences:Vector.<MultiSentences>, scrollOffset:int,
					upButton:Button, downButton:Button, max:int, scrollbarSprite:Sprite,
					ID:int, elementsCnt:int, stepIndex:int, isLoading:Boolean, isDBCmp:Boolean = false, isNetCmp:Boolean = false,
					areaWidth:int, areaHeight:int;
		private var barAreaSize:int, barSize:Number;
		
		public function ResultsArea(windowWidth:int, windowHeight:int, id:int) {
			areaWidth = windowWidth - 10;
			//areaHeight = windowHeight * 11 / 16 - 5 - 5;
			areaHeight = ((windowHeight * 11) >> 4) - 10;
			ID = id;
			elementsCnt = stepIndex = 0;
			barAreaSize = areaHeight - 30;
			
			sentenceSprite = new Sprite(); //これの上にMultiSentencesを載せていく　スクロールはこれを上下に動かす
			addChild(sentenceSprite);
			graphics.beginFill(0xeaf4fc);
			graphics.drawRoundRect(0, 0, areaWidth, areaHeight, 5, 5);
			graphics.endFill();
			sentences = new Vector.<MultiSentences>();
			
			scrollbarSprite = new Sprite();
			addChild(scrollbarSprite);
			scrollbarSprite.addEventListener(MouseEvent.MOUSE_DOWN, MD);
			scrollbarSprite.addEventListener(MouseEvent.MOUSE_UP, MU);
			scrollbarSprite.x = areaWidth - 13;//337 = 350 - 13
			scrollbarSprite.y = 15;
			buttonSet();
			addEventListener(MouseEvent.MOUSE_WHEEL, MW);
		}
		
		//画面をクリアする
		public function clearArea():void {
			sentenceSprite.removeChildren();
			scrollbarSprite.removeChildren();
			scrollbarSprite.removeEventListener(MouseEvent.MOUSE_DOWN, MD);
			scrollbarSprite.removeEventListener(MouseEvent.MOUSE_UP, MU);
			removeEventListener(MouseEvent.MOUSE_WHEEL, MW);
			scrollbarSprite = null;
			sentences = null;
			sentenceSprite = null;
			System.gc();
		}
		
		
		//検索結果は一度スタックして，解析結果帰ってきたのから順次追加とかかなぁ
		//MultiSentencesでまとめることにした　まず日本語の見出しを作ってその下に順次英文を追加していく
		private var YOffset:int = 0, index:int;
		//日本語と英語の対で一つのまとまりを作る
		public function setSentence(jpn:String, eng:String, isHistory:Boolean = false):void {
			index = sentences.push(new MultiSentences(jpn,isHistory)) - 1;
			sentenceSprite.addChild(sentences[index]);
			sentences[index].addSentences(eng);
			sentences[index].y = YOffset;
			//作るのはいいけど，Wordの解析結果が来ないと縦方向の大きさわからないからsetCmp待ちじゃね？
			YOffset += sentences[index].height + 2;
			max = YOffset;
		}
		
		private var tmpobj2:Object;
		//複数ある場合はこっち
		public function setMultiSentences(data:Object, midashi:String, wordclass:Object):void {
			//まず最初に見出しを作って，後から要素を順次追加していく
			//data は ul_je を持つ配列
			index = sentences.push(new MultiSentences(midashi))　 - 1;
			sentenceSprite.addChild(sentences[index]);
			sentences[index].y = YOffset;
			var wordclassIndex:int = 0, dataLength:int = data.length, tmpobj2Length:int;
			for ( var n:int = 0; n < dataLength; n++) {//-------------------------------------▼
				if (data[n].tagName == "UL") {//ulなら普通に処理
					tmpobj2 = data[n].getElementsByTagName("li");
					tmpobj2Length = tmpobj2.length;
					//英語を全部抜き出す
					for (var j:int = 0; j < tmpobj2Length; j++ ) {//必要な数だけ英文を追加する
						sentences[index].addSentences(tmpobj2[j].textContent);
					}
				}else if(data[n].tagName == "OL") {//olだと【～～】がある　しかもこっちだとliないこともある
					tmpobj2 = data[n].getElementsByTagName("li");
					tmpobj2Length = tmpobj2.length;
					sentences[index].addSentences(wordclass[wordclassIndex++].textContent);
					//英語を全部抜き出す
					if (!(tmpobj2Length > 0)) {//1つもない　つまり【～～】改行して英文1つ
						sentences[index].addSentences(data[n].textContent);
					}
					else{//【～～】に続く英文が2つ以上ある
						for (var m:int = 0; m < tmpobj2Length; m++ ) {//必要な数だけ英文を追加する
							sentences[index].addSentences(tmpobj2[m].textContent);
						}
					}
				}
			}//---------------------------------------------------------------------------------▲
			max = YOffset;
		}
		
		private var tmpOffset:int;
		public function alignMultiSentences():void {
			tmpOffset = 0;
			var num:int = sentences.length;
			for (var i:int = 0; i < num; i++) {//今ある分だけ整列
				sentences[i].y = tmpOffset;
				tmpOffset += sentences[i].areaHeight + 3;
			}
			max = tmpOffset;
		}
		
		//--▼-スクロール処理-▼--▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		public function scrollSet():void {
			//0 ~ max
			if (max < areaHeight) {
				scrollbarSprite.visible = false;
			}else {
				var d:Number = downButton.y - upButton.y + 12, g:Graphics = scrollbarSprite.graphics;
				//var d:Number = barAreaSize//areaHeight - 30;
				//スクロールバーの描画
				//upbutton 3+12=15 downbutton 445 430
				barSize = d * d / max;
				pow = Number(areaHeight / barAreaSize) / (d / max);
				g.clear();
				g.beginFill(0xa0a0a0);
				g.drawRoundRect(0, 0, 12, barSize, 4, 4);
				g.endFill();
				scrollbarSprite.visible = true;
				//trace("barsize:"+barSize+",pow:"+pow);
			}
		}
		private var preY:int, diffY:int, startY:int, pow:Number, isTail:Boolean;
		private function MD(e:MouseEvent):void {
			scrollbarSprite.parent.parent.addEventListener(MouseEvent.MOUSE_MOVE, MM);
			scrollbarSprite.parent.parent.addEventListener(MouseEvent.MOUSE_UP, MU);
			preY = mouseY;
		}
		private function MM(e:MouseEvent):void {
			isTail = false
			scrollbarSprite.y += mouseY - preY;
			if (scrollbarSprite.y < 15) scrollbarSprite.y = 15;
			else if (scrollbarSprite.y > areaHeight - 15 - barSize) {
				scrollbarSprite.y = areaHeight - 15 - barSize;
				isTail = true;
			}
			sentenceSprite.y = (scrollbarSprite.y - 15) * -pow;
			if (sentenceSprite.y > 0) sentenceSprite.y = 0;
			else if (sentenceSprite.y < -max + areaHeight || isTail) sentenceSprite.y = -max + areaHeight;
			preY = mouseY;
		}
		private function MU(e:MouseEvent):void {
			scrollbarSprite.parent.parent.removeEventListener(MouseEvent.MOUSE_MOVE, MM);
			scrollbarSprite.parent.parent.removeEventListener(MouseEvent.MOUSE_UP, MU);
		}
		
		private function buttonSet():void {
			upButton = new Button();
			upButton.width = 12;
			upButton.height = 12;
			upButton.label = "▲";
			addChild(upButton);
			upButton.x = areaWidth - 13;
			upButton.y = 3;
			upButton.addEventListener(MouseEvent.CLICK, upClick);
			
			downButton = new Button();
			downButton.width = 12;
			downButton.height = 12;
			downButton.label = "▼";
			addChild(downButton);
			downButton.x = areaWidth - 13;
			downButton.y = areaHeight - 15;
			downButton.addEventListener(MouseEvent.CLICK, downClick);
		}
		
		private function upClick(e:MouseEvent):void {
			sentenceSprite.y += 24;
			if (sentenceSprite.y > 0) sentenceSprite.y = 0;
			scrollbarSprite.y = sentenceSprite.y / -pow;
			if (scrollbarSprite.y < 15) scrollbarSprite.y = 15;
			else if (scrollbarSprite.y > areaHeight - 15 - barSize) scrollbarSprite.y = areaHeight - 15 - barSize;
		}
		private function downClick(e:MouseEvent):void {
			isTail = false;
			sentenceSprite.y -= 24;
			if (sentenceSprite.y < -max + areaHeight) {
				sentenceSprite.y = -max + areaHeight;
				isTail = true;
			}
			scrollbarSprite.y = sentenceSprite.y / -pow;
			if (scrollbarSprite.y < 15) scrollbarSprite.y = 15;
			else if (scrollbarSprite.y > areaHeight - 15 - barSize || isTail) scrollbarSprite.y = areaHeight - 15 - barSize;
		}
		
		private function MW(e:MouseEvent):void {
			isTail = false;
			if (e.delta > 0) {
				sentenceSprite.y += 24;
				if (sentenceSprite.y > 0) sentenceSprite.y = 0;
			}else if (e.delta < 0) {
				sentenceSprite.y -= 24;
				if (sentenceSprite.y < -max + areaHeight) {
					sentenceSprite.y = -max + areaHeight;
					isTail = true;
				}
			}
			scrollbarSprite.y = sentenceSprite.y / -pow;
			if (scrollbarSprite.y < 15) scrollbarSprite.y = 15;
			else if (scrollbarSprite.y > areaHeight - 15 - barSize || isTail) scrollbarSprite.y = areaHeight - 15 - barSize;
		}
		
	}

}