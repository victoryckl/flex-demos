package
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	public class LoadSwf extends Sprite
	{
		var swfLoader:Loader = new Loader();
		
		public function LoadSwf()
		{
			super();
			
			swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
			swfLoader.load(new URLRequest("file:///sdcard/4.swf"));
		}
		
		private function loadComplete(e:Event):void {
			trace("loadComplete()");
			centerAndFull(swfLoader, e);
			
			swfLoader.mask = getMasker(swfLoader);
			addChild(swfLoader.mask);
			addChild(swfLoader);
		}
		
		//-----------------------
		private function getMasker(o:DisplayObject):Shape {
			var masker:Shape = new Shape();
			masker.graphics.beginFill(0xffffff);
			masker.graphics.drawRect(o.x, o.y, o.width, o.height);
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
	}
}