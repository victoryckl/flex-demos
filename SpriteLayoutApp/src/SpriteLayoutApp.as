package
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.StageOrientationEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class SpriteLayoutApp extends Sprite
	{
		private static const BLUE:int = 0x3399ff;
		private static const GREEN:int = 0x99cc00;
		private static const YELLOW:int = 0xffcc00;
		private static const RED:int = 0xff3333;
		
		private var a:Sprite;
		private var b:Sprite;
		private var c:Sprite;
		private var d:Sprite;
		
		private var stageOnrientation:TextField;
		
		public function SpriteLayoutApp()
		{
			super();
			
			// 支持 autoOrient
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, 
									onOrientationChange);
			
			drawSprites();
			addTextField();
		}
		
		private function onResize(e:Event):void {
			var w:int = Stage(e.target).stageWidth;
			var h:int = Stage(e.target).stageHeight;
			
			sizeComponts(w, h);
			layoutComponts(w, h);
		}
		
		private function sizeComponts(w:int, h:int):void {
			trace("sizeComponts()");
			if (w < h) {
				a.width = w/2;
				a.height = h/3;
				
				b.width = w/2;
				b.height = h/3;
				
				c.width = w;
				c.height = h - h/3 - h/6;
				
				d.width = w;
				d.height = h/6;
			} else {
				d.width = w;
				d.height = h/6;
				
				a.width = w/2;
				a.height = (h - d.height) / 2;
				
				b.width = a.width;
				b.height = a.height;
				
				c.width = a.width;
				c.height = h - d.height;
			}
		}
		
		private function layoutComponts(w:int, h:int):void {
			if (w < h) {
				a.x = 0;
				a.y = 0;
				
				b.x = a.x + a.width;
				b.y = 0;
				
				c.x = 0;
				c.y = a.y + a.height;
				
				d.x = 0;
				d.y = c.y + c.height;
			} else {
				a.x = 0;
				a.y = 0;
				
				b.x = 0;
				b.y = a.y + a.height;
				
				c.x = a.x + a.width;
				c.y = 0;
				
				d.x = 0;
				d.y = h - d.height;
			}
		}
		
		private function getSprite(id:String):Sprite {
			return stage.getChildByName(id) as Sprite;
		}
		
		private function drawSprites():void {
			trace("drawSprites()");
			a = drawRectangle("a", 1, 1, BLUE);
			b = drawRectangle("b", 1, 1, GREEN);
			c = drawRectangle("c", 1, 1, YELLOW);
			d = drawRectangle("d", 1, 1, RED);
		}
		
		private function drawRectangle(id:String, w:int, h:int, color:int):Sprite {
			var sprite:Sprite = new Sprite();
			sprite.name = id;
			sprite.graphics.beginFill(color);
			sprite.graphics.drawRect(0, 0, w, h);
			sprite.graphics.endFill();
			stage.addChild(sprite);
			return sprite;
		}
		
		//-----------------------
		private function addTextField():void {
			var tf:TextFormat = new TextFormat();
			
			stageOnrientation = new TextField();
			stageOnrientation.setTextFormat(tf);
			stageOnrientation.text = "";
			
			stage.addChild(stageOnrientation);
		}
		
		private function onOrientationChange(e:StageOrientationEvent):void {
			stageOnrientation.text = Stage(e.target).deviceOrientation;
		}
	}
}