package Trans 
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.engine.TabAlignment;
	/**
	 * ...
	 * @author matzyou
	 */
	public class TabsArea extends Sprite
	{
		public var tabsVector:Vector.<Tab>, areaWidth:int, areaHeight:int;
		private var offsetX:int, tabSprite:Sprite, leftButton:Sprite, rightButton:Sprite, cover:Sprite, isScrollTab:Boolean;
		private static const allClearEvent:Event = new Event("allClear");
		
		public function TabsArea(windowWidth:int, windowHeight:int) {
			areaWidth = windowWidth - 40;
			areaHeight = windowHeight / 48;
			tabSprite = new Sprite();
			addChild(tabSprite);
			tabSprite.x = 4;
			tabsVector = new Vector.<Tab>();
			offsetX = 0;
			
			var g:Graphics;
			cover = new Sprite();
			addChild(cover);
			g = cover.graphics;
			g.beginFill(0x4c4c4c);
			g.drawRect(-20, 0, 20, areaHeight);
			g.drawRect(areaWidth, 0, 20, areaHeight)
			g.endFill();
			g.beginFill(0x4c4c4c);
			g.drawRect(-20, areaHeight - 3, 5.5, 4);
			g.drawRect(areaWidth + 14.5, areaHeight - 3, 5.5, 4);
			g.endFill();
			
			rightButton = new Sprite();
			addChild(rightButton);
			g = rightButton.graphics;
			g.beginFill(0x999999, 0.8);
			g.drawRoundRect(0, 0, 15, areaHeight, 5, 5);
			g.endFill();
			g.lineStyle(2, 0xffffff, 0.8);
			g.moveTo(3, 3);
			g.lineTo(3, areaHeight - 3);
			g.lineTo(11, areaHeight >> 1);
			g.lineTo(3, 3);
			rightButton.x = areaWidth;
			rightButton.y = -2;
			
			leftButton = new Sprite();
			addChild(leftButton);
			leftButton.x = -15;
			leftButton.y = -2;
			g = leftButton.graphics;
			g.beginFill(0x999999, 0.8);
			g.drawRoundRect(0, 0, 15, areaHeight, 5, 5);
			g.endFill();
			g.lineStyle(2, 0xffffff, 0.8);
			g.moveTo(11, 3);
			g.lineTo(11, areaHeight - 3);
			g.lineTo(3, areaHeight >> 1);
			g.lineTo(11, 3);
			
			leftButton.alpha = 0.3;
			rightButton.alpha = 0.3;
			
			leftButton.addEventListener(MouseEvent.CLICK, leftMove);
			leftButton.addEventListener(MouseEvent.MOUSE_OVER, MOVER);
			leftButton.addEventListener(MouseEvent.MOUSE_OUT, MOUT);
			rightButton.addEventListener(MouseEvent.CLICK, rightMove);
			rightButton.addEventListener(MouseEvent.MOUSE_OVER, MOVER);
			rightButton.addEventListener(MouseEvent.MOUSE_OUT, MOUT);
		}
		
		public function addTab(text:String = "", area:ResultsArea = null):void {
			var tab:Tab = new Tab(text, area), lastTab:Tab, num:int;
			tabsVector.push(tab);
			tabSprite.addChild(tab);
			alignTabs();
			num = tabSprite.numChildren;
			for (var i:int = 0; i < num; i++) {
				Tab(tabSprite.getChildAt(i)).deactivate();
			}
			tab.activate();
			tab.addEventListener(MouseEvent.CLICK, activateTab);
			tab.closeSprite.addEventListener(MouseEvent.CLICK, closeTab);
			//表示範囲を超えていたら収まるようにする
			isScrollTab = false;
			leftButton.alpha = rightButton.alpha = 0.3;
			lastTab = Tab(tabSprite.getChildAt(tabSprite.numChildren - 1));
			if (lastTab.x + lastTab.width > areaWidth) {
				isScrollTab = true;
				leftButton.alpha = rightButton.alpha = 0.6;
				var tmp:int = areaWidth - lastTab.x - lastTab.width;
				tabSprite.x = tmp - 4;
			}
			
		}
		
		private function closeTab(e:MouseEvent):void {
			/* activeTabを閉じる場合は右隣があればそれをアクティブに
			 * 右がなければ左をアクティブに　どっちも無ければ真っ白な状態にする
			 * 左詰めにして整形
			 **/
			e.stopPropagation(); //親側にもCLICKイベントが伝播するのでここで食い止める
			var tab:Tab = Tab(e.target.parent), index:int;
			if (tab.resultsArea.isLoading) return;
			index = tabsVector.indexOf(tab);
			if (tab.isActive) { //activeTabを閉じる
				tab.deactivate();
				if (tabsVector.length == 1) { //そのタブしかなかった
					tabsVector.pop();
					
					dispatchEvent(allClearEvent);
				} else if (index + 1 >= tabsVector.length) { //一番右側だった
					tabsVector[index - 1].activate();
					tabsVector.splice(index, 1);
				} else { //右側がいるのでそっちをアクティブに
					tabsVector[index + 1].activate();
					tabsVector.splice(index, 1);
				}
			}else {
				if (index + 1 >= tabsVector.length) { //一番右側だった
					tabsVector.pop();
				} else { //右側がいる
					tabsVector.splice(index, 1);
				}
			}
			tabSprite.removeChild(tab);
			tab.removeEventListener(MouseEvent.CLICK, activateTab);
			tab.closeSprite.removeEventListener(MouseEvent.CLICK, closeTab);
			tab.clear();
			tab = null;
			alignTabs();
			
			isScrollTab = false;
			leftButton.alpha = rightButton.alpha = 0.3;
			if (tabsVector.length <= 0) return;
			var lastTab:Tab = Tab(tabSprite.getChildAt(tabSprite.numChildren - 1));
			if (lastTab.x + lastTab.width > areaWidth) {
				isScrollTab = true;
				leftButton.alpha = rightButton.alpha = 0.6;
			}else {
				tabSprite.x = 4;
			}
		}
		
		private function alignTabs():void {
			//タブを整列させる
			offsetX = 0;
			var num:int = tabsVector.length;
			for (var i:int = 0; i < num; i++) {
				tabsVector[i].x = offsetX;
				offsetX += tabsVector[i].width + 4;
			}
		}
		
		public function activateTab(e:MouseEvent):void {
			var num:int = tabSprite.numChildren, tab:Tab;
			for (var i:int = 0; i < num; i++) {
				Tab(tabSprite.getChildAt(i)).deactivate();
			}
			tab = Tab(e.target);
			tab.activate();
			//前後のがあればそれが見えるように
			if (tab.x + tabSprite.x < 4) tabSprite.x = -tab.x + 8;
			else if (tab.x + tab.width + tabSprite.x > areaWidth) tabSprite.x = areaWidth - tab.x - tab.width - 8;
		}
		
		//scroll
		public function leftMove(e:MouseEvent):void {
			if (!isScrollTab) return;
			tabSprite.x += areaWidth / 6;
			var tab:Tab = Tab(tabSprite.getChildAt(tabSprite.numChildren - 1));
			if (tabSprite.x > 4) tabSprite.x = 4;
		}
		public function rightMove(e:MouseEvent):void {
			if (!isScrollTab) return;
			tabSprite.x -= areaWidth / 6;
			var tab:Tab = Tab(tabSprite.getChildAt(tabSprite.numChildren - 1));
			if (tabSprite.x < tab.x - tab.width) tabSprite.x = -(tab.x + tab.width - areaWidth) - 4;
		}
		
		public function getAllTabWord():String {
			var str:String = new String(), num:int = tabsVector.length, i:int;
			for (i = 0; i < num; i++) {
				str += tabsVector[i].text + ",";
			}
			return str;
		}
		private function MOVER(e:MouseEvent):void {if(isScrollTab)	e.target.alpha = 1;}
		private function MOUT(e:MouseEvent):void {if(isScrollTab) e.target.alpha = 0.6;}
	}

}