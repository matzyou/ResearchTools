package Trans 
{
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	/**
	 * ...
	 * @author matzyou
	 * 
	 * タブ一個一個
	 */
	public class Tab extends Sprite {
		
		private var tf:TextField, cover:Sprite, baseG:Graphics, closeG:Graphics, cx:int, cy:int, g:Graphics;
		public var resultsArea:ResultsArea, closeSprite:Sprite, isActive:Boolean;
		
		public function Tab(text:String = "", area:ResultsArea = null) {
			var format:TextFormat = new TextFormat();
			format.size = 10;
			tf = new TextField();
			tf.text = text;
			tf.setTextFormat(format);
			tf.selectable = false;
			tf.autoSize = TextFieldAutoSize.LEFT;
			addChild(tf);
			
			cover = new Sprite();
			g = cover.graphics;
			g.beginFill(0xffffff, 0.01);
			g.drawRoundRect(0, 0, tf.width, tf.height, 5, 5);
			g.endFill();
			addChild(cover);
			
			baseG = graphics;
			baseG.beginFill(0xf0f0f0, 0.8);
			baseG.drawRoundRect(0, 0, tf.width, tf.height, 5, 5);
			baseG.endFill();
			
			closeSprite = new Sprite();
			closeG = closeSprite.graphics;
			closeG.beginFill(0xffffff, 0.01);
			cx = tf.width + 5;
			cy = (tf.height >> 1) + 1;
			closeG.drawCircle(cx, cy, 6);
			closeG.endFill();
			addChild(closeSprite);
			closeSprite.addEventListener(MouseEvent.MOUSE_OVER, MOVER);
			closeSprite.addEventListener(MouseEvent.MOUSE_OUT, MOUT);
			closeG.lineStyle(2, 0x999999, 0.3);
			closeG.moveTo(cx - 2.5, cy - 2.5);
			closeG.lineTo(cx + 2.5, cy + 2.5);
			closeG.moveTo(cx - 2.5, cy + 2.5);
			closeG.lineTo(cx + 2.5, cy - 2.5);
			
			tf.mouseEnabled = false;
			cover.mouseEnabled = false;
			resultsArea = area;
		}
		
		public function showResultsArea():void { resultsArea.visible = true; }
		public function hideResultsArea():void { resultsArea.visible = false; }
		
		private function MOVER(e:MouseEvent):void {
			closeG.clear();
			closeG.beginFill(0xff9090, 0.5);
			cx = tf.width + 5;
			cy = (tf.height >> 1) + 1;
			closeG.drawCircle(cx, cy, 6);
			closeG.endFill();
			closeG.lineStyle(2, 0xffffff);
			closeG.moveTo(cx - 2.5, cy - 2.5);
			closeG.lineTo(cx + 2.5, cy + 2.5);
			closeG.moveTo(cx - 2.5, cy + 2.5);
			closeG.lineTo(cx + 2.5, cy - 2.5);
		}
		private function MOUT(e:MouseEvent):void {
			closeG.clear();
			closeG.beginFill(0xffffff, 0.01);
			cx = tf.width + 5;
			cy = (tf.height >> 1) + 1;
			closeG.drawCircle(cx, cy, 6);
			closeG.endFill();
			closeG.lineStyle(2, 0x666666, 0.4);
			closeG.moveTo(cx - 2.5, cy - 2.5);
			closeG.lineTo(cx + 2.5, cy + 2.5);
			closeG.moveTo(cx - 2.5, cy + 2.5);
			closeG.lineTo(cx + 2.5, cy - 2.5);
		}
		
		public function activate():void {
			baseG.clear();
			baseG.beginFill(0xeaf4fc);
			baseG.drawRoundRect(0, 0, tf.width + 12, tf.height + 5, 5, 5);
			baseG.endFill();
			isActive = true;
			showResultsArea();
		}
		
		public function deactivate():void {
			baseG.clear();
			baseG.beginFill(0xc0c0c0, 0.8);
			baseG.drawRoundRect(0, 0, tf.width + 12, tf.height, 5, 5);
			baseG.endFill();
			isActive = false;
			hideResultsArea();
		}
		
		public function clear():void {
			removeChildren();
			resultsArea.clearArea();
			resultsArea = null;
		}
		
		public function get text():String { return tf.text; }
	}

}