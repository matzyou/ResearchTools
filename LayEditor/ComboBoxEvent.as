package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author MatzYou
	 */
	public class ComboBoxEvent extends Event 
	{
		public var data:int = 0;
		public var label:String = "NONE";
		public function ComboBoxEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new ComboBoxEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ComboBoxEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}