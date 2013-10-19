package org.rjb.command
{
	import com.adobe.cairngorm.commands.ICommand;
	import com.adobe.cairngorm.control.CairngormEvent;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.rpc.IResponder;
	import mx.rpc.events.ResultEvent;
	
	import org.rjb.business.LoginDelegate;
	import org.rjb.event.LoginEvent;
	import org.rjb.model.UserModelLocator;

	public class LoginCommand implements ICommand, IResponder
	{
		public var userModelLocator:UserModelLocator=UserModelLocator.getInstance();
		
		public function LoginCommand(){
			
		}

		public function execute(event:CairngormEvent):void{
			var loginDelegate:LoginDelegate=new LoginDelegate(this);
			var loginEvent:LoginEvent=LoginEvent(event);
			loginDelegate.login(loginEvent.userVO);
		}
		
		public function result(data:Object):void{
			var result:String=data.toString();
			if(result=="OK"){
				mx.core.Application.application.loginPanel.currentState="success";
				userModelLocator.state="Login---Result";
			}else{
				mx.core.Application.application.loginPanel.currentState="fail";
			    userModelLocator.state="Login---Result";
			}
		}
		
		public function fault(info:Object):void{
			mx.controls.Alert.show(info+"");
		}
		
	}
}