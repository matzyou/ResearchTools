package
{
   import flash.events.Event;

   public class SliderbarEvent extends Event
   {
      public var pos:Number = 0;
      public function SliderbarEvent(type:String){
         super(type);
      }
   }
}