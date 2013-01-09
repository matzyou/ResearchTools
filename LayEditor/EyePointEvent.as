package  
{
	import flash.events.Event;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author MatzYou
	 */
	public class EyePointEvent extends Event 
	{
		public var pt:Point = new Point();
		public function EyePointEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new EyePointEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("EyePointEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}