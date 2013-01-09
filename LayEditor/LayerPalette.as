package  
{
	import air.update.descriptors.ConfigurationDescriptor;
	import fl.data.DataProvider;
	import fl.events.SliderEvent;
	import fl.events.ColorPickerEvent;
	import flash.display.*;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.*;
	import fl.controls.*;
	/**
	 * ...
	 * @author MatzYou
	 */
	public class LayerPalette extends Sprite{
		/*
		 * Paletteを作るクラス
		 * 簡易的にはレイヤパレットのみ実装
		 * 後々ツール群を実装する？
		 */
		private var debag:Boolean = true;
		
		public var windowOption:NativeWindowInitOptions;
		public var layerPalette:NativeWindow;
		public var slider:SliderControl;
		public var combox:ComboBox;
		
		public var colorPicker:ColorPicker;
		
		public function LayerPalette(ownerWindow:NativeWindow) {
			/* initialaize */
			windowOption = new NativeWindowInitOptions();
			windowOption.owner = ownerWindow;
			//windowOption.systemChrome = NativeWindowSystemChrome.NONE;
			//windowOption.type = NativeWindowType.LIGHTWEIGHT;
			windowOption.type = NativeWindowType.UTILITY;
			//windowOption.transparent = true;
			//windowOption.resizable = false;
			windowOption.maximizable = false;
			windowOption.minimizable = false;
		}
		
		public var alphaValue:TextField;
		public var sliderValue:int;
		public var layerArea:Sprite;
		public function createLayerPalette():void {
			/* layer palette */
			trace("create layer palette");
			layerPalette = new NativeWindow(windowOption);
			layerPalette.title = "LayerPalette";
			layerPalette.width = 250;
			layerPalette.height = 500;
			layerPalette.activate();
			layerPalette.x = 100;
			layerPalette.y = 400;
			
			layerPalette.stage.scaleMode = StageScaleMode.NO_SCALE;
			layerPalette.stage.align = StageAlign.TOP_LEFT;
			
			layerPalette.stage.addEventListener(Event.RESIZE, resize);
			
			/* パレットをシステムChromeなしでつくるよう
			var stageSprite:Sprite = new Sprite();
			stageSprite.graphics.beginFill(0xe0ebaf);
			stageSprite.graphics.drawRoundRect(0, 0, 250, 500,20,20);
			stageSprite.graphics.endFill();
			layerPalette.stage.addChild(stageSprite);
			*/
			//comboboxの設定
			var cbItem:Array = [ { label:"通常", data:0 }, { label:"挿入", data:1 } ];
			combox = new ComboBox();
			combox.x = 10;
			combox.y = 30;
			combox.setSize(100,20);
			combox.dataProvider = new DataProvider(cbItem);
			combox.addEventListener(Event.CHANGE, onComboboxChange);
			layerPalette.stage.addChild(combox);
			
			//不透明度調整のスプライト　まとめる意味ないかもしれないけど，なんとなくまとめて一気に移動出来るようにする
			var sliderSprite:Sprite = new Sprite();
			layerPalette.stage.addChild(sliderSprite);
			sliderSprite.x = 120;
			sliderSprite.y = 30;
			
			slider = new SliderControl();
			slider.addEventListener("change", sliderMove);
			sliderSprite.addChild(slider);
			
			alphaValue = new TextField();
			
			sliderValue = 100;
			alphaValue.text = "Opacity:"+sliderValue;
			sliderSprite.addChild(alphaValue);
			alphaValue.x = 35;
			alphaValue.y = 20;
			
			//---------------------------------------------------------
			layerArea = new Sprite();
			layerArea.graphics.beginFill(0x999999);
			layerArea.graphics.drawRoundRect(9, -1, 217, 382,7,7);
			layerArea.graphics.endFill();
			layerArea.graphics.beginFill(0xfffaf0);
			layerArea.graphics.drawRoundRect(10, 0, 215, 380,5,5);
			layerArea.graphics.endFill();
			layerPalette.stage.addChild(layerArea);
			layerArea.y = 70;
			
			layerPalette.addEventListener(Event.ACTIVATE, onComplete);
			
			addIconLoader = new Loader();
			addIconLoader.load(addIconURL);
			addIconLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,onIconLoaded);
		}
		//--------------アイコンクリック----------------------
		private var addIconLoader:Loader;
		private var addIconURL:URLRequest = new URLRequest("http://dl.dropbox.com/u/10365076/addIcon.png");
		private function onIconLoaded(e:Event):void {
			layerPalette.stage.addChild(addIconLoader);
			addIconLoader.scaleX = 0.2;
			addIconLoader.scaleY = 0.2;
			addIconLoader.x = 10;
			addIconLoader.y = 5;
			addIconLoader.addEventListener(MouseEvent.CLICK,addLayerClick);
		}
		private function addLayerClick(me:MouseEvent):void {
			var newEvent:Event = new Event("addLayerClick");
			dispatchEvent(newEvent);
		}
		//--------------アイコンクリック----------------------
		
		public function onComboboxChange(e:Event):void {
			//comboboxのイベントの設定
			trace(e.currentTarget.selectedItem.data);
			var sendEvent:ComboBoxEvent = new ComboBoxEvent("modeChange");
			sendEvent.data = e.currentTarget.selectedItem.data;
			sendEvent.label = e.currentTarget.selectedItem.label;
			dispatchEvent(sendEvent);
		}
		
		public function onComplete(e:Event):void {
			var newEvent:Event = new Event("comp");
			dispatchEvent(newEvent);
			layerPalette.removeEventListener(Event.ACTIVATE, onComplete);
		}
		
		
		public function sliderMove(e:SliderbarEvent):void {
			//強引かなぁ　一応sliderValueでこのスライダの値を0から100で取り出せるようにしたけど
			//trace(e.pos);
			sliderValue = e.pos * 100;
			if (sliderValue == 100) alphaValue.text = "Opacity:"+sliderValue;
			else alphaValue.text = "Opacity:  "+sliderValue;
		}
		
		public var containerSpriteArray:Array = new Array();
		public var containerIndex:int = -1;
		public function layerDraw(yPos:int,color:uint=0x000000):void {
			/*
			 * レイヤを増やす毎にこの描画クラス呼ぶようにする
			 * 
			 * */
			containerSpriteArray[++containerIndex] = new Sprite();
			var eyeSprite:Sprite = new Sprite();
			var nameSprite:Sprite = new Sprite();
			var nameText:TextField = new TextField();
			var colorSprite:Sprite = new Sprite();
			layerArea.addChild(containerSpriteArray[containerIndex]);
			containerSpriteArray[containerIndex].addChild(eyeSprite);
			containerSpriteArray[containerIndex].addChild(nameSprite);
			containerSpriteArray[containerIndex].addChild(colorSprite);
			containerSpriteArray[containerIndex].name = ""+containerIndex;
			
			//左側の表示非表示のアイコンのエリア
			eyeSprite.graphics.beginFill(0x222222);//99bb99
			eyeSprite.graphics.drawRoundRect(-1, -1, 27, 27, 7, 7);
			eyeSprite.graphics.endFill();
			eyeSprite.graphics.beginFill(0xf3f3f3);//bbffbb
			eyeSprite.graphics.drawRoundRect(0, 0, 25, 25, 5, 5);
			eyeSprite.graphics.endFill();
			eyeSprite.x = 20;
			
			var eyeShape:Shape = new Shape();
			eyeShape.graphics.beginFill(0xcc3333);
			eyeShape.graphics.drawCircle(12.5,12.5,10);
			eyeShape.graphics.endFill();
			eyeShape.graphics.beginFill(0xdd9999);
			eyeShape.graphics.drawCircle(12.5,12.5,9);
			eyeShape.graphics.endFill();
			eyeSprite.addChild(eyeShape);
			
			eyeSprite.addEventListener(MouseEvent.CLICK, turnVisible);
			//右側の名前とFocus表示のエリア
			nameSprite.graphics.beginFill(0x222222);
			nameSprite.graphics.drawRoundRect(-1, -1, 157, 27, 7, 7);
			nameSprite.graphics.endFill();
			
			nameSprite.graphics.beginFill(0xf3f3f3);
			nameSprite.graphics.drawRoundRect(0, 0, 155, 25, 5, 5);
			nameSprite.graphics.endFill();
			nameSprite.x = 60;
			
			nameSprite.addChild(nameText);
			nameText.text = "Layer " + (containerIndex + 1);
			nameText.type = TextFieldType.INPUT;
			nameText.autoSize = TextFieldAutoSize.LEFT;
			nameText.multiline = false;
			nameText.height = 20;
			nameText.x = 10;
			nameText.y = 5;
			//ハイライト
			var nameShape:Shape = new Shape();
			//nameShape.graphics.beginFill(0xff3333);
			//nameShape.graphics.drawRoundRect(-1, -1, 167, 27, 7, 7);
			//nameShape.graphics.endFill();
			
			nameShape.graphics.beginFill(0xffdcdc);
			nameShape.graphics.drawRoundRect(0, 0, 155, 25, 5, 5);
			nameShape.graphics.endFill();
			nameSprite.addChildAt(nameShape,0);
			
			nameSprite.addEventListener(MouseEvent.CLICK, selectLayer);
			
			colorSprite.graphics.beginFill(0x222222);
			colorSprite.graphics.drawRoundRect( -1, -1, 9, 27, 5, 5);
			colorSprite.graphics.endFill();
			colorSprite.graphics.beginFill(color);
			colorSprite.graphics.drawRoundRect( 0, 0, 7, 25, 5, 5);
			colorSprite.graphics.endFill();
			
			colorSprite.x = 49;
			colorSprite.doubleClickEnabled = true;
			colorSprite.addEventListener(MouseEvent.DOUBLE_CLICK, colorSelect);
			
			colorPicker = new ColorPicker();
			colorSprite.addChild(colorPicker);
			colorPicker.x = -15;
			colorPicker.visible = false;
			colorPicker.colors = LayeredArea.colorTable;
			colorPicker.selectedColor = color;
			colorPicker.setStyle("columnCount", 6);
			colorPicker.addEventListener(ColorPickerEvent.CHANGE, colorPicked);
			containerSpriteArray[containerIndex].y = -25;
			moveLayer(containerIndex);
			trace("LayperPalette...\nnowFocusLayerIndex:" + LayeredArea.nowFocusLayerIndex);
			
			focus();
		}
		
		public function colorSelect(me:MouseEvent):void {
			trace("color sprite double click:"+layerArea.getChildIndex(me.target.parent));
			//ここで色を選択出来る何かを用意する
			me.target.getChildAt(0).open();
		}
		public function colorPicked(ce:ColorPickerEvent):void {
			colorChange(layerArea.getChildIndex(ce.target.parent.parent),ce.target.selectedColor);
		}
		
		public function colorChange(i:int,color:uint):void {
			var tmp:Sprite = containerSpriteArray[i].getChildAt(2) as Sprite;
			tmp.graphics.beginFill(color);
			tmp.graphics.drawRoundRect( 0, 0, 7, 25, 5, 5);
			tmp.graphics.endFill();
			var e:ColorEvent = new ColorEvent("paletteColorChange");
			e.color = color;
			e.index = i;
			dispatchEvent(e);
		}
		
		public function focus():void {
			for (var i:int = 0; i < containerSpriteArray.length; ++i){
				containerSpriteArray[i].getChildAt(1).getChildAt(0).alpha = 0;
			}
			containerSpriteArray[LayeredArea.nowFocusLayerIndex].getChildAt(1).getChildAt(0).alpha = 1;
		}
		
		private function selectLayer(me:MouseEvent):void {
			trace("nameSprite clicked");
			if (me.target as TextField) return;
			var obj:Sprite = me.target as Sprite;
			//クリックしたレイヤ（スプライト）が何番目なのかを調べる　スプライトの親の親（containerSpriteArray）からgetChildIndex(クリックしたスプライトの親)
			var index:int = obj.parent.parent.getChildIndex(obj.parent);
			trace(index);
			containerSpriteArray[LayeredArea.nowFocusLayerIndex].getChildAt(1).getChildAt(0).alpha = 0;
			obj.getChildAt(0).alpha = 1;
			LayeredArea.nowFocusLayerIndex = index;
			var newEvent:Event = new Event("clickSelect");
			dispatchEvent(newEvent);
		}
		
		private function turnVisible(me:MouseEvent):void {
			trace("clicked");
			var obj:Object = me.target.getChildAt(0);
			obj.visible = obj.visible?false:true;
			var newEvent:TurnVisibleEvent = new TurnVisibleEvent("turnVisible");
			newEvent.index = obj.parent.parent.parent.getChildIndex(obj.parent.parent);
			dispatchEvent(newEvent);
		}
		
		private function moveLayer(index:int):void {
			/**
			 * 追加したり消したりしたときにレイヤのスプライトを移動する
			 */
			trace(index);
			for (; index >= 0; --index) {
				containerSpriteArray[index].y += 30;
			}
			
		}
		
		public function deleteLayer(target:int):void {
			/*
			 * フォーカスしているレイヤを削除する
			 * containerの中身を整理する
			 * spliceで間は詰まる
			 * 
			 * */
			moveDel(target);
			layerArea.removeChildAt(target);
			containerSpriteArray.splice(target, 1);
			containerIndex--;
		}
		
		private function moveDel(index:int):void {
			trace(index);
			for (var i:int = 0; i < index; ++i) {
				containerSpriteArray[i].y -= 30;	
			}
		}
		
		private var areaHeight:int;
		private function resize(e:Event):void {
			areaHeight = layerPalette.stage.stageHeight - 85;
			layerArea.graphics.clear();
			layerArea.graphics.beginFill(0x999999);
			layerArea.graphics.drawRoundRect(9, -1, 217, areaHeight+2,7,7);
			layerArea.graphics.endFill();
			layerArea.graphics.beginFill(0xfffaf0);
			layerArea.graphics.drawRoundRect(10, 0, 215, areaHeight,5,5);
			layerArea.graphics.endFill();
		}
		
	}
	
}

