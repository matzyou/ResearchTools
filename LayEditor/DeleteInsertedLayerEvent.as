package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author MatzYou
	 */
	public class DeleteInsertedLayerEvent extends Event 
	{
		public var parentIndex:int = -1;
		public var childIndex:int = -1;
		public function DeleteInsertedLayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new DeleteInsertedLayerEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DeleteInsertedLayerEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}