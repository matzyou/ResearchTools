package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author MatzYou
	 */
	public class TurnVisibleEvent extends Event 
	{
		public var index:int = 0;
		public function TurnVisibleEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new TurnVisibleEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("TurnVisibleEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}