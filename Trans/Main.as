package Trans
{
	import fl.core.ComponentShim;
	import fl.data.DataProvider;
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.desktop.SystemTrayIcon;
	import flash.display.*;
	import fl.controls.*;
	import flash.events.FocusEvent;
	import flash.ui.Keyboard;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.*;
	import fl.events.*;
	import flash.ui.Multitouch;
	import flash.filesystem.File;
	import flash.data.SQLResult;
	/**
	 * ...
	 * @author matzyou
	 */
	/** summary
	 * Main:このプログラムの母体　すべての要素はここで管理される
	 * 		SearchArea，ResultsArea，ComposeAreaの3つに分けて実装
	 *
	 * SearchArea:検索用のクラス
	 * 		クエリを入力して検索する　ここはそれだけ検索エンジンにクエリ投げる準備をして終了
	 * 		実際検索するのはMainの中
	 * 
	 * ResultsArea:検索結果の表示用クラス
	 * 		検索結果を整形して表示する　検索エンジンからの結果を解析して日本語と英語を抜き出す
	 * 		日本語と英語をもとにしてMultiSentencesを作っていく
	 * 
	 * MultiSentences:日本語と英語の一セットをまとめてもつクラス
	 * 		日本語1つに対して複数の英語が対応する場合があるが，これひとつで対応
	 * 		英語は解析器にかけて単語毎に分けてかつ品詞分析　単語はWordで作る
	 * 
	 * analyzerLoader:品詞解析の時に使うクラス
	 * 		普通にやるとうまく結果が帰ってこないことがある
	 * 		うまくいかなかった時のために　リロードできるようにする
	 * 
	 * Word：英単語用のクラス
	 * 		1つの英単語を持つ　その品詞に応じて色を変える　これをマウスで動かして文を作る
	 * 
	 * ComposeArea:目的の文を組み立てるエリアのクラス
	 * 		このエリア内でWordを移動したり，単語を足したり，人称時制を変更したりして文を組み立てる
	 * 		ResultsAreaから一文引っ張ってきたり，単語をドラッグしてきて　ここにドロップする
	 * 		このエリア内のWordを外にドロップすることでそのWordを削除
	 * 		並び替えは，置きたい場所にドロップすることで可能
	 * 		Doneボタンを押すとクリップボードに，現在のComposeArea内の文をコピーして外に出せるようにする
	 * 
	 * ResolutionNumber：解像度の値を定数として保持するためのクラス
	 * 
	 * Tab:タブ
	 * 		タブ
	 * 
	 * TabsArea:タブを表示するエリア
	 * 		この中にタブを入れていく
	 * 
	 * DBManager:データベース（履歴）管理用クラス
	 * DBSearchEvent:DBから検索した時にその結果を受け取るためのイベントクラス
	 * 
	 */
	public class Main extends Sprite 
	{
		private var searchArea:SearchArea, resultsAreas:Vector.<ResultsArea>, resultsAreaID:int,
					sentenceArea:Sprite, composeArea:ComposeArea, tabsArea:TabsArea,
					isCtrlDown:Boolean, ratio:Number, resultsAreaContainer:Sprite, dbManager:DBManager;
		public static var mainWidth:int, mainHeight:int;
		public static const ENGINE:String = SearchManager.GLOSBE; //alc or glosbe
		
		public function Main():void 
		{
			//解像度切り替えるときは Project->Properties から Dimensions の値もなおす必要あり
			//init(ResolutionNumbers.HVGAW360W, ResolutionNumbers.HVGAW640H); //360x640
			init(ResolutionNumbers.QHD540W, ResolutionNumbers.QHD960H); //540x960 556x998
			//init(ResolutionNumbers.HD720W, ResolutionNumbers.HD1280H); //720x1280
		}
		/*
		 * margin 5px
		 * searchArea
		 * w: windowWidth - 10
		 * h: windowHeight / 16 - 5 //640:35, 960:55 , 1280:75
		 * 
		 * resultsArea
		 * w: windowWidth - 10
		 * h: windowHeight * 11 / 16 - 5 //640:435, 960:655, 1280:875
		 * 
		 * composeArea
		 * w: windowWidth - 10
		 * h: windowHeight / 4 - 10 //640:150, 960:230, 1280:310
		 * 
		 * 隙間が20pxある
		 */
		private function init(initWidth:int, initHeight:int):void {
			mainWidth = initWidth;
			mainHeight = initHeight;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = StageAlign.TOP_LEFT;
			stage.nativeWindow.addEventListener(Event.RESIZE, windowResize);
			ratio = stage.nativeWindow.height / stage.nativeWindow.width;
			
			searchArea = new SearchArea(mainWidth, mainHeight);
			addChild(searchArea);
			searchArea.x = 5;
			searchArea.y = 5;
			searchArea.searchButton.addEventListener(MouseEvent.CLICK, searchButtonClick);
			searchArea.query = "";
			searchArea.queryTextInput.addEventListener(ComponentEvent.ENTER, enter);
			
			resultsAreas = new Vector.<ResultsArea>();
			resultsAreaID = 0; //IDは0からスタート
			resultsAreas.push(new ResultsArea(mainWidth, mainHeight,resultsAreaID));
			resultsAreaContainer = new Sprite();
			addChild(resultsAreaContainer);
			resultsAreaContainer.addChild(resultsAreas[resultsAreaID]);
			resultsAreas[resultsAreaID].x = 5;
			resultsAreas[resultsAreaID].y = searchArea.y + searchArea.areaHeight + 10;
			
			setChildIndex(resultsAreaContainer, 0);
			setLayer();
			
			composeArea = new ComposeArea(mainWidth, mainHeight);
			addChild(composeArea);
			composeArea.x = 5;
			composeArea.y = resultsAreas[resultsAreaID].y + resultsAreas[resultsAreaID].areaHeight + 5;
			composeArea.composeSprite.addEventListener(ComposeArea.INSERT_WORD_EVENT, insertWord);
			composeArea.addEventListener(ComposeArea.DONE_EVENT, historyWrite);
			
			tabsArea = new TabsArea(mainWidth, mainHeight);
			addChild(tabsArea);
			tabsArea.x = 20;
			tabsArea.y = resultsAreas[resultsAreaID].y - (searchArea.areaHeight + 5) / 3;
			tabsArea.addEventListener("allClear", allClearTab);
			
			dbManager = new DBManager(File.applicationStorageDirectory.resolvePath("history").resolvePath("userHistory.db"));
			dbManager.open();
			
			addEventListener(KeyboardEvent.KEY_DOWN, KD);
			addEventListener(KeyboardEvent.KEY_UP, KU);
			stage.nativeWindow.addEventListener(Event.CLOSING, windowClosing);
		}
		
		//履歴保存
		private function historyWrite(e:Event):void {
			dbManager.insertSentence(tabsArea.getAllTabWord(),composeArea.getSentence());
		}
		
		//----▼- task tray functions -▼-----------
		private function windowClosing(e:Event):void {
			dbManager.close();
			/*stage.nativeWindow.visible = false;
			e.preventDefault();
			setTaskTray();*/
		}
		
		private function setTaskTray():void {
			var images:Array = [], systemTrayMenu:NativeMenu, systemTrayIcon:SystemTrayIcon, exitMenu:NativeMenuItem;
			if (NativeApplication.supportsSystemTrayIcon) {
				images.push(new BitmapData(16, 16, false, 0xf0c0c0));
				NativeApplication.nativeApplication.icon.bitmaps = images;
			}
			systemTrayMenu = new NativeMenu();
			systemTrayIcon = SystemTrayIcon(NativeApplication.nativeApplication.icon);
			systemTrayIcon.menu = systemTrayMenu;
			exitMenu = new NativeMenuItem("exit");
			exitMenu.addEventListener(Event.SELECT, exitSelect);
			systemTrayMenu.addItem(exitMenu);
			NativeApplication.nativeApplication.icon.addEventListener(MouseEvent.CLICK, trayClick);
		}
		private function trayClick(e:MouseEvent):void {
			stage.nativeWindow.visible = true;
			stage.nativeWindow.activate();
		}
		private function exitSelect(e:Event):void {
			dbManager.close();
			NativeApplication.nativeApplication.exit();
		}
		//-----▲- task tray functions -▲-----------
		//--▼----------Keyboard Event--------------------▼--
		private function KD(ke:KeyboardEvent):void {
			//trace(ke.keyCode);
			switch(ke.keyCode){
				case Keyboard.C: if (ke.ctrlKey && ke.shiftKey) { ke.preventDefault(); } break;
				case Keyboard.CONTROL: isCtrlDown = true; break;
			}
		}
		private function KU(ke:KeyboardEvent):void {
			isCtrlDown = false;
		}
		//--▲----------Keyboard Event--------------------▲--
		
		//スクロール処理のためのカバー用レイヤ　はみ出した部分を隠す　rearchAreaより上でsearchArea,composeAreaより下
		private function setLayer():void {
			var headsp:Sprite = new Sprite(), footsp:Sprite = new Sprite(), g:Graphics;
			g = headsp.graphics;
			g.beginFill(0x4c4c4c);
			g.drawRect(0, 0, stage.width, resultsAreas[resultsAreaID].y);
			g.endFill();
			addChild(headsp);
			setChildIndex(headsp, 1);
			
			g = footsp.graphics;
			g.beginFill(0x4c4c4c);
			g.drawRect(0, resultsAreas[resultsAreaID].y + resultsAreas[resultsAreaID].areaHeight, stage.width, 400);//400なのはどの解像度でもエリア外までカバーするから
			g.endFill();
			addChild(footsp);
			setChildIndex(footsp, 2);
		}
		
		private var isFirst:Boolean = true, searchManager:SearchManager, htmlLoader:HTMLLoader, glosbeLoader:URLLoader;
		private function searchButtonClick(e:MouseEvent):void {
			var ra:ResultsArea;
			if (isFirst) {
				ra = resultsAreas[resultsAreaID];
				ra.elementsCnt = 0;
				ra.stepIndex = 0;
				ra.isLoading = true;
				dbManager.addEventListener(DBSearchEvent.SEARCH_COMPLETE, dbSearchCmp);
				dbManager.search(searchArea.query, resultsAreaID);
				searchManager = new SearchManager(ENGINE, resultsAreaID);
				searchManager.load(searchArea.setQueryURL(ENGINE));
				switch(ENGINE) {
					case SearchManager.ALC: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, alcLoadCmp); break;
					case SearchManager.GLOSBE: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, glosbeLoadCmp); break;
				}
				tabsArea.addTab(searchArea.query, resultsAreas[resultsAreaID]);
				isFirst = false;
			}else {
				resultsAreas.push(new ResultsArea(mainWidth, mainHeight, ++resultsAreaID));
				ra = resultsAreas[ resultsAreas.length - 1];
				ra.x = 5;
				ra.y = searchArea.y + searchArea.areaHeight + 10;
				ra.elementsCnt = 0;
				ra.stepIndex = 0;
				ra.isLoading = true;
				resultsAreaContainer.addChild(ra);
				searchManager = new SearchManager(ENGINE, resultsAreaID);
				searchManager.load(searchArea.setQueryURL(ENGINE));
				switch(ENGINE) {
					case SearchManager.ALC: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, alcLoadCmp); break;
					case SearchManager.GLOSBE: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, glosbeLoadCmp); break;
				}
				tabsArea.addTab(searchArea.query, ra);
			}
		}
		private function enter(e:ComponentEvent):void {
			var ra:ResultsArea;
			if (isFirst) {
				ra = resultsAreas[resultsAreaID];
				ra.elementsCnt = 0;
				ra.stepIndex = 0;
				ra.isLoading = true;
				dbManager.addEventListener(DBSearchEvent.SEARCH_COMPLETE, dbSearchCmp);
				dbManager.search(searchArea.query, resultsAreaID);
				searchManager = new SearchManager(ENGINE, resultsAreaID);
				searchManager.load(searchArea.setQueryURL(ENGINE));
				switch(ENGINE) {
					case SearchManager.ALC: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, alcLoadCmp); break;
					case SearchManager.GLOSBE: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, glosbeLoadCmp); break;
				}
				tabsArea.addTab(searchArea.query, resultsAreas[resultsAreaID]);
				isFirst = false;
			}else {
				resultsAreas.push(new ResultsArea(mainWidth, mainHeight, ++resultsAreaID));
				ra = resultsAreas[ resultsAreas.length - 1];
				ra.elementsCnt = 0;
				ra.stepIndex = 0;
				ra.x = 5;
				ra.isLoading = true;
				ra.y = searchArea.y + searchArea.areaHeight + 10;
				resultsAreaContainer.addChild(ra);
				dbManager.addEventListener(DBSearchEvent.SEARCH_COMPLETE, dbSearchCmp);
				dbManager.search(searchArea.query, resultsAreaID);
				searchManager = new SearchManager(ENGINE, resultsAreaID);
				searchManager.load(searchArea.setQueryURL(ENGINE));
				switch(ENGINE) {
					case SearchManager.ALC: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, alcLoadCmp); break;
					case SearchManager.GLOSBE: searchManager.addEventListener(SearchEvent.SEARCH_COMPLETE, glosbeLoadCmp); break;
				}
				tabsArea.addTab(searchArea.query, ra);
			}
		}
		private function allClearTab(e:Event):void {
			resultsAreas.push(new ResultsArea(mainWidth, mainHeight, ++resultsAreaID));
			resultsAreas[resultsAreaID].x = 5;
			resultsAreas[resultsAreaID].y = searchArea.y + searchArea.areaHeight + 10;
			resultsAreaContainer.addChild(resultsAreas[resultsAreaID]);
			isFirst = true;
		}
		
		//▼▼▼▼▼▼▼▼▼▼▼▼　DB Search　▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		private function dbSearchCmp(e:DBSearchEvent):void {
			var res:SQLResult = e.sqlResult, ID:int = e.id, ra:ResultsArea = resultsAreas[ID];
			if (res.data == null) {
				trace("該当なし");
			}else {
				var num:int = res.data.length, row:Object;
				for (var i:int = 0; i < num; i++) {
					row = res.data[i];
					trace("id:" + row.id + " jpn:" + row.jpn + " eng:" + row.eng);
					ra.setSentence(row.jpn, row.eng, true);
					ra.elementsCnt++;
				}
			}
			ra.isDBCmp = true;
			stepRunStandby(ID);
		}
		//▲▲▲▲▲▲▲▲▲▲▲▲　DB Search　▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
		//▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼　Glosbe　API　▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		private function glosbeLoadCmp(e:SearchEvent):void {
			e.target.removeEventListener(SearchEvent.SEARCH_COMPLETE, glosbeLoadCmp);
			var glosbeXML:XML = new XML(e.data), ID:int = e.id, ra:ResultsArea = resultsAreas[ID], jpn:String;
			for each(var tmpXML:XML in glosbeXML.entry.list.map) {
				//trace("eng:" + tmpXML.entry.slpair.sentence[0].text());
				jpn = tmpXML.entry.slpair.sentence[1].text();
				jpn = jpn.replace(/<strong class='em'>/g, "").replace(/<\/strong>/g, "").replace(/ /g, "");
				//trace(jpn);
				ra.setSentence(jpn,tmpXML.entry.slpair.sentence[0].text());
				ra.elementsCnt++;
			}
			ra.isNetCmp = true;
			stepRunStandby(ID);
			ra = null;
		}
		//▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲　Glosbe　API　▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
		
		//省く区切り文字一覧
		//◆ ｛　｝ ［　］ (　) ~ ～ … 【 】 《 》 〈 〉
		
		//▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼　ALC　　▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		private var tmpstr:String, strArray:Array, isMulti:Boolean = false;
		private function alcLoadCmp(e:SearchEvent):void {
			//普通にJSの文法でかけるっぽい
			e.target.removeEventListener(SearchEvent.SEARCH_COMPLETE, alcLoadCmp);
			var ID:int = e.id, ra:ResultsArea = resultsAreas[ID], resultsList:Object = e.loader.window.document.getElementById("resultsList"),
				list:Object, tmpobj:Object, tmpobj2:Object, tmpwordclass:Object, wordclassIndex:int, nodeLength:int;
			//var list:Object = resultsList.getElementsByTagName("li"); //liの中のliに反応してしまう
			//結果の入った li 要素を束ねてる ul 要素を抜き出す　配列で出てくるので最初のを参照する
			if (resultsList == null) {
				stepRunStandby(ID);
				return;
			}
			
			list = resultsList.getElementsByTagName("ul")[0];
			ra.elementsCnt += list.childElementCount;//要素数
			
			//ここでlistは　全体を持ってる　ul　を指す
			//ここで list.childNodes　の配列は　奇数番号の中に必要な　li 要素が入ってる
			nodeLength = list.childNodes.length - 1;
			for (var i:int = 1; i < nodeLength; i += 2 ) {
				//innerTextは対応してないらしい textContentで代用できるっぽい
				//【自動】とかがあったら
				//class="ul_je"を持ってると複数回liが引っかかるのでそれは特別に処理
				//tmpobjは ul か ol
				tmpobj = list.childNodes[i].getElementsByClassName("ul_je");
				tmpwordclass = list.childNodes[i].getElementsByClassName("wordclass");
				if (tmpobj.length > 0) { //複数の英文を持ってる
					wordclassIndex = 0;
					isMulti = true;
					//最初の日本語
					tmpstr = tmpobj[0].parentNode.parentNode.getElementsByClassName("midashi")[0].textContent;
					ra.setMultiSentences(tmpobj, tmpstr, tmpwordclass);
				}
				else{//日本語と英語　1つずつ
					tmpstr = list.childNodes[i].textContent;
					//splitで改行文字で分割　結果の配列は　先頭の改行の有無で異なる 
					if(tmpstr.match(/^\n/)){//最初に改行があると1,2 != null
						strArray = tmpstr.split("\n");
						if (tmpstr.match(/→/)) {
							ra.elementsCnt--;
							continue;
						}
						ra.setSentence(strArray[1], strArray[2]);
					}else{//最初に改行がなければ0,1
						strArray = tmpstr.split("\n");
						if (tmpstr.match(/→/)) {
							ra.elementsCnt--;
							continue;
						}
						ra.setSentence(strArray[0], strArray[1]);
					}
				}
			}
			ra.isNetCmp = true;
			ra = null;
			stepRunStandby(ID);
		}
		//▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲　ALC　▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
		
		//▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		private function stepRunStandby(ID:int):void {
			var ra:ResultsArea = resultsAreas[ID];
			if (ra.isNetCmp && ra.isDBCmp) {
				if (ra.elementsCnt <= 0) {
					//検索時にヒットしなかったら　N/Aを出す　こうしないとエラーがでる　あと明示的に無いことを示す
					ra.setSentence("該当無し","N/A");
					ra.elementsCnt++;
				}
				stepRun(ID);
			}else {
				
			}
		}
		//複数個同時にやるから間違う　一個一個実行する
		private function stepRun(id:int):void {
			var sent:MultiSentences = resultsAreas[id].sentences[resultsAreas[id].stepIndex];
			sent.addEventListener("allSetCmp", stepRunCmp);
			sent.setAllSentences();
			sent.show();
		}
		private function stepRunCmp(e:Event):void {
			var id:int = e.target.parent.parent.ID, ra:ResultsArea = resultsAreas[id], sentence:MultiSentences = ra.sentences[ra.stepIndex],
				wv:Vector.<Vector.<Word>> = sentence.wordsVector, wvLength:int = wv.length, wvFirst:Vector.<Word>, wvFirstLength:int,
				sv:Vector.<Sprite> = sentence.englishSentencesSprite, svLength:int = sv.length;
			ra.alignMultiSentences();
			ra.scrollSet();
			//Mainでドラッグの処理をかく
			for (var i:int = 0; i < wvLength; i++) {
				wvFirst = wv[i];
				wvFirstLength = wvFirst.length;
				for (var k:int = 0; k < wvFirstLength; k++) {
					wvFirst[k].cover.addEventListener(MouseEvent.MOUSE_DOWN, wordMouseDown, false, 0, true);
				}
			}
			
			for (var n:int = 0; n < svLength; n++) {
				sv[n].getChildAt(0).addEventListener(MouseEvent.MOUSE_DOWN, allDragMD, false, 0, true);
			}
			sentence.removeEventListener("allSetCmp", stepRunCmp);
			if (++ra.stepIndex >= ra.elementsCnt) {//全要素終わったら
				ra.isLoading = false;
			}else {
				stepRun(id);
			}
		}
		//▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
		
		//--▼-左端の丸をドラッグした時の処理-▼--▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		//これはその文の単語を全部移動する
		private var allDragSprite:Sprite, targetParentIndex:int;
		private function allDragMD(e:MouseEvent):void {
			targetParentIndex = e.target.parent.parent.englishSentencesSprite.indexOf(e.target.parent);
			var sp:Sprite = e.target.parent.parent.englishSentencesSprite[targetParentIndex],
				objY:int = sp.getChildAt(sp.numChildren - 1).y + 24,//multiSentenceの大きさかな
				spg:Graphics, p:Point, tmpWord:Word, cloneWord:Word, num:int = sp.numChildren - 1;
			//単語のクローンとそれをまとめるスプライトを作る
			allDragSprite = new Sprite();
			spg = allDragSprite.graphics;
			spg.beginFill(0xeb6101);
			if(mainWidth == ResolutionNumbers.HVGAW360W) spg.drawCircle( -3, 15, 5);
			else if (mainWidth == ResolutionNumbers.QHD540W) spg.drawCircle( -10, 18, 8);
			
			spg.beginFill(0xeb6101, 0.1);
			if(mainWidth == ResolutionNumbers.HVGAW360W) spg.drawRoundRect(0, 6, mainWidth - mainWidth / 10, objY - 6, 5, 5);
			else if (mainWidth == ResolutionNumbers.QHD540W) spg.drawRoundRect( -6, 6, mainWidth - mainWidth / 10 , objY - 7, 5, 5);
			
			spg.endFill();
			spg.lineStyle(1, 0xeb6101);
			if (mainWidth == ResolutionNumbers.HVGAW360W) {
				spg.moveTo( -3, 4);
				spg.lineTo(mainWidth - mainWidth / 10, 4);
				spg.lineTo(mainWidth - mainWidth / 10, objY);
				spg.lineTo( -3, objY);
				spg.lineTo( -3, 4);				
			}
			else if(mainWidth == ResolutionNumbers.QHD540W){
				spg.moveTo( -10, 4);
				spg.lineTo(mainWidth - mainWidth / 10, 4);
				spg.lineTo(mainWidth - mainWidth / 10, objY);
				spg.lineTo( -10, objY);
				spg.lineTo( -10, 4);
			}
			spg.endFill();
			p = e.target.localToGlobal(new Point(e.target.x, e.target.y));
			allDragSprite.x = p.x;
			allDragSprite.y = p.y;
			
			for (var i:int = 0; i < num; i++) {
				tmpWord = e.target.parent.parent.wordsVector[targetParentIndex][i];
				cloneWord = wordClone( tmpWord );
				allDragSprite.addChild(cloneWord);
				cloneWord.x = tmpWord.x;
				cloneWord.y = tmpWord.y;
			}
			
			addChild(allDragSprite);
			allDragSprite.addEventListener(MouseEvent.MOUSE_UP, allDragMU, false, 0, true);
			allDragSprite.addEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove, false, 0, true);
			insertPoint.setParse(Word.INSERT);
			insertPoint.visible = false;
			composeArea.composeSprite.addChild(insertPoint);
			allDragSprite.startDrag();
		}
		private function allDragMU(e:MouseEvent):void {
			allDragSprite.stopDrag();
			allDragSprite.removeEventListener(MouseEvent.MOUSE_DOWN, allDragMD);
			allDragSprite.removeEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove);
			composeArea.composeSprite.removeChild(insertPoint);
			if (!(mouseX > mainWidth - 5 || mouseX < 5 || mouseY > mainHeight - 5 || mouseY < composeArea.y)) {//違うところにドロップするから座標の方がいい
				//全部のWordを貼っつける
				var tmpWord:Word, cover:Sprite, num:int = allDragSprite.numChildren;
				for (var i:int = 0; i < num; i++) {
					tmpWord = Word(composeArea.composeSprite.addChild(allDragSprite.removeChildAt(0)));
					cover = tmpWord.cover;
					cover.addEventListener(MouseEvent.MOUSE_DOWN, inComposeAreaMD, false, 0, true);
					cover.addEventListener(MouseEvent.DOUBLE_CLICK, inComposeAreaDD, false, 0, true);
					cover.addEventListener(MouseEvent.CLICK, inComposeAreaMC, false, 0, true);
					cover.addEventListener(MouseEvent.RIGHT_CLICK, inComposeAreaRC, false, 0, true);
					if (tmpWord.parse.match(/^VV/) != null) {
						tmpWord.setModify();
					}
					//その場に入れ込む
					tmpWord.x = composeArea.composeSprite.mouseX + i * 0.05;
					tmpWord.y = composeArea.composeSprite.mouseY;
				}
			}
			removeChild(allDragSprite);
			allDragSprite = null;
			composeArea.alignWords();
		}
		//--▲-左端の丸をドラッグした時の処理-▲--▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
		
		//Wordのクローンを作る
		private function wordClone(target:Word):Word {
			var clone:Word = new Word(target.textField.text);
			clone.setParse(target.parse);
			clone.lemma = target.lemma;
			return clone;
		}
		
		//--▼-単語をドラッグした時の処理-▼--▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		private var preDragWordPoint:Point, movingPoint:Point, insertPoint:Word = new Word(" ");
		private function wordMouseDown(e:MouseEvent):void {
			e.preventDefault();
			var dragWord:Word = wordClone(e.target.parent), p:Point = e.target.localToGlobal(new Point(e.target.x, e.target.y));
			dragWord.x = p.x;
			dragWord.y = p.y;
			addChild(dragWord);
			dragWord.cover.addEventListener(MouseEvent.MOUSE_UP, wordMouseUp, false, 0, true);
			dragWord.cover.addEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove, false, 0, true);
			dragWord.startDrag();
			preDragWordPoint = new Point(dragWord.x, dragWord.y);
			insertPoint.visible = false;
			insertPoint.setParse(Word.INSERT);
			composeArea.composeSprite.addChild(insertPoint);
		}
		
		//-----previewはここで処理
		private function previewMouseMove(e:MouseEvent):void {
			if (!(mouseX > mainWidth - 5 || mouseX < 5 || mouseY > mainHeight - 5 || mouseY < composeArea.y )) {
				insertPoint.visible = true;
				movingPoint = composeArea.composeSprite.globalToLocal(new Point(mouseX, mouseY));
				insertPoint.x = movingPoint.x;
				insertPoint.y = movingPoint.y;
			}else {
				insertPoint.visible = false;
				insertPoint.x = insertPoint.y = 800;
			}
			composeArea.alignWords();
		}//-------------
		
		private function wordMouseUp(e:MouseEvent):void {
			var dragWord:Word = Word(e.target.parent), cover:Sprite = dragWord.cover;
			dragWord.stopDrag();
			cover.removeEventListener(MouseEvent.MOUSE_UP, wordMouseUp);
			cover.removeEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove);
			composeArea.composeSprite.removeChild(insertPoint);
			//閾値以内の移動ならクリックと判定　以上ならドラッグ
			if ( (preDragWordPoint.x - dragWord.x) * (preDragWordPoint.x - dragWord.x) + (preDragWordPoint.y - dragWord.y) * (preDragWordPoint.y - dragWord.y) < 100 && dragWord.y < composeArea.y ) {
				dragWord.x = preDragWordPoint.x;
				dragWord.y = preDragWordPoint.y;
				wordMouseClick(dragWord); //CLICKイベントがうまく取れなかったので少し変更
			}else {
				//ドロップしたところがcomposeArea内なら単語を追加　それ以外なら削除
				if (!(mouseX > mainWidth - 5 || mouseX < 5 || mouseY > mainHeight - 5 || mouseY < composeArea.y )) {
					removeChild(dragWord);
					composeArea.composeSprite.addChild(dragWord);
					dragWord.y = composeArea.composeSprite.globalToLocal(new Point(mouseX, mouseY)).y;
					if (dragWord.parse.match(/^VV/) != null) {
						dragWord.setModify();
					}
					//新しくマウスダウンアップのイベントを割り当てる
					cover.addEventListener(MouseEvent.MOUSE_DOWN, inComposeAreaMD, false, 0, true);
					cover.addEventListener(MouseEvent.MOUSE_UP, inComposeAreaMU, false, 0, true);
					cover.addEventListener(MouseEvent.DOUBLE_CLICK, inComposeAreaDD, false, 0, true);
					cover.addEventListener(MouseEvent.CLICK, inComposeAreaMC, false, 0, true);
					cover.addEventListener(MouseEvent.RIGHT_CLICK, inComposeAreaRC, false, 0, true);
				}else {
					removeChild(dragWord);
					dragWord = null;
				}
			}
			composeArea.alignWords();
		}
		
		//------複数選択--------------------------------------
		private var multiDragWordSprite:Sprite, //選択した単語を貼り付ける
					multiDragWordVector:Vector.<Word>; //単語の語順を守る用
		private function wordMouseClick(word:Word):void {
			if (multiDragWordSprite == null) {
				multiDragWordSprite = new Sprite();
				addChild(multiDragWordSprite);
			}
			removeChild(word);
			var spg:Graphics = multiDragWordSprite.graphics, tmpWord:Word, num:int;
			multiDragWordSprite.addChild(word);
			word.cover.addEventListener(MouseEvent.MOUSE_DOWN, multiDragMouseDown, false, 0, true);
			spg.beginFill(0xff0000, 0.7);
			spg.drawRoundRect(word.x - 3, word.y - 1, word.width + 6, word.height + 2, 10, 10);
			spg.beginFill(0xffffff, 0.7);
			spg.drawRoundRect(word.x - 2, word.y, word.width + 4, word.height, 10, 10);
			spg.endFill();
			
			//右上から左下に向かってソートする　これでどの順番で選択しても，見た目の語順を守れる
			multiDragWordVector = new Vector.<Word>();
			num = multiDragWordSprite.numChildren;
			for (var i:int = 0; i < num; i++) {
				tmpWord = Word(multiDragWordSprite.getChildAt(i));
				//x座標とy座標のウィンドウ幅倍したのを＋1すると右上から左下に向かってソートできる　nameで値を保持する
				tmpWord.name = String(tmpWord.x + tmpWord.y * mainWidth + 1);
				multiDragWordVector.push(tmpWord);
			}
			multiDragWordVector.sort(vectSortName);
		}
		
		private function vectSortName(x:Object, y:Object):Number {return Number(x.name) - Number(y.name);}
		
		private function multiDragMouseDown(e:MouseEvent):void {
			multiDragWordSprite.startDrag();
			multiDragWordSprite.alpha = 0.7;
			e.target.addEventListener(MouseEvent.MOUSE_UP, multiDragMouseUp, false, 0, true);
			e.target.addEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove, false, 0, true);
			insertPoint.setParse(Word.INSERT);
			insertPoint.visible = false;
			composeArea.composeSprite.addChild(insertPoint);
		}
		private function multiDragMouseUp(e:MouseEvent):void {
			var dragWord:Word = Word(e.target.parent);
			multiDragWordSprite.stopDrag();
			e.target.removeEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove);
			composeArea.composeSprite.removeChild(insertPoint);			
			if (!(mouseX > mainWidth - 5 || mouseX < 5 || mouseY > mainHeight - 5 || mouseY < composeArea.y )) {
				var tmpWord:Word, cover:Sprite, num:int = multiDragWordVector.length;
				for (var i:int = 0; i < num; i++) {
					tmpWord = Word(composeArea.composeSprite.addChild(multiDragWordVector.shift()));
					cover = tmpWord.cover;
					cover.removeEventListener(MouseEvent.MOUSE_DOWN, multiDragMouseDown);
					cover.removeEventListener(MouseEvent.MOUSE_UP, multiDragMouseUp);
					cover.addEventListener(MouseEvent.MOUSE_DOWN, inComposeAreaMD, false, 0, true);
					cover.addEventListener(MouseEvent.DOUBLE_CLICK, inComposeAreaDD, false, 0, true);
					cover.addEventListener(MouseEvent.CLICK, inComposeAreaMC, false, 0, true);
					cover.addEventListener(MouseEvent.RIGHT_CLICK, inComposeAreaRC, false, 0, true);
					if (tmpWord.parse.match(/^VV/) != null) {
						tmpWord.setModify();
					}
					//その場に入れ込む 座標は0.05px単位が最小
					tmpWord.x = composeArea.composeSprite.mouseX + i * 0.05;
					tmpWord.y = composeArea.composeSprite.mouseY;
				}
			}
			removeChild(multiDragWordSprite);
			multiDragWordSprite = null;
			composeArea.alignWords();
		}
		
		
		//--▲-単語をドラッグした時の処理-▲--▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
		
		//---▼-composeArea内での処理-▼--▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
		//MD → (MM) → MU → MC → MD → (MM) → MU → DD
		//なんとかしてマウスイベントを……
		private function inComposeAreaMC(e:MouseEvent):void {
			//trace("MC");
		}
		private function inComposeAreaMD(e:MouseEvent):void {
			var word:Word = Word(e.target.parent);
			word.startDrag();
			
			word.cover.addEventListener(MouseEvent.MOUSE_UP, inComposeAreaMU, false, 0, true);
			word.cover.addEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove, false, 0, true);
			insertPoint.visible = true;
			insertPoint.setParse(Word.INSERT);
			composeArea.composeSprite.addChild(insertPoint);
			insertPoint.x = word.x;
			insertPoint.y = word.y;
			word.parent.removeChild(word);
			composeArea.addChild(word);
			//composeArea.alignWords();
		}
		private function inComposeAreaMU(e:MouseEvent):void {
			var word:Word = Word(e.target.parent);
			word.stopDrag();
			word.cover.removeEventListener(MouseEvent.MOUSE_UP, inComposeAreaMU);
			word.cover.removeEventListener(MouseEvent.MOUSE_MOVE, previewMouseMove);
			composeArea.composeSprite.removeChild(insertPoint);
			composeArea.removeChild(word);
			if (!(mouseX > mainWidth - 5 || mouseX < 5 || mouseY > mainHeight - 5 || mouseY < composeArea.y)) {
				composeArea.composeSprite.addChild(word);
				var p:Point = composeArea.composeSprite.globalToLocal(new Point(mouseX, mouseY));
				word.x = p.x;
				word.y = p.y;
			}
			composeArea.alignWords();
		}
		private function inComposeAreaDD(e:MouseEvent):void {
			//編集可能にする
			composeArea.dialogLayerOpen(e.target.parent.textField.text, true, Word(e.target.parent));
		}
		private function inComposeAreaMM(e:MouseEvent):void {
			var sp:Sprite = Sprite(e.target);
			if (mouseX > mainWidth - 5 || mouseX < 5 || mouseY > mainHeight - 5 || mouseY < 5) {
				sp.removeEventListener(MouseEvent.MOUSE_DOWN, inComposeAreaMD);
				sp.removeEventListener(MouseEvent.MOUSE_UP, inComposeAreaMU);
				sp.removeEventListener(MouseEvent.MOUSE_MOVE, inComposeAreaMM);
				composeArea.composeSprite.removeChild(Word(sp.parent));
				composeArea.alignWords();
			}
		}
		
		private function insertWord(e:Event):void {
			var tmp:Word = e.target.getChildAt(e.target.numChildren - 1), cover:Sprite = tmp.cover;
			cover.addEventListener(MouseEvent.MOUSE_DOWN, inComposeAreaMD, false, 0, true);
			cover.addEventListener(MouseEvent.DOUBLE_CLICK, inComposeAreaDD, false, 0, true);
			cover.addEventListener(MouseEvent.CLICK, inComposeAreaMC, false, 0, true);
			cover.addEventListener(MouseEvent.RIGHT_CLICK, inComposeAreaRC, false, 0, true);
			composeArea.alignWords();
		}
		
		//◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
		//人称代名詞，動詞とかの変化
		//右クリック　→　候補が出てくる　→　その候補から選択　→　選択されたものにして元の画面に戻る
		//右クリック時に　必要な候補を検索して全部Wordで出す　クリックされたらそれに決定する処理
		//人称なら人称一覧　動詞ならその動詞の変化形
		private var selectCoverSprite:Sprite = new Sprite(); //候補の部分を明るくする
		private var tmpCoverSprite:Sprite = new Sprite(); //暗く全体を覆う部分
		private var selectingWord:Word;
		private var modifiedForms:Vector.<String>;
		private var nowModifiedHead:int;
		private function inComposeAreaRC(e:MouseEvent):void {
			var tmp:Word = Word(e.target.parent), p:Point = tmp.parent.localToGlobal(new Point(tmp.x, tmp.y));
			selectingWord = tmp;
			selectCoverSprite.x = p.x;
			selectCoverSprite.y = p.y;
			addChild(tmpCoverSprite);
			tmpCoverSprite.x = composeArea.x;
			tmpCoverSprite.y = composeArea.y;
			addChild(selectCoverSprite);
			
			modifiedForms = tmp.modifyVector;
			
			//候補一覧を生成して出す
			var wordVector:Vector.<Word> = new Vector.<Word>(), hogeWord:Word,
				diffNum:int = 22, diffY:int = diffNum, maxWidth:int = 0, cnt:int = 0, g:Graphics;
			hogeWord = wordClone(selectingWord);
			selectCoverSprite.addChild(hogeWord);
			hogeWord.cover.addEventListener(MouseEvent.CLICK, SMFMC, false, 0, true);
			if (hogeWord.textField.width > maxWidth) maxWidth = hogeWord.textField.width;
			
			for each (var item:String in modifiedForms) {
				if (tmp.text == item) continue;
				hogeWord = new Word(item);
				hogeWord.setParse(tmp.parse);
				hogeWord.lemma = tmp.lemma;
				selectCoverSprite.addChild(hogeWord);
				hogeWord.y = diffY;
				diffY += diffNum;
				hogeWord.cover.addEventListener(MouseEvent.CLICK, SMFMC, false, 0, true);
				if (hogeWord.textField.width > maxWidth) maxWidth = hogeWord.textField.width;
				if (++cnt > 3) hogeWord.visible = false;
			}
			
			g = tmpCoverSprite.graphics;
			g.clear();
			g.beginFill(0x000000, 0.3);
			g.drawRoundRect(0, 0, composeArea.areaWidth, composeArea.areaHeight, 5, 5);
			g.endFill();
			tmpCoverSprite.addEventListener(MouseEvent.CLICK, SMFCancel, false, 0, true);
			g = selectCoverSprite.graphics;
			g.clear();
			g.beginFill(0xf5f5f5, 0.7);
			g.drawRoundRect( -5, -6, maxWidth + 10, 103, 5, 5);
			g.endFill();
			nowModifiedHead = 0;
			scrollSpriteSet(selectCoverSprite, maxWidth);
			
		}
		
		//up down Buttonを作る
		private function scrollSpriteSet(sp:Sprite, maxWidth:int):void {
			var upSprite:Sprite = new Sprite(), downSprite:Sprite = new Sprite(), g:Graphics;
			g = upSprite.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect( -4, 0, maxWidth + 8, 8, 5, 5);
			g.endFill();
			g.lineStyle(2, 0x4c4c4c, 0.7);
			g.moveTo(10, 6);
			g.lineTo(maxWidth >> 1, 2);
			g.lineTo(maxWidth - 10, 6);
			g = downSprite.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect( -4, 0, maxWidth + 8, 8, 5, 5);
			g.endFill();
			g.lineStyle(2, 0x4c4c4c, 0.7);
			g.moveTo(10, 2);
			g.lineTo(maxWidth >> 1, 6);
			g.lineTo(maxWidth - 10, 2);
			sp.addChild(upSprite);
			sp.addChild(downSprite);
			downSprite.y = 88;
			upSprite.y = -5;
			upSprite.alpha = 0.3;
			downSprite.alpha = 0.3;
			upSprite.name = "up";
			downSprite.name = "down";
			upSprite.addEventListener(MouseEvent.CLICK, scrollUp, false, 0, true);
			upSprite.addEventListener(MouseEvent.MOUSE_OVER, scrollOver, false, 0, true);
			upSprite.addEventListener(MouseEvent.MOUSE_OUT, scrollOut, false, 0, true);
			downSprite.addEventListener(MouseEvent.CLICK, scrollDown, false, 0, true);
			downSprite.addEventListener(MouseEvent.MOUSE_OVER, scrollOver, false, 0, true);
			downSprite.addEventListener(MouseEvent.MOUSE_OUT, scrollOut, false, 0, true);
		}
		
		private function scrollOver(e:MouseEvent):void {
			if (e.target.name == "up" && selectCoverSprite.numChildren > 6 && nowModifiedHead > 0) {
				e.target.alpha = 1.0;
			}else if (e.target.name == "down" && selectCoverSprite.numChildren > 6 && nowModifiedHead < selectCoverSprite.numChildren - 6) {
				e.target.alpha = 1.0;
			}
		}
		private function scrollOut(e:MouseEvent):void {e.target.alpha = 0.3;}
		private function scrollUp(e:MouseEvent):void {
			if (selectCoverSprite.numChildren > 6 && nowModifiedHead > 0) {
				nowModifiedHead--;
				var tmp:Word, num:int = selectCoverSprite.numChildren - 2;
				for (var i:int = 0; i < num; i++) {
					tmp = Word(selectCoverSprite.getChildAt(i));
					if (i < nowModifiedHead || i > nowModifiedHead + 3) tmp.visible = false;
					else tmp.visible = true;
					tmp.y += 22;
				}
				if (!(selectCoverSprite.numChildren > 6 && nowModifiedHead > 0)) {
					e.target.alpha = 0.3;
				}
			}
		}
		private function scrollDown(e:MouseEvent):void {
			if (selectCoverSprite.numChildren > 6 && nowModifiedHead < selectCoverSprite.numChildren - 6) {
				nowModifiedHead++;
				var tmp:Word, num:int = selectCoverSprite.numChildren - 2;
				for (var i:int = 0; i < num; i++) {
					tmp = Word(selectCoverSprite.getChildAt(i));
					if (i < nowModifiedHead || i > nowModifiedHead + 3) tmp.visible = false;
					else tmp.visible = true;
					tmp.y -= 22;
				}
				if (!(selectCoverSprite.numChildren > 6 && nowModifiedHead < selectCoverSprite.numChildren - 6)) {
					e.target.alpha = 0.3;
				}
			}
		}
		
		//提示された候補をクリックした時の処理
		private function SMFMC(e:MouseEvent):void {
			var tmp:Word = Word(e.target.parent), num:int = selectCoverSprite.numChildren - 2;
			for (var i:int = 0; i < num; i++) {
				Word(selectCoverSprite.getChildAt(i)).cover.removeEventListener(MouseEvent.CLICK, SMFMC);
			}
			selectCoverSprite.removeChildren();
			removeChild(selectCoverSprite);
			removeChild(tmpCoverSprite);
			selectingWord.setParse(tmp.parse);
			selectingWord.changeWord(tmp.text);
			composeArea.alignWords();
		}
		private function SMFCancel(e:MouseEvent):void {
			tmpCoverSprite.removeEventListener(MouseEvent.CLICK, SMFCancel);
			selectCoverSprite.removeChildren();
			removeChild(selectCoverSprite);
			removeChild(tmpCoverSprite);
		}
		//◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
		//--▲--------------------▲-----------------
		
		private function windowResize(e:Event):void {
			stage.nativeWindow.height = stage.nativeWindow.width * ratio;
		}
	}
	
}
