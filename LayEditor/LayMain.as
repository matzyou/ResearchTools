package 
{
	import adobe.utils.CustomActions;
	import fl.controls.*;
	import fl.events.ScrollEvent;
	import flash.display.*;
	import flash.desktop.*;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.sampler.NewObjectSample;
	import flash.text.*;
	import flash.net.*;
	import flash.events.*;
	import flash.filesystem.*;
	import flash.ui.*;

	/**
	 * ...
	 * @author MatzYou
	 */
	public class LayMain extends Sprite {
		
		private var debag:Boolean = true;
		
		private var mainWinwod:NativeWindow;
		private var eyeSelectWindow:EyeSelectWindow;
		private var layerPalette:LayerPalette;
		private var baseSprite:Sprite;
		private var tf:TextField;
		
		private var isChangeFlag:Boolean;
		
		//LayeredAreaクラスの配列で管理するか
		private var textLayerArray:Array;
		private var layerYPos:int = 5;
		
		private var slider:SliderControl;
		private var HScrollBar:ScrollBar;//水平
		private var HScrollDistance:Number = 0;
		private var VScrollBar:ScrollBar;//垂直
		private var VScrollDistance:Number= 0;
		
		public function LayMain():void {
			createNativeMenus();
			init();
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			stage.addEventListener(MouseEvent.CLICK, mouseClick);
			stage.nativeWindow.addEventListener(Event.CLOSING, windowClosing);
			
			//動画撮影用
			///*
			mainWinwod.x = 320;
			mainWinwod.y = 180;
			layerPalette.layerPalette.x = 1320;
			layerPalette.layerPalette.y = 370;
			//*/
		}
		
		private function init():void {
			/* initialize */
			trace("initialize called");
			trace(NativeProcess.isSupported);
			
			mainWinwod = stage.nativeWindow;
			mainWinwod.activate();
			
			eyeSelectWindow = new EyeSelectWindow(mainWinwod);
			eyeSelectWindow.addEventListener("eyePoint", getEyePoint);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, stageResized);
			stage.align = StageAlign.TOP_LEFT;
			
			baseSprite = new Sprite();
			addChild(baseSprite);
			baseSprite.addEventListener(MouseEvent.CLICK, baseClick);
			
			layerPalette = new LayerPalette(mainWinwod);
			layerPalette.createLayerPalette();
			layerPalette.slider.addEventListener("change", sliderMoved);
			layerPalette.addEventListener("comp", paletteCreateComplete);
			layerPalette.addEventListener("turnVisible", turnVisible);
			layerPalette.addEventListener("clickSelect", clickSelect);
			layerPalette.addEventListener("modeChange", modeChange);
			layerPalette.addEventListener("paletteColorChange", paletteColorChange);
			layerPalette.addEventListener("addLayerClick", paletteAddLayerClick);
			VScrollBar = new ScrollBar();
			addChild(VScrollBar);
			VScrollBar.x = stage.stageWidth - VScrollBar.width;
			VScrollBar.height = stage.stageHeight;
			
			VScrollBar.minScrollPosition = 0;
			VScrollBar.maxScrollPosition = 200;
			VScrollBar.addEventListener(ScrollEvent.SCROLL, vscrollEvent);
			
			HScrollBar = new ScrollBar();
			HScrollBar.direction = ScrollBarDirection.HORIZONTAL;
			addChild(HScrollBar);
			HScrollBar.y = stage.stageHeight - HScrollBar.height;
			HScrollBar.width = stage.stageWidth - VScrollBar.width;
			
			HScrollBar.minScrollPosition = 0;
			HScrollBar.maxScrollPosition = 200;
			HScrollBar.addEventListener(ScrollEvent.SCROLL, hscrollEvent);
			
			textLayerArray = new Array();
			addLayer();
			
		}
		
		private function mouseClick(me:MouseEvent):void {
			var p:Point = new Point(me.stageX, me.stageY);
			trace(p);
			//trace(getObjectsUnderPoint(p));
		}
		
		private function paletteColorChange(e:ColorEvent):void {
			trace("palette color change");
			textLayerArray[e.index].changeColor(e.color);
			mainWinwod.activate();
		}
		
		private function searchParent(targetIndex:int):void {
			trace("searchParent  targetIndex:"+targetIndex);
			var p:Point = new Point(textLayerArray[targetIndex].localSprite.x+55+baseSprite.x, textLayerArray[targetIndex].localSprite.y+5+baseSprite.y);
			var obj:Array = getObjectsUnderPoint(p);
			trace(p + " : " +obj);
			var tmp:Object = textLayerArray[targetIndex].localTextField;
			var i:int;
			for (i = 0; i < obj.length; i++) {
				if (tmp == obj[i]) { trace("hit : " + i ); break; }
			}
			if (i < 3) return; //重なってたら必ずiは５以上になる　２だと下にはフィールドはない
			textLayerArray[targetIndex].parentLayerIndex = baseSprite.getChildIndex(obj[i - 3].parent);
			trace("searched parent:" + textLayerArray[targetIndex].parentLayerIndex);
			textLayerArray[textLayerArray[targetIndex].parentLayerIndex].childLayerIndex = targetIndex;
		}
		
		private function modeChange(cbe:ComboBoxEvent):void {
			trace("combo box item changed\nlabel:" + cbe.label + " data:" + cbe.data);
			if (textLayerArray[LayeredArea.nowFocusLayerIndex].modeData == cbe.data) return ;
			textLayerArray[LayeredArea.nowFocusLayerIndex].modeLabel = cbe.label;
			textLayerArray[LayeredArea.nowFocusLayerIndex].modeData = cbe.data;
			
			//ここまで来るということは前の状態から変化したということ　通常→挿入あるいはその逆の変化があった
			switch(cbe.label) {
				case "通常":
					if (textLayerArray[LayeredArea.nowFocusLayerIndex].localSprite.visible) {
						if (textLayerArray[LayeredArea.nowFocusLayerIndex].parentLayerIndex == -1) break;
						textLayerArray[LayeredArea.nowFocusLayerIndex].dragSprite.visible = true;
						textLayerArray[LayeredArea.nowFocusLayerIndex].dragSpriteMini.visible = false;
						deleteInsertedLayer(textLayerArray[LayeredArea.nowFocusLayerIndex].parentLayerIndex, LayeredArea.nowFocusLayerIndex);
						textLayerArray[textLayerArray[LayeredArea.nowFocusLayerIndex].parentLayerIndex].childLayerIndex = -1;
						textLayerArray[LayeredArea.nowFocusLayerIndex].parentLayerIndex = -1;
					}
					break;
				case "挿入":
					if (textLayerArray[LayeredArea.nowFocusLayerIndex].localSprite.visible) {
						searchParent(LayeredArea.nowFocusLayerIndex);
						if (textLayerArray[LayeredArea.nowFocusLayerIndex].parentLayerIndex != -1){
							textLayerArray[LayeredArea.nowFocusLayerIndex].dragSpriteMini.visible = true;
							textLayerArray[LayeredArea.nowFocusLayerIndex].dragSprite.visible = false;
						}
						insertLayer(textLayerArray[LayeredArea.nowFocusLayerIndex].parentLayerIndex, LayeredArea.nowFocusLayerIndex);
					}
					break;
			}
		}
		
		private function insertLayer(parentIndex:int,childIndex:int):void {
			//parentに設定されているレイヤに組み込まてれいるように見せかける focus中のレイヤしかモード変更できないはず
			trace("insert layer call: parent:"+parentIndex+" child:"+childIndex);
			if (parentIndex == -1) return ;
			var target:LayeredArea = textLayerArray[parentIndex];
			var localY:int = textLayerArray[childIndex].localSprite.y - textLayerArray[parentIndex].localSprite.y;
			if (localY) localY /= LayeredArea.textHeight;
			//ここまでで親のどこの行に入るのかがわかる 0から始まるインデックスがlocalYにはいってる
			trace(localY);
			//ここで範囲外かを事前に調べるか，もしくはTryCatch的な何かでやるか　範囲外ならcaret=0にすればいいだけ
			try{
				var caret:int = target.localTextField.getLineOffset(localY); //ここで範囲外だとエラーで落ちる
				var str:String = "";
				for (var i:int = 0; i < textLayerArray[childIndex].localTextField.numLines; i++) str += "\n";
				target.localTextField.replaceText(caret, caret, str);
			}catch(e:Error) {
				trace("Error catch");
			}
			target.backColorDraw();
		}
		
		private function deleteInsertedLayer(parentIndex:int, childIndex:int):void {
			trace("delete insered layer call");
			if (parentIndex == -1) return ;
			var target:LayeredArea = textLayerArray[parentIndex];
			var localY:int = textLayerArray[childIndex].localSprite.y - textLayerArray[parentIndex].localSprite.y;
			if (localY) localY /= LayeredArea.textHeight;
			//ここまでで親のどこの行に入るのかがわかる 0から始まるインデックスがlocalYにはいってる
			//こっちでも死ぬから例外処理を
			try{
				var beginCaret:int = target.localTextField.getLineOffset(localY);
				var endCaret:int = target.localTextField.getLineOffset(localY + textLayerArray[childIndex].localTextField.numLines);
				target.localTextField.replaceText(beginCaret, endCaret, "");
			}catch (e:Error) {
				trace("Error catch");
			}
			target.backColorDraw();
		}
		
		
		private function baseClick(me:MouseEvent):void {
			trace("base click");
			if (stage.focus == null) stage.focus = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			LayeredArea.nowFocusLayerIndex = baseSprite.getChildIndex(stage.focus.parent);
			//layerPalette.focus();
			paletteSet();
			trace(layerPalette.containerSpriteArray[LayeredArea.nowFocusLayerIndex].getChildAt(1).getChildAt(1).text);
		}
		
		private function clickSelect(e:Event):void {
			trace("click select");
			//LayerPaletteのOpacityとスライダーの値を変える処理が必要 イベント出さないためにもスライダーの中身をいじる
			paletteSet();
			stage.focus = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			mainWinwod.activate();
		}
		
		private function paletteSet():void {
			//レイヤの状態を復元する　スライダーの値とか合成モードの値とか　パレットの表示を直す
			var tmp:int = textLayerArray[LayeredArea.nowFocusLayerIndex].opacity
			layerPalette.slider.barBtn.x = textLayerArray[LayeredArea.nowFocusLayerIndex].sliderX * 80.0;
			if ( tmp == 100) layerPalette.alphaValue.text = "Opacity:"+tmp;
			else layerPalette.alphaValue.text = "Opacity:  "+tmp;
			trace(textLayerArray[LayeredArea.nowFocusLayerIndex].modeData)
			layerPalette.combox.selectedIndex = textLayerArray[LayeredArea.nowFocusLayerIndex].modeData;
			layerPalette.focus();
			focusBorderSet();
		}
		
		private function focusBorderSet():void {
			for (var i:int; i < textLayerArray.length; i++) {
				textLayerArray[i].localTextField.border = false;
			}
			textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField.border = true;
		}
		
		private function turnVisible(e:TurnVisibleEvent):void {
			trace("turn LayMain");
			trace(e.index);
			trace(textLayerArray[e.index].localSprite.visible);
			textLayerArray[e.index].localSprite.visible = textLayerArray[e.index].localSprite.visible ? false : true;
			if (textLayerArray[e.index].modeLabel=="挿入") {
				if (textLayerArray[e.index].localSprite.visible) {
					insertLayer(textLayerArray[e.index].parentLayerIndex, e.index);
				}else {
					deleteInsertedLayer(textLayerArray[e.index].parentLayerIndex, e.index);
				}
			}
			stage.focus = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			mainWinwod.activate();
		}
		
		private var preVPos:Number = 0;
		private var preHPos:Number = 0;
		private function vscrollEvent(se:ScrollEvent):void {
			// 縦スクロール
			trace(se.position);
			baseSprite.y = -se.position * 50;
			VScrollDistance += Math.abs(se.position - preVPos) * 50;
			preVPos = se.position;
		}
		private function hscrollEvent(se:ScrollEvent):void {
			// 横スクロール
			//trace(se.position);
			baseSprite.x = -se.position * 50;
			HScrollDistance += Math.abs(se.position - preHPos) * 50;
			preHPos = se.position;
		}
		
		private function sliderMoved(e:SliderbarEvent):void {
			/*
			 * 現在選択中，フォーカスの当たっているレイヤのみ
			 * スライダを動かすことで不透明度を調整する
			 * 
			trace("sliderMoved");
			trace(LayeredArea.nowFocusLayerIndex);
			trace(textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField.text);
			trace(e.pos);
			*/
			textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField.alpha = e.pos;
			textLayerArray[LayeredArea.nowFocusLayerIndex].whiteShape.alpha = e.pos;
			textLayerArray[LayeredArea.nowFocusLayerIndex].opacity = (int)(e.pos * 100);
			textLayerArray[LayeredArea.nowFocusLayerIndex].sliderX = e.pos;
		}
		
		
		private function addLayer():void {
			/*
			 * メインの中でレイヤを増やす時にはこれを呼ぶ
			 * */
			if(LayeredArea.numberOfLayer == 0) textLayerArray[LayeredArea.numberOfLayer] = new LayeredArea(baseSprite);
			else {
				//こっちにはいるなら，既にレイヤがあるのでテキストが選択されてる可能性がある
				var oldFocusLayerIndex:int = LayeredArea.nowFocusLayerIndex;
				textLayerArray[LayeredArea.numberOfLayer] = new LayeredArea(baseSprite, textLayerArray[LayeredArea.nowFocusLayerIndex].localSprite.y + textLayerArray[LayeredArea.nowFocusLayerIndex].getLineNum() * LayeredArea.textHeight);
				textSet(oldFocusLayerIndex); //これで選択しながら新しくレイヤを作ったら　選択中のテキストを切って新しいレイヤに貼る
			}
			layerPalette.layerDraw(layerYPos,textLayerArray[LayeredArea.nowFocusLayerIndex].backColor);
			layerYPos += 30;
			if (debag) trace("LayMain...\ntextLayerArray.length:" + textLayerArray.length + 
							 "\nnowFocusLayerIndex:" + LayeredArea.nowFocusLayerIndex + "\n");
			
			addChild(textLayerArray[LayeredArea.nowFocusLayerIndex]);
			stage.focus = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			textLayerArray[LayeredArea.nowFocusLayerIndex].addEventListener("deleteInsertedLayer", function deleteInsertedLayerFromLayeredArea(e:DeleteInsertedLayerEvent):void {
				deleteInsertedLayer(e.parentIndex, e.childIndex);
			});
			textLayerArray[LayeredArea.nowFocusLayerIndex].addEventListener("insertLayer", function insertLayerFromLayeredArea(e:InsertLayerEvent):void {
				trace("ile get");
				insertLayer(e.parentIndex, e.childIndex);
			});
		}
		
		private var copyFlag:Boolean = false;
		private function textSet(oldFocusLayerIndex:int):void {
			//BeginとEndが同じインデックスならなにも選択していない　はず
			var begin:int = textLayerArray[oldFocusLayerIndex].localTextField.selectionBeginIndex;
			var end:int = textLayerArray[oldFocusLayerIndex].localTextField.selectionEndIndex;
			trace("Begin:"+begin);
			trace("End:" + end);
			
			if (begin == end) return;
			
			var tmp:String = textLayerArray[oldFocusLayerIndex].localTextField.text.slice(begin, end);
			trace(tmp);
			if(!copyFlag) textLayerArray[oldFocusLayerIndex].localTextField.replaceSelectedText("");
			textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField.text = tmp;
			textLayerArray[oldFocusLayerIndex].backColorDraw();
			textLayerArray[LayeredArea.nowFocusLayerIndex].backColorDraw();
			copyFlag = false;
		}
		
		private function textSelectCheck(Index:int):Boolean {
			//テキストが選択状態にあるかどうかのチェック
			var begin:int = textLayerArray[Index].localTextField.selectionBeginIndex;
			var end:int = textLayerArray[Index].localTextField.selectionEndIndex;
			trace("Begin:"+begin);
			trace("End:" + end);
			if (begin == end) return false;
			return true;
		}
		
		private function fusionLayer():void {
			/* 唯一の減算的処理
			 * レイヤを統合する　上のレイヤをすぐ下のレイヤに統合
			 * 基本的にinsertと同じ動きをする
			 * けど現在見ている状態に統合
			 * 統合する側のレイヤのテキストを全選択してカット
			 * 統合される側のレイヤにペースト　基本的に上書き
			 * その行の先頭のインデックスから統合する側の行数だけ選択した状態にしてreplace
			 * で最後に上にあったレイヤを削除　初めて削除が必要になったな
			 * */
			trace("fusionLayer called ---------");
			var p:Point = new Point(textLayerArray[LayeredArea.nowFocusLayerIndex].localSprite.x+55+baseSprite.x, textLayerArray[LayeredArea.nowFocusLayerIndex].localSprite.y+5+baseSprite.y);
			var obj:Array = getObjectsUnderPoint(p);
			trace(p + " : " +obj);
			var tmp:Object = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			var i:int;
			for (i = 0; i < obj.length; i++) {
				if (tmp == obj[i]) { trace("hit : " + i ); break; }
			}
			if (i < 3) return; //重なってたら必ずiは５以上になる　２だと下にはフィールドはない
			trace("searched fusionLayer:" + obj[i-3].text);
			//ここで上のレイヤのテキストを全選択
			var str:String = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField.text.slice();
			//下のレイヤのはじめの部分と終わりの部分を探す処理が必要
			str += "\r";
			trace("str:"+str);
			trace(obj[i-3].text);
			
			var localY:int = textLayerArray[LayeredArea.nowFocusLayerIndex].localSprite.y - textLayerArray[baseSprite.getChildIndex(obj[i-3].parent)].localSprite.y;
			if (localY) localY /= LayeredArea.textHeight;
			//ここまでで親のどこの行に入るのかがわかる 0から始まるインデックスがlocalYにはいってる
			trace(localY);
			//ここで範囲外かを事前に調べるか，もしくはTryCatch的な何かでやるか　範囲外ならcaret=0にすればいいだけ
			try{
				var caret:int = obj[i-3].getLineOffset(localY); //ここで範囲外だとエラーで落ちる
				obj[i-3].replaceText(caret, caret, str);
			}catch(e:Error) {
				trace("Error catch");
			}
			
			//最後にレイヤを消す処理　面倒そうだなぁ
			baseSprite.removeChildAt(LayeredArea.nowFocusLayerIndex);
			layerPalette.deleteLayer(LayeredArea.nowFocusLayerIndex);
			textLayerArray.splice(LayeredArea.nowFocusLayerIndex, 1);
			textLayerArray[0].removeLayer();
			
			LayeredArea.nowFocusLayerIndex = baseSprite.getChildIndex(obj[i - 3].parent);
			paletteSet();
			stage.focus = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			mainWinwod.activate();
		}
		
		//---------------------------------key event------------------
		private function keyUp(ke:KeyboardEvent):void {
			switch(ke.keyCode) {
				case Keyboard.F5: break;
			}
		}
		private function keyDown(ke:KeyboardEvent):void {
			//isChangeFlag = true;//処理ができたら戻す
			switch(ke.keyCode) {
			case Keyboard.F6: trace("(" + mainWinwod.x + "," + mainWinwod.y + ")(" + layerPalette.layerPalette.x + "," + layerPalette.layerPalette.y + ")"); break;
			case Keyboard.F5: if (eyeSelectWindow.t.running) eyeSelectWindow.t.stop(); else eyeSelectWindow.t.start(); break;
			case Keyboard.F1: if (ke.shiftKey) copyFlag = true; addLayer(); paletteSet(); break;
			case Keyboard.F2: 
				if (LayeredArea.nowFocusLayerIndex < textLayerArray.length - 1) { stage.focus = textLayerArray[++LayeredArea.nowFocusLayerIndex].localTextField; }
				layerPalette.focus();
				paletteSet();
				break;
			case Keyboard.F3:
				if (LayeredArea.nowFocusLayerIndex > 0) {stage.focus = textLayerArray[--LayeredArea.nowFocusLayerIndex].localTextField;}
				layerPalette.focus();
				paletteSet();
				break;
			//shortcut key
			//カットと同じ機能　但しレイヤを追加する
			case Keyboard.X: if (ke.ctrlKey&&ke.shiftKey) { copyFlag = false; if(textSelectCheck(LayeredArea.nowFocusLayerIndex)) addLayer(); paletteSet(); ke.preventDefault(); }; break;
			//コピーと同じ機能　但しレイヤを追加する
			case Keyboard.C: if (ke.ctrlKey&&ke.shiftKey) { copyFlag = true; if(textSelectCheck(LayeredArea.nowFocusLayerIndex)) addLayer(); paletteSet(); ke.preventDefault(); }; break;
			//ペーストと同じ機能　レイヤを重ねた状態からその見た目になるようにレイヤを統合する
			case Keyboard.V: if (ke.ctrlKey&&ke.shiftKey) { fusionLayer(); ke.preventDefault();} break;
			//レイヤの追加
			case Keyboard.L: if (ke.ctrlKey) { if (ke.shiftKey) copyFlag = true; addLayer(); paletteSet(); ke.preventDefault(); }; break;
			//レイヤの統合
			
			//保存
			case Keyboard.S: if (ke.ctrlKey) { saveAs(); ke.preventDefault(); }; break;
			//開く
			case Keyboard.O: if (ke.ctrlKey) { openData(); ke.preventDefault(); }; break;
			case Keyboard.ENTER:
				if (ke.ctrlKey && ke.shiftKey && !ke.altKey) {
					//ctrl shift enter は上のレイヤへ登る
					trace("ctrl + shift + enter");
					if (LayeredArea.nowFocusLayerIndex < textLayerArray.length - 1) {
						stage.focus = textLayerArray[++LayeredArea.nowFocusLayerIndex].localTextField;
						layerPalette.focus();
						paletteSet();
						break;
					}
				}
				else if (ke.ctrlKey && !ke.shiftKey && !ke.altKey) {
					//ctrl enter　は下のレイヤへ潜る
					trace("ctrl + enter");
					if (LayeredArea.nowFocusLayerIndex > 0) {
						stage.focus = textLayerArray[--LayeredArea.nowFocusLayerIndex].localTextField;
						layerPalette.focus();
						paletteSet();
						ke.preventDefault();
						break;
					}
				}
				break;
			}
		}
		
		//-----------------↓menu↓----------------------------------
		
		public var XMLData:XMLFile = new XMLFile();
		
		private function createNativeMenus():void {
			//menuを作る
			var nativeMenu:NativeMenu = new NativeMenu();
			//一応MacとWindowsの設定　使わないけど
			if (NativeApplication.supportsMenu) { NativeApplication.nativeApplication.menu = nativeMenu; }
			else if (NativeWindow.supportsMenu) { stage.nativeWindow.menu = nativeMenu; }
			
			//File Menu
			var fileMenu:NativeMenuItem = nativeMenu.addSubmenu(new NativeMenu(), "File");
			var openSubMenu:NativeMenuItem = fileMenu.submenu.addItem(new NativeMenuItem("Open"));
			openSubMenu.addEventListener(Event.SELECT, openSelected);
			var saveSubMenu:NativeMenuItem = fileMenu.submenu.addItem(new NativeMenuItem("Save"));
			saveSubMenu.addEventListener(Event.SELECT, saveSelected);
			var sep:NativeMenuItem = fileMenu.submenu.addItem(new NativeMenuItem("",true));//セパレータ
			var exitSubMenu:NativeMenuItem = fileMenu.submenu.addItem(new NativeMenuItem("Exit"));
			exitSubMenu.addEventListener(Event.SELECT, exitSelected);
			
			var editMenu:NativeMenuItem = nativeMenu.addSubmenu(new NativeMenu(), "Edit");
			var addLayerMenu:NativeMenuItem = editMenu.submenu.addItem(new NativeMenuItem("Add Layer"));
			addLayerMenu.addEventListener(Event.SELECT, addLayerMenuSelected);
			var toolsMenu:NativeMenuItem = nativeMenu.addSubmenu(new NativeMenu(), "Tools");
			
		}
		
		private function addLayerMenuSelected(e:Event):void {addLayer();paletteSet();}
		
		private function openSelected(e:Event):void {openData();}
		
		private function openData():void {
			/*
			 * XMLFileのopenを呼び出す
			 * */
			XMLData.addEventListener("loadComplete", onComplete);
			XMLData.openFile();
		}
		
		private function onComplete(e:FileEvent):void {
			//ファイルのロードが終わったら解析して表示
			trace(XMLData.xml);
			mainWinwod.title = e.fileName + " - LayEditor";
			var tmp:String;
			var id:int;
			
			var layerData:XML = XMLData.xml;
			HScrollDistance = layerData.@hScroll;
			VScrollDistance = layerData.@vScroll;
			trace("--"+layerData.@vScroll);
			for each (var layer:XML in XMLData.xml.layer) {
				tmp = layer.text;
				id = layer.@id;
				//trace("id:"+id+" start");
				if (id != 0) addLayer();//最初のレイヤは既にある
				textLayerArray[id].localSprite.y = layer.@setLine * LayeredArea.textHeight;
				textLayerArray[id].modeLabel = layer.@modeLabel;
				textLayerArray[id].modeData = layer.@modeData;
				textLayerArray[id].opacity = layer.@opacity;
				textLayerArray[id].localTextField.alpha = textLayerArray[id].sliderX = textLayerArray[id].whiteShape.alpha = layer.@sliderX;
				textLayerArray[id].localTextField.borderColor = textLayerArray[id].backColor = layer.@backColor;
				textLayerArray[id].localSprite.visible = layerPalette.containerSpriteArray[LayeredArea.nowFocusLayerIndex].getChildAt(0).getChildAt(0).visible = layer.@isVisible == "true"?true:false;
				textLayerArray[id].localTextField.text = tmp.replace(/\\n/g, "\n");
				textLayerArray[id].changeColor(layer.@backColor);
				paletteSet();
				layerPalette.containerSpriteArray[id].getChildAt(1).getChildAt(1).text = layer.@name;
				textLayerArray[id].localSprite.x = layer.@x;
				textLayerArray[id].backColorDraw();
				textLayerArray[id].parentLayerIndex = layer.@parentLayerIndex;
				textLayerArray[id].childLayerIndex = layer.@childLayerIndex;
				var d:Date = new Date(String(layer.@createDate));
				if (d.fullYear > 2000) textLayerArray[id].createDate = d;
				d = new Date(String(layer.@lastChangeDate));
				if (d.fullYear > 2000) textLayerArray[id].lastChangeDate = d;
				layerPalette.colorChange(id, layer.@backColor);
				//trace("id:" + id + " done");
			}
			XMLData.removeEventListener(Event.COMPLETE,onComplete);
		}
		
		private function saveSelected(e:Event):void {saveAs();}
		
		private function saveAs():void {
			/*
			 * XMLFileのsaveを呼び出す
			 * */
			var ld:XML =
				<layerData>
				</layerData>;
			ld.@hScroll = HScrollDistance;
			ld.@vScroll = VScrollDistance;			
			var tmp:XML;
			var text:String;
			var id:int;
			for (var i:int = 0; i < textLayerArray.length ; i++ ) {
				tmp = new XML();
				tmp =
					<layer>
					</layer>;
				tmp.@id = i;
				//tmp.@numLines = textLayerArray[i].localTextField.numLines;
				tmp.@setLine = (textLayerArray[i].localSprite.y + LayeredArea.textHeight) / LayeredArea.textHeight - 1;
				tmp.@x = textLayerArray[i].localSprite.x;
				tmp.@modeLabel = textLayerArray[i].modeLabel;
				tmp.@modeData = textLayerArray[i].modeData;
				tmp.@opacity = textLayerArray[i].opacity;
				tmp.@sliderX = textLayerArray[i].sliderX;
				tmp.@backColor = textLayerArray[i].backColor;
				tmp.@isVisible = textLayerArray[i].localSprite.visible;
				tmp.@parentLayerIndex = textLayerArray[i].parentLayerIndex;
				tmp.@childLayerIndex = textLayerArray[i].childLayerIndex;
				tmp.@name = layerPalette.containerSpriteArray[i].getChildAt(1).getChildAt(1).text;
				tmp.@createDate = textLayerArray[i].createDate;
				tmp.@lastChangeDate = textLayerArray[i].lastChangeDate;
				tmp.text = textLayerArray[i].localTextField.text.replace(/\n/g,File.lineEnding);
				ld = ld.appendChild(tmp);
			}
			XMLData.saveFile(ld);
			XMLData.addEventListener("saveComplete", onSaveComp);
		}
		private function onSaveComp(e:FileEvent):void { mainWinwod.title = e.fileName + " - LayEditor"; }
		
		private function exitSelected(e:Event):void {stage.nativeWindow.close();}
		//---------------------------↑menu↑------------------------
		
		//------------------------↓あんまり触らなそうなメソッド↓-------------------
		private function paletteAddLayerClick(e:Event):void {
			addLayer();
			stage.focus = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			mainWinwod.activate();
		}
		private function exitFunction():void {
			//未保存なら　そのまま終了していいかどうかを聴くあれ
			if (isChangeFlag) {
				trace("changing");
			}
			else {
				mainWinwod.close();
			}
		}
		
		private function windowClosing(e:Event):void { e.preventDefault(); exitFunction(); }
		
		private function paletteCreateComplete(e:Event):void {
			trace("comp");
			//一度mainWindowをアクティブにしないとFocusだけが移動してパレットがアクティブになってる　すぐには書けない
			mainWinwod.activate();
			stage.focus = textLayerArray[LayeredArea.nowFocusLayerIndex].localTextField;
			removeEventListener("comp", paletteCreateComplete);
		}
		
		private function stageResized(e:Event):void {
			//stageのリサイズ処理
			VScrollBar.x = stage.stageWidth - VScrollBar.width;
			VScrollBar.height = stage.stageHeight;
			HScrollBar.y = stage.stageHeight - HScrollBar.height;
			HScrollBar.width = stage.stageWidth - VScrollBar.width;
			for (var i:int = 0; i < textLayerArray.length; ++i ) {
				//textLayerArray[i].localTextField.width = stage.stageWidth - 50 - VScrollBar.width;
				textLayerArray[i].backColorDraw();
			}
		}
		//▼=========== EYE TRACKING FUNCTION ==========================▼
		private var eyeFlag:Boolean;
		private var oldEyeFocus:Object = new Object();
		private var eyeCount:int = 0;
		private function getEyePoint(e:EyePointEvent):void {
			var localPoint:Point = e.pt;
			var resetCount:int = 0;
			var cntFlag:Boolean = false;
			localPoint.x -= mainWinwod.x - 10;
			localPoint.y -= mainWinwod.y - 30;
			var tmp:Array = getObjectsUnderPoint(localPoint);
			if (oldEyeFocus == tmp[tmp.length - 1]) {
				if (eyeCount < 5) eyeCount += 1;
				//cntFlag = true;
				trace("eyeCount up");
			}
			else {
				oldEyeFocus = tmp[tmp.length - 1];
				if (eyeCount > 0) eyeCount -= 5;
				//cntFlag = false;
				//resetCount++;
				trace("eyeCount down");
				//if (resetCount > 3) { eyeCount = resetCount = 0; trace("eyeCount Reset"); }
			}
			trace(localPoint);
			if (eyeCount > 2) {
				var ob:Object = tmp[tmp.length - 1];
				if (ob is TextField) {
					if (stage.focus != tmp[tmp.length - 1]) {
						stage.focus = tmp[tmp.length - 1];
						LayeredArea.nowFocusLayerIndex = baseSprite.getChildIndex(stage.focus.parent);
						layerPalette.focus();
						paletteSet();
						trace("focus change by Eye Track!");
					}
				}
			}
		}
		//▲=========== EYE TRACKING FUNCTION ==========================▲
	}
}
