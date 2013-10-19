package org.rjb.event
{
	import com.adobe.cairngorm.control.CairngormEvent;
	
	import flash.events.Event;
	
	import org.rjb.vo.UserVO;

	public class LoginEvent extends CairngormEvent
	{
		public static const LOGIN_EVENT:String="login";
		public var userVO:UserVO;
		public function LoginEvent(userVO:UserVO)
		{
			super(LOGIN_EVENT);
			this.userVO=userVO;
		}
		
		override public function clone():Event
		{
			return new LoginEvent(userVO);
		}			
	}
}