package Trans 
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	/**
	 * ...
	 * @author matzyou
	 */
	public class DBManager extends EventDispatcher
	{
		private var connection:SQLConnection, db:File, isFirst:Boolean;
		private static const openCmpEvent:Event = new Event("openCmp"), insertCmpEvent:Event = new Event("insertCmp");
		
		public function DBManager(file:File) 
		{
			db = file;
			isFirst = !file.exists; //初回起動ならテーブルを作る　二回目以降なら飛ばす
			if (isFirst) {
				db.parent.createDirectory();
			}
			connection = new SQLConnection();
		}
		
		public function open():void {
			if (!connection.connected) {
				try{
					connection.open(db);
				}catch (e:SQLError) {
					trace(e.details);
				}
			}else {
				trace("- you are connecting DB already -");
			}
		}
		
		public function openAsync():void {
			if(!connection.connected){
				connection.addEventListener(SQLEvent.OPEN, onDBOpen, false, 0, true);
				connection.addEventListener(SQLErrorEvent.ERROR, onDBError, false, 0, true);
				connection.openAsync(db);
			}else {
				trace("- you are connecting DB already -");
			}
		}
		private function onDBOpen(e:SQLEvent):void {
			trace("DB connect success");
			connection.removeEventListener(SQLEvent.OPEN, onDBOpen);
			if(isFirst){//最初だからDBにテーブルを用意する
				var stmt:SQLStatement = new SQLStatement();
				stmt.sqlConnection = connection;
				stmt.addEventListener(SQLEvent.RESULT, onCreateTable, false, 0, true);
				stmt.addEventListener(SQLErrorEvent.ERROR, onDBError, false, 0, true);
				stmt.text = "CREATE TABLE IF NOT EXISTS history(id INTEGER PRIMARY KEY AUTOINCREMENT, jpn TEXT, eng TEXT, timestamp TEXT);";
				stmt.execute();
			}else {
				dispatchEvent(openCmpEvent);
			}
		}
		private function onCreateTable(e:SQLEvent):void {
			trace("create table cmp");
			isFirst = false;
			dispatchEvent(openCmpEvent);
		}
		
		//こっちにもクエリー投げられるから　それで検索する
		public function search(query:String, id:int):void {
			if (!connection.connected) {
				trace("DB not connect");
				return;
			}
			var searcher:DBSearcher = new DBSearcher(connection);
			searcher.addEventListener(DBSearchEvent.SEARCH_COMPLETE, onSearchCmp);
			searcher.dbSearch(query, id);
		}
		private function onSearchCmp(e:DBSearchEvent):void {
			//検索結果を返す
			dispatchEvent(e);
		}
		
		//日本語と英語をセットで登録する 日本語はスペース区切りで接続済み
		public function insertSentence(jpn:String, eng:String):void {
			if (!connection.connected) {
				trace("DB not connect");
				return;
			}
			if (eng.match(/'/g)) eng = eng.replace(/'/g, "''");
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = connection;
			stmt.addEventListener(SQLEvent.RESULT, onInsertCmp, false, 0, true);
			stmt.addEventListener(SQLErrorEvent.ERROR, onDBError, false, 0, true);
			stmt.text = "INSERT INTO history(jpn, eng, timestamp) VALUES ('"+jpn+"','"+eng+"','"+new Date().toString()+"');";
			stmt.execute();
		}
		private function onInsertCmp(e:SQLEvent):void {
			dispatchEvent(insertCmpEvent);
		}
		
		private function onDBError(e:SQLErrorEvent):void {trace(e.error.details);}
		public function close():void {connection.close();}
	}

}