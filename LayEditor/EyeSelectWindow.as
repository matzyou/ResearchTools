package  
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author MatzYou
	 */
	public class EyeSelectWindow extends Sprite{
		
		public var eyeWindow:NativeWindow;
		public var wito:NativeWindowInitOptions = new NativeWindowInitOptions();
		public var tf:TextField = new TextField();
		public var t:Timer = new Timer(150);
		
		public function EyeSelectWindow(own:NativeWindow) {
			wito.type = NativeWindowType.LIGHTWEIGHT;
			wito.type = NativeWindowType.UTILITY;
			
			wito.systemChrome = NativeWindowSystemChrome.NONE;
			wito.transparent = true;
			wito.owner = own;
			eyeWindow = new NativeWindow(wito);
			eyeWindow.height = 60;
			eyeWindow.width = 200;
			eyeWindow.title = "--(0,0)--"
			eyeWindow.activate();
			eyeWindow.stage.addChild(tf);
			eyeWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			eyeWindow.stage.align = StageAlign.TOP_LEFT;
			//tf.text = eyeWindow.title;
			t.addEventListener(TimerEvent.TIMER, frame);
		}
		public var str:String;
		public function frame(e:Event):void {
			str = eyeWindow.title;
			var param:Array = str.split(",", 2);
			var x:Array = param[0].split("(", 2);
			var y:Array = param[1].split(")", 2);
			//tf.text = x[1] + " " + y[0];
			
			var pt:Point = new Point(x[1],y[0]);
			var ep:EyePointEvent = new EyePointEvent("eyePoint");
			ep.pt = pt;
			dispatchEvent(ep);
			
		}
		
		
	}

}