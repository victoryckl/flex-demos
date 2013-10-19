package org.rjb.control
{
	import com.adobe.cairngorm.control.FrontController;
	
	import org.rjb.event.LoginEvent;
    import org.rjb.command.LoginCommand;
    
	public class LoginControl extends FrontController
	{
		public function LoginControl(){
			this.initialiseCommands();
		}
		
		public function initialiseCommands():void{
			this.addCommand(LoginEvent.LOGIN_EVENT,LoginCommand);
		}
	}
}