package model.vo
{
	public class MediaItemVO {
		public var title:String;
		public var description:String;
		
		[Bindable]
		public var url:String;
		public var duration:String;
		
		public function MediaItemVO() {
		}
	}
}