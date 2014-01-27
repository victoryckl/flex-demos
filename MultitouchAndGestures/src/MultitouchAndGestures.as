package
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.GesturePhase;
	import flash.events.TimerEvent;
	import flash.events.TouchEvent;
	import flash.events.TransformGestureEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.Timer;
	
	import org.flexunit.internals.matchers.Each;
	
	[ SWF(backgrouncColor="0xFFFFFF",
		  frameRate="25",
		  width="320",
		  height="480") ]
	
	public class MultitouchAndGestures extends Sprite
	{
		private var coordinates:TextField;
		private var multitouch:TextField;
		private var currentTarget:String;
		private var idleTimer:Timer;
		private var offsetX:Number;
		private var offsetY:Number;
		
		public function MultitouchAndGestures()
		{
			super();
			
			// 支持 autoOrient
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			multitouch = new TextField();
			multitouch.autoSize = TextFieldAutoSize.LEFT;
			
			idleTimer = new Timer(1000);
			idleTimer.addEventListener(TimerEvent.TIMER, onTimer);
			
			switch(Multitouch.supportsTouchEvents)
			{
				case true:
				{
					Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
					multitouch.text = "Touch Supported, max points: " + Multitouch.maxTouchPoints;
					
					stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouch);
					stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouch);
					stage.addEventListener(TouchEvent.TOUCH_END, onTouch);
				}
					break;
				case false:
				{
					multitouch.text = "Not Supported";
				}
					break;
				default:
					break;
			}
			stage.addChild(multitouch);
		}
		
		private function onTouch(e:TouchEvent):void
		{
			var id:Number = e.touchPointID;
			var x:Number = e.stageX;
			var y:Number = e.stageY;
			
			switch(e.type) {
				case TouchEvent.TOUCH_BEGIN:
					if (e.target is Stage) {
						removeShape(id);
						drawLines(id, x, y);
						drawShape(id, x, y);
					} else {
						currentTarget = e.target.name;
						initializeGestures();
					}
					break;
				case TouchEvent.TOUCH_MOVE:
					moveLines(id, x, y);
					drawShape(id, x, y);
					break;
				case TouchEvent.TOUCH_END:
					removeLines(id);
					break;
			}
		}
		
		private function drawLines(id:Number, x:Number, y:Number):void {
			offsetX = x;
			offsetY = y;
			
			var vertical:Sprite = new Sprite();
			vertical.name = id+"v";
			vertical.graphics.lineStyle(2, 0x000000);
			vertical.graphics.moveTo(x, 0);
			vertical.graphics.lineTo(x, stage.stageHeight);
			stage.addChild(vertical);
			
			var horizontal:Sprite = new Sprite();
			horizontal.name = id + "h";
			horizontal.graphics.lineStyle(2, 0x000000);
			horizontal.graphics.moveTo(0, y);
			horizontal.graphics.lineTo(stage.stageWidth, y);
			stage.addChild(horizontal);
			
			setCoordinates(x, y);
		}
		
		private function moveLines(id:Number, x:Number, y:Number):void {
			var vertical:Sprite = Sprite(stage.getChildByName(id + "v"));
			var horizontal:Sprite = Sprite(stage.getChildByName(id + "h"));
			
			vertical.x = x - offsetX;
			horizontal.y = y - offsetY;
			
			setCoordinates(x, y);
		}
		
		private function removeLines(id:Number):void {
			stage.removeChild(Sprite(stage.getChildByName(id + "v")));
			stage.removeChild(Sprite(stage.getChildByName(id + "h")));
			stage.removeChild(coordinates);
			coordinates = null;
		}
		
		private function setCoordinates(x:Number, y:Number):void {
			if (!coordinates) {
				coordinates = new TextField();
				stage.addChild(coordinates);
			}
			coordinates.text =  "("+x+", "+y+")";
			coordinates.x = x-200;
			if (coordinates.x < 0) {
				coordinates.x = x + 100;
			}
			coordinates.y = y-70;
			if (coordinates.y < 0) {
				coordinates.y = y + 100;
			}
		}
		
		private function drawShape(id:Number, x:Number, y:Number):void {
			var shape:Sprite;
			var shapeId:String = "shape01";
//			var shapeId:String = id.toString();
			if (!stage.getChildByName(shapeId)) {
				shape = new Sprite();
				shape.name = shapeId;
				for each(var g:String in Multitouch.supportedGestures) {
					switch(g)
					{
						case TransformGestureEvent.GESTURE_PAN:
							shape.addEventListener(g, onPan);
							break;
						default:
							break;
					}
				}
				stage.addChild(shape);
			} else {
				shape = stage.getChildByName(shapeId) as Sprite;
			}
			
			var width:Number = x - offsetX;
			var height:Number = y - offsetY;
			
			shape.graphics.lineStyle(2, 0x000000, 1.0);
			shape.graphics.beginFill(0x000000, 0.0);
			shape.graphics.drawRect(offsetX, offsetY, width, height);
			shape.graphics.endFill();
		}
		
		private function removeShape(id:Number):void {
			var shapeId:String = "shape01";
//			var shapeId:String = id.toString();
			var shape:Sprite = null;
			shape = stage.getChildByName(shapeId) as Sprite;
			if (shape != null) {
				stage.removeChild(shape);
			}
		}
		
		//--------------------------
		private function onTimer(e:TimerEvent):void {
			idleTimer.stop();
			initializeTouch();
		}
		
		private function initializeTimer():void {
			idleTimer.delay = 1000;
			if (!idleTimer.running) {
				idleTimer.start();
			}
		}
		
		private function initializeGestures():void {
			if (Multitouch.supportsGestureEvents) {
				Multitouch.inputMode = MultitouchInputMode.GESTURE;
				initializeTimer();
			}
		}
		
		private function initializeTouch():void {
			if (Multitouch.supportsTouchEvents) {
				Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			}
		}
		
		private function onPan(e:TransformGestureEvent):void {
			var shape:Sprite = stage.getChildByName(currentTarget) as Sprite;
			switch(e.phase) {
				case GesturePhase.UPDATE:
					shape.x = shape.x + e.offsetX;
					shape.y = shape.y + e.offsetY;
					initializeTimer();
				break;
			}
		}
	}
}