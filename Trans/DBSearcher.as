package Trans 
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.SQLEvent;
	import flash.events.SQLErrorEvent;
	/**
	 * ...
	 * @author matzyou
	 */
	public class DBSearcher extends EventDispatcher
	{
		private var stmt:SQLStatement, ID:int;
		public function DBSearcher(connection:SQLConnection) 
		{
			stmt = new SQLStatement();
			if(connection.connected){
				stmt.sqlConnection = connection;
			}else {
				trace("DB not connected");
			}
		}
		
		public function dbSearch(query:String, id:int):void {
			ID = id;
			stmt.addEventListener(SQLEvent.RESULT, onSearchCmp, false, 0, true);
			stmt.addEventListener(SQLErrorEvent.ERROR, onDBError, false, 0, true);
			stmt.text = "SELECT * FROM history WHERE jpn LIKE '%" + query + "%'";
			stmt.execute();
		}
		
		private function onSearchCmp(e:SQLEvent):void {
			//検索結果を返す
			dispatchEvent(new DBSearchEvent(DBSearchEvent.SEARCH_COMPLETE, e.target.getResult(), ID));
		}
		private function onDBError(e:SQLErrorEvent):void {trace(e.error.details);}
	}

}