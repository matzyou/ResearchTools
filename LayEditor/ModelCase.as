package  
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author MatzYou
	 */
	public class ModelCase extends Sprite{
		
		public var modelSprite:Sprite = new Sprite();
		
		/*
		 * モデルケース　検証用
		 * とりあえずこうしたら使えるんじゃねっていう場合をここで生成して
		 * どう使えるかを見る感じ
		 */
		public function ModelCase(stage:Stage) {
			stage.addChild(modelSprite);
			case1(stage);
		}
		
		public var layer1:Sprite = new Sprite();
		public var layer2:Sprite = new Sprite();
		public var layer3:Sprite = new Sprite();
		public var layer4:Sprite = new Sprite();
		public function case1(stage:Stage):void {
			
			var tf1:TextField = new TextField();
			var tf2:TextField = new TextField();
			var tf3:TextField = new TextField();
			var tf4:TextField = new TextField();
			
			var format:TextFormat = new TextFormat();
			format.size = 20;
			
			tf1.defaultTextFormat = format;
			tf2.defaultTextFormat = format;
			tf3.defaultTextFormat = format;
			tf4.defaultTextFormat = format;
			
			
			layer1.addEventListener(MouseEvent.MOUSE_DOWN, down);
			layer1.addEventListener(MouseEvent.MOUSE_UP, up);
			
		}
		
		public function down(me:MouseEvent):void {
			layer1.startDrag();
		}
		public function up(me:MouseEvent):void {
			layer1.stopDrag();
		}
		
	}

}