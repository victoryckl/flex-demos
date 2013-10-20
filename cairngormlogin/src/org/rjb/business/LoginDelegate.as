package org.rjb.business
{
	import mx.rpc.IResponder;
	
	import org.rjb.vo.UserVO;
	
	public class LoginDelegate
	{
		public var responder:IResponder;
		public function LoginDelegate(responder:IResponder){
			this.responder=responder;
		}
		public function login(userVO:UserVO):void{
			var result:Object;
			if(userVO.userName=="root"&&userVO.password=="123"){
				result="OK";
			}else{
				result="Fail";
			}
			responder.result(result);
		}
	}
}