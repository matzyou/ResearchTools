package  
{
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.FocusEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author MatzYou
	 */
	public class LayeredArea extends Sprite	{
		
		private var debag:Boolean = true;
		public var localSprite:Sprite;
		public var backgroundShape:Shape;
		public var whiteShape:Shape;
		public var dragSprite:Sprite;
		public var dragSpriteMini:Sprite;
		public var localTextField:TextField;
		public var opacity:int = 100;
		public var sliderX:Number = 1;
		public var modeLabel:String = "通常";
		public var modeData:int = 0;
		public var insertSpaceLine:int = 0;
		public var createDate:Date;
		public var lastChangeDate:Date;
		
		public var parentLayerIndex:int = -1;
		public var myLayerIndex:int = -1;
		public var childLayerIndex:int = -1;
		
		public static var fontSize:int = 20;//16-19 20-22
		public static var textHeight:int = 22;
		
		public static var nowFocusLayerIndex:int = -1;
		public static var numberOfLayer:int = 0;
		public var pattern:RegExp = /\r/;
		public var backColor:uint = 0x333333;
		
		public function LayeredArea(sp:Sprite,yPos:int=0) {
			/* initialize */
			localTextField = new TextField();
			localSprite = new Sprite();
			backgroundShape = new Shape();
			whiteShape = new Shape();
			dragSprite = new Sprite();
			dragSpriteMini = new Sprite();
			localSprite.addChild(whiteShape);
			localSprite.addChild(backgroundShape);
			localSprite.addChild(dragSprite);
			localSprite.addChild(localTextField);
			localSprite.addChild(dragSpriteMini);
			initField(sp, yPos);
			addLayer();
			createDate = new Date();
			lastChangeDate = createDate;
		}
		
		private static var tableIndex:int = 0;
		public static var colorTable:Array = new Array(0xeb6101, 0x007b43, 0x1e50a2, 0x65318e, 0xe6b422, 0x008899,
											 0xa22041, 0xc3d825, 0x0095d9, 0xcc7eb1, 0xfbd26b, 0x44617b,
											 0xf0908d, 0x928c36, 0x83ccd2, 0xa59aca, 0xc38743, 0x478384
											);
		private function initField(sp:Sprite,yPos:int):void {
			var format:TextFormat = new TextFormat();
			format.size = fontSize;//20
			format.leftMargin = 10;
			/* 朱色　常盤色　瑠璃色　本紫　黄金 納戸色
			 * 真紅 若草色 青 菖蒲色 花葉色 紺鼠
			 * 薄紅　鴬色 白群 藤紫 狐色 青碧
			 * */
			if (tableIndex > 17) tableIndex = 0;
			backColor = localTextField.borderColor = colorTable[tableIndex++];
			
			
			localTextField.type = TextFieldType.INPUT;
			localTextField.multiline = true;
			localTextField.defaultTextFormat = format;
			localTextField.width = 735;
			//localTextField.height = 26;
			localTextField.wordWrap = true;
			//localTextField.background = true;
			localTextField.border = true;
			localTextField.x = 50;
			//localTextField.y = yPos;
			localTextField.text = "";
			localTextField.autoSize = TextFieldAutoSize.LEFT;
			
			whiteShape.graphics.beginFill(0xffffff, 0.7);
			whiteShape.graphics.drawRect(localTextField.x, localTextField.y, localTextField.width, localTextField.height);
			whiteShape.graphics.endFill();
			
			backgroundShape.graphics.beginFill(backColor, 0.05);
			backgroundShape.graphics.drawRect(localTextField.x, localTextField.y, localTextField.width, localTextField.height);
			backgroundShape.graphics.endFill();
			
			dragSprite.graphics.beginFill(backColor);
			dragSprite.graphics.drawRoundRect(5, 0, 45, 10, 5, 5);
			dragSprite.graphics.endFill();
			
			dragSpriteMini.graphics.beginFill(backColor);
			dragSpriteMini.graphics.drawRoundRect(15, 0, 35, 10, 5, 5);
			dragSpriteMini.graphics.endFill();
			dragSpriteMini.visible = false;
			
			sp.addChild(localSprite);
			localSprite.y = yPos;
			localTextField.addEventListener(KeyboardEvent.KEY_DOWN, tfKeyDown);
			localTextField.addEventListener(KeyboardEvent.KEY_UP, tfKeyUp);
			localTextField.addEventListener(Event.SCROLL, scroll);
			localTextField.addEventListener(Event.CHANGE, change);
			
			dragSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			dragSprite.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			dragSpriteMini.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownMini);
			dragSpriteMini.addEventListener(MouseEvent.MOUSE_UP, mouseUpMini);
			//dragSprite.addEventListener(MouseEvent.ROLL_OUT, mouseRollOut);
			
		}
		//----------------------drag-------------------------
		public function mouseDown(me:MouseEvent):void {
			trace("dragShape down");
			localSprite.startDrag();
			if(modeLabel == "挿入"){
				var e:DeleteInsertedLayerEvent = new DeleteInsertedLayerEvent("deleteInsertedLayer");
				e.parentIndex = parentLayerIndex;
				e.childIndex = myLayerIndex;
				dispatchEvent(e);
				trace("dile send");
			}
		}
		public function mouseUp(me:MouseEvent):void {
			localSprite.stopDrag();
			if (localSprite.x < 785) localSprite.x = 0;
			else {
				var tmpx:int = (localSprite.x - 785) % 50;
				if (tmpx < 24) localSprite.x -= tmpx;
				else localSprite.x += 50 - tmpx;
			}
			var tmp:int = (localSprite.y) % textHeight;
			if (tmp > 11) localSprite.y += textHeight - tmp;
			else localSprite.y -= tmp;
			if (localSprite.y < 0) localSprite.y = 0;
			if(modeLabel == "挿入"){
				var e:InsertLayerEvent = new InsertLayerEvent("insertLayer");
				e.parentIndex = parentLayerIndex;
				e.childIndex = myLayerIndex;
				dispatchEvent(e);
				trace("ile send");
			}
		}
		public function mouseDownMini(me:MouseEvent):void {
			trace("dragShape down");
			localSprite.startDrag();
			if(modeLabel == "挿入"){
				var e:DeleteInsertedLayerEvent = new DeleteInsertedLayerEvent("deleteInsertedLayer");
				e.parentIndex = parentLayerIndex;
				e.childIndex = myLayerIndex;
				dispatchEvent(e);
				trace("dile send");
			}
		}
		public function mouseUpMini(me:MouseEvent):void {
			localSprite.stopDrag();
			if (localSprite.x < 785) localSprite.x = 0;
			else {
				var tmpx:int = (localSprite.x - 785) % 50;
				if (tmpx < 24) localSprite.x -= tmpx;
				else localSprite.x += 50 - tmpx;
			}
			var tmp:int = (localSprite.y) % textHeight;
			if (tmp > 11) localSprite.y += textHeight - tmp;
			else localSprite.y -= tmp;
			if (localSprite.y < 0) localSprite.y = 0;
			if(modeLabel == "挿入"){
				var e:InsertLayerEvent = new InsertLayerEvent("insertLayer");
				e.parentIndex = parentLayerIndex
				e.childIndex = myLayerIndex;
				dispatchEvent(e);
				trace("ile send");
			}
		}
		//----------------------drag--------------------------
		public function change(e:Event):void {
			backColorDraw();
			lastChangeDate = new Date();
		}
		
		public function backColorDraw():void {
			whiteShape.graphics.clear();
			whiteShape.graphics.beginFill(0xffffff, 0.6);
			whiteShape.graphics.drawRect(localTextField.x, localTextField.y, localTextField.width, localTextField.height);
			whiteShape.graphics.endFill();
			backgroundShape.graphics.clear();
			backgroundShape.graphics.beginFill(backColor, 0.05);
			backgroundShape.graphics.drawRect(localTextField.x, localTextField.y, localTextField.width, localTextField.height);
			backgroundShape.graphics.endFill();
			
		}
		
		public function changeColor(color:uint):void {
			localTextField.borderColor = color;
			backColor = color;
			dragSprite.graphics.clear();
			dragSprite.graphics.beginFill(backColor);
			dragSprite.graphics.drawRoundRect(5, 0, 45, 10, 5, 5);
			dragSprite.graphics.endFill();
			backColorDraw();
		}
		
		public function getLineNum():int {
			/*
			 * 現在のカーソルのある行数を返す
			 */
			var caret:int = localTextField.caretIndex;
			var nowLine:int = localTextField.getFirstCharInParagraph(caret);
			var i:int;
			var rect:Rectangle;
			if (caret == 0) return 0;//一行目だからすぐリターン
			if (caret == localTextField.text.length) return localTextField.numLines - 1;//一番後ろだから直ぐにわかる
			for (i=0;i < localTextField.numLines ;++i ) {
				trace(localTextField.getLineOffset(i));
				if (nowLine == localTextField.getLineOffset(i)) break;
			}
			while (1) {
				if (localTextField.text.substr(caret,1) != "\s" && localTextField.text.substr(caret,1) != "\t") break;
				caret -= 1;
				if (caret == 0) return 0;
			}
			if (localTextField.text.substr(caret, 1) == "\r") {
				if (localTextField.text.substr(caret - 1, 1) == "\r") {
					return i;
				}
				else {
					rect = localTextField.getCharBoundaries(caret - 1);
					trace(rect.y);
					if (rect.y == 2) return 0;
					else i = (rect.y - 2) / textHeight;
				}
			}
			else {
				rect = localTextField.getCharBoundaries(caret);
				trace(rect.y);
				if (rect.y == 2) return 0;
				else i = (rect.y - 2) / textHeight;
			}
			return i;
		}
		public var lineNum:int;
		public var moveFlag:Boolean;
		public function tfKeyDown(ke:KeyboardEvent):void {
			//trace("key down");
			lineNum = localTextField.numLines;
			switch(ke.keyCode) {
				case Keyboard.F8:
					//if (localTextField.text.substr(localTextField.caretIndex,1) == "\r") trace("line end");
					trace(localTextField.getCharBoundaries(localTextField.caretIndex));
					//trace(localTextField.text.length);
					trace("current line:" + getLineNum());
					break;
				case Keyboard.F9:
					trace("parent index " + parentLayerIndex);
					trace("child index " + childLayerIndex);
			}
		}
		
		public function tfKeyUp(ke:KeyboardEvent):void {
			//trace("key up");
			switch(ke.keyCode) {
				case Keyboard.DELETE:
				case Keyboard.BACKSPACE:
					break;
			}
		}
		
		public function scroll(e:Event):void {
			localTextField.scrollV = 1;
			//localTextField.scrollH = 0;
		}
		
		public function addLayer():void {
			//レイヤを追加する時に呼ばれるけど，Initializeと統合してもよさそう
			nowFocusLayerIndex = myLayerIndex = numberOfLayer++;
		}
		
		public function removeLayer():void {
			//多分使わない　減算はあまり考えないし　非表示にすればいいだけだし
			if (nowFocusLayerIndex <= 0 || numberOfLayer <= 1) { trace("Layer is last one. Not removed"); return; }
			--nowFocusLayerIndex;
			--numberOfLayer;
			trace("LayeredArea...\nnumberOfLayer:"+numberOfLayer+"\nnowFocusLayerIndex:"+nowFocusLayerIndex+"\n");
		}		
	}

}