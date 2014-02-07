package
{
	public class Greeter
	{
		private static var validNames:Array = ["Sammy", "Frank", "Dean"];
		
		public function sayHello(userName:String = ""):String {
			var greeting:String;
			if (userName == "") {
				greeting = "Hello. Please type your user name, and then press the Enter key.";
			} else if (validName(userName)) {
				greeting = "Hello, " + userName + ".";
			} else {
				greeting = "Sorry " + userName +", you are not on the list."; 
			}
			return greeting;
		}
		
		private function validName(userName:String):Boolean {
			return validNames.indexOf(userName) > -1 ? true : false;
		}
	}
}