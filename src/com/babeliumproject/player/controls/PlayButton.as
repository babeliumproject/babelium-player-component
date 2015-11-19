package com.babeliumproject.player.controls
{
	import flash.display.GraphicsPathCommand;
	import flash.display.Sprite;
	
	import mx.utils.ObjectUtil;
	
	public class PlayButton extends DictionarySkinnableButton
	{

		public static const PLAY_STATE:String = "play";
		public static const PAUSE_STATE:String = "pause";
	
		private var _state:String = PLAY_STATE;
		
		protected var iconPlay:Object;
		protected var iconPause:Object;
		
		public function PlayButton()
		{
			super("PlayButton");
			
			//commands: 1=move_to, 2=line_to, 3=curve_to		
			iconPlay = {
				'commands': [2,2,2],
				'data': [10,5,0,10,0,0]
			};
			iconPause = {
				'commands': [2,2,2,2,1,2,2,2,2],
				'data': [0,10,3,10,3,0,0,0,6,0,6,10,9,10,9,0,6,0]
			};
		}
		
		override public function dispose():void{
			super.dispose();
			
			//There are no objects that need to be manually disposed
		}
		
		public function set state(value:String):void
		{
			if(value && _state != value){
				_state = value;
				invalidateDisplayList();
			}
		}
		
		public function get state():String{
			return _state;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			if( _state == PLAY_STATE ){
				drawIcon(_iconDisplay,iconPlay);
				drawIcon(_iconDisplayHover,iconPlay,'Hover');
				drawIcon(_iconDisplayActive,iconPlay,'Active');
			} else {
				drawIcon(_iconDisplay,iconPause);
				drawIcon(_iconDisplayHover,iconPause,'Hover');
				drawIcon(_iconDisplayActive,iconPause,'Active');
			}
			
			_iconDisplay.width=14;
			_iconDisplay.height=14;
			_iconDisplayHover.width=14;
			_iconDisplayHover.height=14;
			_iconDisplayActive.width=14;
			_iconDisplayActive.height=14;
			
			var wc:Number=this.width/2;
			var hc:Number=this.height/2;
			
			_iconDisplay.x = wc - _iconDisplay.width/2;
			_iconDisplay.y = hc - _iconDisplay.height/2;
			_iconDisplayHover.x=wc - _iconDisplayHover.width/2;
			_iconDisplayHover.y=hc - _iconDisplayHover.height/2;
			_iconDisplayActive.x=wc - _iconDisplayActive.width/2;
			_iconDisplayActive.y=hc - _iconDisplayActive.height/2;
		}
	}
}
