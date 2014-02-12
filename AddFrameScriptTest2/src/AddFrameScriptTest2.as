package
{
	import com.codeazur.as3swf.SWF;
	import com.codeazur.as3swf.tags.TagFileAttributes;
	
	import flash.display.AVM1Movie;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.net.URLLoader;
	
	public class AddFrameScriptTest2 extends Sprite
	{
		public function AddFrameScriptTest2()
		{
			super();
			
			// 支持 autoOrient
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			initPath();
		}
		
		private var swfLoader:Loader = new Loader();
		private function initLoader():void {
			swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
			swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadIOError);
			swfLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadSecurityError);
			
			var url:String = jointUrl(pathXml.url);
			trace("url: "+url);
			swfLoader.load(new URLRequest(url));
			stage.addChild(swfLoader);
		}
		
		private function loadComplete(e:Event):void {
			trace("loadComplete()");
			if (swfLoader.content is MovieClip) {
				trace(swfLoader.loaderInfo.url + "is as3 MovieClip");
				
				var mc:MovieClip = swfLoader.content as MovieClip;
				mc.addFrameScript(mc.totalFrames - 1, swfLoader.unloadAndStop);
			} else if (swfLoader.content is AVM1Movie) {
				trace(swfLoader.loaderInfo.url + "is as2 MovieClip");
				
				var swf:SWF = new SWF(swfLoader.content.loaderInfo.bytes);
				var tagFile:TagFileAttributes = swf.tags[0] as TagFileAttributes;
				tagFile.actionscript3 = true;
				var newByte:ByteArray = new ByteArray();
				swf.publish(newByte);
				
				var lc:LoaderContext = new LoaderContext();
				lc.allowCodeImport = true;
				swfLoader.loadBytes(newByte, lc);
			}
		}
		
		private function loadIOError(e:IOErrorEvent):void {
			trace("swfLoader loadIOError, "+e.toString());
		}
		
		private function loadSecurityError(e:SecurityErrorEvent):void {
			trace("swfLoader loadSecurityError, "+e.toString());
		}
		
		//--------------
		private var pathXml:XML = null;
		private function initPath():void {
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, function(e:Event):void {
				trace("xml load complete, \n"+e.target.data);
				pathXml = XML(e.target.data);
				initLoader();
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
				trace("io error, "+e.toString());
			});
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void {
				trace("security error, "+e.toString());
			});
			loader.load(new URLRequest(jointUrl("data/path.xml")));
		}
		
		private function getRootUrl():String {
			return File.documentsDirectory.url+File.separator;
		}
		
		private function jointUrl(name:String):String {
			return getRootUrl()+name;
		}
	}
}