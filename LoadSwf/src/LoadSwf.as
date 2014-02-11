package
{
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	
	import flashx.textLayout.events.ModelChange;
	
	public class LoadSwf extends Sprite
	{
		private var swfLoader:Loader = new Loader();
		private var swfMC:MovieClip = null;
		private var pathXml:XML = null;
		
		public function LoadSwf()
		{
			super();
			initStage();
			initPath();
		}
		
		//--------------------------------
		private function initStage():void {
//			stage.color = 0x00000;
			stage.addEventListener(Event.ACTIVATE, onActivate);
			stage.addEventListener(Event.DEACTIVATE, onDeActivate);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
		
		private function onKeyUp(event:KeyboardEvent):void {
			trace("onKeyUp(), "+event.keyCode);
			swfStop();
		}
		
		private function onDeActivate(e:Event):void {
			trace("onDeActivate()");
			swfPause();
		}
		
		private function onActivate(e:Event):void {
			trace("onActivate()");
			swfResume();
		}
		
		//---------------------------------
		private function initLoader():void {
			swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
			swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadIOError);
			swfLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadSecurityError);
			trace("url: "+pathXml.url);
			swfLoader.load(new URLRequest(pathXml.url));
		}
		
		private function swfResume():void {
//			if (swfMC != null) {
//				swfMC.play();
//			}
		}
		
		private function swfPause():void {
//			if (swfMC != null) {
//				swfMC.stop();
//			}
			swfStop();
		}
		
		private function swfStop():void {
			swfLoader.unloadAndStop();
			NativeApplication.nativeApplication.exit();
		}
		
		private function loadComplete(e:Event):void {
			trace("loadComplete()");
			centerAndFull(swfLoader, e);
			
			swfLoader.mask = getMasker(swfLoader, e);
			stage.addChild(swfLoader.mask);
			
			stage.addChild(swfLoader);
			swfMC = swfLoader as MovieClip;
		}
		
		private function loadIOError(e:IOErrorEvent):void {
			trace("swfLoader loadIOError, "+e.toString());
		}
		
		private function loadSecurityError(e:SecurityErrorEvent):void {
			trace("swfLoader loadSecurityError, "+e.toString());
		}
		
		//-----------------------
		private function getMasker(o:DisplayObject, e:Event):Shape {
			var li:LoaderInfo = LoaderInfo(e.target);
			
			var masker:Shape = new Shape();
			masker.graphics.beginFill(0xff0000);
			masker.graphics.drawRect(o.x, o.y, li.width*o.scaleX, li.height*o.scaleY);
			masker.graphics.endFill();
			return masker;
		}
		
		private function traceInfo(o:DisplayObject):void {
			trace("x:"+o.x+", y:"+o.y
				+ "\nw:"+o.width +", h:" + o.height
				+ "\nsx:" + o.scaleX +", sy:"+o.scaleY+", sz:"+o.scaleZ);
		}
		
		private function centerAndFull(o:DisplayObject, e:Event):void {
			traceInfo(o);
			var loadInfo:LoaderInfo = LoaderInfo(e.target);
			
			//full
			var scalex:Number = stage.stageWidth / loadInfo.width;
			var scaley:Number = stage.stageHeight / loadInfo.height;
			var scale:Number = scalex < scaley ? scalex : scaley;
			o.width *= scale;
			o.height *= scale;
			
			//center
			o.x = (stage.stageWidth - loadInfo.width*scale) / 2;
			o.y = (stage.stageHeight - loadInfo.height*scale) / 2;
			
			traceInfo(o);
		}
		
		//-----------------------
		private function initPath():void {
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, function(e:Event):void {
				trace("xml load complete, "+e.target.data);
				pathXml = XML(e.target.data);
				initLoader();
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
				trace("io error, "+e.toString());
			});
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void {
				trace("security error, "+e.toString());
			});
			loader.load(new URLRequest("file:///sdcard/path.xml"));
		}
	}
}