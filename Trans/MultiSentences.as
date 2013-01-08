package Trans 
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.events.Event;
	import flash.net.*;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author matzyou
	 */
	public class MultiSentences extends Sprite
	{
		/*
		 * 1つの見出しと1つ以上の英文を持つ
		 * コンストラクタは見出しの語が引数
		 * 以後英文を一つ一つ追加していく englishSentencesSpriteで管理
		 * 
		 */
		private var japaneseSentence:TextField, YOffset:int, XOffset:int;
		private static const sentenceCmpEvent:Event = new Event("sentenceSetCmp"), allCmpEvent:Event = new Event("allSetCmp");
		public var englishSentencesSprite:Vector.<Sprite>, wordsVector:Vector.<Vector.<Word>>, areaHeight:int, isHistory:Boolean;
		
		//最初に見出しを作って後から追加する
		public function MultiSentences(midashi:String, isHistory:Boolean = false) 
		{
			this.isHistory = isHistory;
			japaneseSentence = new TextField();
			var tfm:TextFormat = new TextFormat();
			if (Main.mainWidth == ResolutionNumbers.HVGAW360W) tfm.size = 10;
			else if(Main.mainWidth == ResolutionNumbers.QHD540W) tfm.size = 14;
			japaneseSentence.text = midashi;
			japaneseSentence.setTextFormat(tfm);
			addChild(japaneseSentence);
			japaneseSentence.width = Main.mainWidth - Main.mainWidth / 10;//300 = 350 - 50
			japaneseSentence.multiline = true;
			japaneseSentence.wordWrap = true;
			japaneseSentence.autoSize = TextFieldAutoSize.LEFT;
			japaneseSentence.y = 2;
			japaneseSentence.x = 4;
			japaneseSentence.selectable = false;
			areaHeight = 0;
			areaHeight += japaneseSentence.height - 2;
			englishSentencesSprite = new Vector.<Sprite>();
			wordsVector = new Vector.<Vector.<Word>>();
			queue = new Vector.<String>();
			YOffset = 0;
			YOffset += japaneseSentence.height - 2;
			drawArea();
			visible = false;//全部セットし終わったら表示する
			
		}
		
		public function show():void {visible = true;}
		
		private function drawArea():void {
			graphics.clear();
			graphics.lineStyle(1, 0xeb6101);
			graphics.moveTo(4, areaHeight);
			graphics.lineTo(Main.mainWidth - 28, areaHeight);//Main.mainWidth - 10 - 8 - 10
		}
		
		private var queue:Vector.<String>, eventCnt:int, queueLength:int, queueStr:String;
		//まずすべての要素を積む
		public function addSentences(str:String):void {queue.push(str);}
		//積み終わったらこっちを読んで処理する　これを呼び出してallSetCmpを受けるようにする
		public function setAllSentences():void {
			queueLength = queue.length;
			eventCnt = 0;
			setSentence();
		}
		//これを必要な回数だけ呼び出す
		public function setSentence():void {
			if((queueStr = queue.shift()) == null) return;
			//wordsVector.push(new Vector.<Word>());
			if (hasEventListener("sentenceSetCmp")) removeEventListener("sentenceSetCmp",cntSentenceSetCmp);
			addEventListener("sentenceSetCmp", cntSentenceSetCmp);//先にイベントをセット
			
			if (queueStr.match(/^【/)) addWordClass(queueStr);//【で始まるならWordClass
			else addEnglishSentence(queueStr);//それ以外なら英文
		}
		private function cntSentenceSetCmp(e:Event):void {
			removeEventListener("sentenceSetCmp",cntSentenceSetCmp);
			if (++eventCnt >= queueLength) {//すべての処理が終わったら
				areaHeight = YOffset + 4;
				drawArea();
				dispatchEvent(allCmpEvent);
			}
			else {//まだ処理すべき文が残ってる
				drawArea();
				setSentence();
			}
		}
		
		//【形】とかを追加する これはもう一行と仮定していいはず　でTextFieldで
		public function addWordClass(wordclass:String):void {
			var tfm:TextFormat = new TextFormat(), tf:TextField = new TextField();;
			tfm.color = 0x0f2350;
			tfm.size = 14;
			
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.text = wordclass;
			tf.setTextFormat(tfm);
			addChild(tf);
			tf.y = YOffset + 2;
			YOffset += tf.height - 6;
			areaHeight = YOffset + 6;
			//最後に完了したイベントを出して終わり
			dispatchEvent(sentenceCmpEvent);
		}
		
		//英文を追加　解析まで終わったらイベントが起こる
		public function addEnglishSentence(eng:String):void {parse(eng);}
		//--▼----ここから連続した処理-------▼--
		//英文受け取ってそれを単語に分解してArrayに入れて返す
		private function parse(str:String):void {
			//ALCならこれが必要　Glosbeはいらない
			if(Main.ENGINE == SearchManager.ALC){
				var str0:String = str.replace(/\r/g, ""), str4:Array, str5:String;
				str0 =　str0.replace(/全文表示/, "");
				str0 = str0.split(/〔/)[0];
				str0 = str0.split(/《/)[0];
				str0 = str0.split(/〈/)[0];
				str0 = str0.split(/◆/)[0];
				str4 = str0.split(/（/);
				str5 = str4[0];
				if (str4[1] != null && str4[1].match(/[a-zA-Z0-9_]/) != null) str5 = str0;
				if (str5.match(/（/)) {
					str5 = str5.replace(/（/g, "");
					str5 = str5.replace(/）/g, "");
				}
				str = str5;
			}
			analyzer(str);
		}
		//英文を受け取って解析して品詞とか調べて返す
		private function analyzer(str:String):void {
			var data:URLVariables = new URLVariables(), loader:AnalyzerLoader;
			data.Tex = str;
			loader= new AnalyzerLoader(data);
			loader.addEventListener(AnalyzerLoader.LOAD_COMPLETE, cmp);
			loader.load();
		}
		private function cmp(e:Event):void {
			var str:String = e.target.cgiLoader.data;
			if (str.match(/Can't open.*No such file/) != null) {
				//失敗したのでリロードする
				trace("--"+" reload "+"--");
				e.target.load();
				return;
			}
			var splitedStr:Array = str.split("\r\n"), dissectedStr:Array, word:Word,
				localXOffset:int = 0, localYOffset:int = 5, g:Graphics, splitedStrLength:int,
				englishSentence:Sprite = new Sprite(), words:Vector.<Word> = new Vector.<Word>(), allDragSprite:Sprite = new Sprite();
			englishSentencesSprite.push(englishSentence);
			englishSentence.x += Main.mainWidth / 20;
			englishSentence.addChild(allDragSprite);
			
			g = allDragSprite.graphics;
			if (isHistory)g.beginFill(0x164a84);
			else g.beginFill(0xeb6101);
			
			if (Main.mainWidth == ResolutionNumbers.HVGAW360W) g.drawCircle( -3, 15, 5);
			else if (Main.mainWidth == ResolutionNumbers.QHD540W) g.drawCircle( -10, 18, 8);
			g.endFill();
			
			splitedStrLength = splitedStr.length - 4;//便宜上splitedStr.length - 4をLengthとする
			for (var i:int = 3; i < splitedStrLength; i++) {//前後3つはタグなので不要要素
				dissectedStr = (String)(splitedStr[i]).split("\t");
				words.push(new Word(dissectedStr[0]));
				word = words[i - 3];
				englishSentence.addChild(word)
				word.setParse(dissectedStr[1]);
				word.lemma = dissectedStr[2];
				word.y = localYOffset;
				word.x = localXOffset + 5;
				if (word.x + word.textField.width > Main.mainWidth - Main.mainWidth / 10 - 10) {//追加して超えてたら折り返す
					localYOffset += 22; //360x640:16
					localXOffset = 0;
					word.y = localYOffset;
					word.x = localXOffset + 5;
				}
				localXOffset += word.textField.width + 5;
			}
			wordsVector.push(words);
			//showVector(words);
			addChild(englishSentence);
			englishSentence.y = YOffset;
			YOffset += localYOffset + 22; //16
			areaHeight = YOffset + 5;
			e.target.removeEventListener(AnalyzerLoader.LOAD_COMPLETE, cmp);
			//最後に完了したイベントを出して終わり
			dispatchEvent(sentenceCmpEvent);
		}
		//--▲----ここまで連続した処理-------▲--
		private function showVector(vector:Vector.<Word>):void {
			var str:String = new String();
			for (var i:int = 0; i < vector.length; i++ ) {
				str += vector[i].textField.text + ",";
			}
			trace("--"+str);
		}
		
	}

}