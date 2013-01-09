package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author MatzYou
	 */
	public class ColorEvent extends Event 
	{
		public var index:int = 0;
		public var color:uint = 0xffffff;
		public function ColorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new ColorEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ColorEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}