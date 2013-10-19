package org.rjb.model
{
	import com.adobe.cairngorm.model.ModelLocator;
	
	import org.rjb.vo.UserVO;
    [Bindable]
	public class UserModelLocator implements ModelLocator
	{
		//存放vo对象
		public var userVO:UserVO;
		//存放一些状态变量
		public var state:String="User---Login";
		//单例对象
		private static var modelLocator:UserModelLocator;
		
		public static function getInstance():UserModelLocator{
			if(modelLocator==null){
				modelLocator=new UserModelLocator(new SingleClass());
			}
			return modelLocator;
		}
		
		public function UserModelLocator(single:SingleClass){
			if(single==null){
				throw new Error( "You Can Only Have One UserModelLocator" );
			}
			
		}
	}
}
class SingleClass{}