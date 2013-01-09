package
{
   import flash.display.*;
   import flash.events.*;

   public class SliderControl extends Sprite
   {
	   public var barBtn:Sprite; 
      public function SliderControl( _initPos:Number=1,_width:Number=100,_height:Number=20,_barWidth:Number=80){
         var container:Sprite = this;
         container.graphics.beginFill(0x999999,1.0);
         container.graphics.drawRoundRect(0,0,_width,_height,8,8);
         container.graphics.beginFill(0xfffaf0,1.0);
         container.graphics.drawRoundRect(1,1,_width-2,_height-2,5,5);
         
         var bar:Sprite = container.addChild(new Sprite()) as Sprite;
         bar.graphics.lineStyle(2,0x696969,1.0);
         bar.graphics.lineTo(_barWidth,0);
         bar.graphics.endFill();
         bar.x = (_width-_barWidth)/2;
         bar.y = _height/2;
         
		 //カーソルの表示
         barBtn = bar.addChild(new Sprite()) as Sprite;
         _initPos= _initPos>1?1:(_initPos<0?0:_initPos);
         barBtn.x = _initPos*_barWidth;
         barBtn.graphics.lineStyle(1,0x191970,1.0);
         barBtn.graphics.beginFill(0x00bfff, 0.5);
		 /*
         barBtn.graphics.moveTo( 2, 5);
         barBtn.graphics.lineTo( 2,-5);
         barBtn.graphics.lineTo(-2,-5);
         barBtn.graphics.lineTo(-2, 5);
         barBtn.graphics.lineTo( 2, 5);
         barBtn.graphics.endFill();
		 */
		 barBtn.graphics.drawRoundRect( -3, -6, 6, 12, 2, 2);
         barBtn.buttonMode=true;
         barBtn.useHandCursor=true;
         
         var drag:Boolean = false;
		 //▼----------------------↓スライダーハンドルをドラッグした処理↓--------------------▼
         var stageMouseMoveHandler:Function=function(event:MouseEvent):void{
            if(drag){
               var barBtnX:Number = barBtn.x;
               if(0<=bar.mouseX && bar.mouseX <= _barWidth){
                  barBtn.x=bar.mouseX;
               }else if(bar.mouseX<0){
                  barBtn.x=0;
               }else if(_barWidth<bar.mouseX){
                  barBtn.x = _barWidth;
               }
               if(barBtnX!=barBtn.x){
                  var newEvent:SliderbarEvent = new SliderbarEvent("change");
                  newEvent.pos = barBtn.x/_barWidth;
                  container.dispatchEvent(newEvent);
               }
            }
         };
		 
         var stageMouseUpHandler:Function=function(event:MouseEvent):void{
            drag=false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandler);
            stage.removeEventListener(MouseEvent.MOUSE_UP,stageMouseUpHandler);
         };
		 //▲----------------------↑スライダーハンドルをドラッグした処理↑--------------------▲
 		 //▼----------------------↓スライダーコントロール内をクリックした処理↓--------------------▼
         container.addEventListener(MouseEvent.MOUSE_DOWN,function(evt:MouseEvent):void{
            drag=true;
            stage.addEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandler);
            stage.addEventListener(MouseEvent.MOUSE_UP,stageMouseUpHandler);
            var barBtnX:Number = barBtn.x;
            if(1<=bar.mouseX && bar.mouseX <= _barWidth){
               barBtn.x=bar.mouseX;
            }else if(bar.mouseX<1){
               barBtn.x=1;
            }else if(_barWidth<bar.mouseX){
               barBtn.x = _barWidth;
            }
            if(barBtnX!=barBtn.x){
               var newEvent:SliderbarEvent = new SliderbarEvent("change");
               newEvent.pos = barBtn.x/_barWidth;
               container.dispatchEvent(newEvent);
            }
         });
         container.addEventListener("update", function(event:SliderbarEvent):void {
			trace("slidecontrol update catch");
            var pos:Number = event.pos>1?1:(event.pos<0?0:event.pos);
            barBtn.x = pos*_barWidth;
         });
 		 //▲----------------------↑スライダーコントロール内をクリックした処理↑--------------------▲
  		 //▼----------------------↓イベントで値を受け取る↓--------------------▼
		 container.addEventListener("changeFocus", function(se:SliderbarEvent):void {
			barBtn.x = se.pos * _barWidth;
		 });
 		 //▲----------------------↑イベントで値を受け取る↑--------------------▲
      }
   }
}