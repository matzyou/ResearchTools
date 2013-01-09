package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author MatzYou
	 */
	public class InsertLayerEvent extends Event 
	{
		public var parentIndex:int = -1;
		public var childIndex:int = -1;
		public function InsertLayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new InsertLayerEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("InsertLayerEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}