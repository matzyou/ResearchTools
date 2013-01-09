package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author matzyou
	 */
	public class FileEvent extends Event 
	{
		public var fileName:String = "";
		public function FileEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new FileEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("FileEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}