package com.babeliumproject.player.controls.babelia
{
	import com.babeliumproject.player.ResourceData;
	import com.babeliumproject.player.controls.DictionarySkinnableButton;
	import com.babeliumproject.player.events.babelia.SubtitlingEvent;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class SubtitleStartEndButton extends DictionarySkinnableButton
	{
		/**
		 * Constants
		 */
		public static const START_STATE:String = "start";
		public static const END_STATE:String = "end";
		
		/**
		 * Variables
		 * 
		 */
		private var _state:String = START_STATE;
		
		
		public function SubtitleStartEndButton()
		{
			super("SubtitleStartEndButton");
		}
		
		override public function dispose():void{
			super.dispose();
			
			//There are no objects that need to be manually disposed
		}
		
		public function set State( state:String ):void
		{
			_state = state;
			
			invalidateDisplayList();
		}
		
		public function getState( ):String
		{
			return _state;
		}
		

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			if( _state == START_STATE )
			{
				CreateStartButton();
				_iconDisplay.x = this.width/2 - _iconDisplay.width/2;
				_iconDisplay.y = this.height/2 - _iconDisplay.height/2;
				this.toolTip = resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SUBTITLE_START_TIME_TOOLTIP');
			}
			else
			{
				CreateEndButton();
				_iconDisplay.x = this.width/2 - _iconDisplay.width/2;
				_iconDisplay.y = this.height/2 - _iconDisplay.height/2;
				this.toolTip = resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SUBTITLE_STOP_TIME_TOOLTIP');
			}
			addChild(_iconDisplay);
		}
		
		
		private function CreateStartButton():void
		{
			var g:Sprite = _iconDisplay;
			g.graphics.clear();
			g.graphics.beginFill( getSkinColor(COLOR) );
			g.graphics.moveTo( 0, 5 );
			g.graphics.lineTo( 5, 0 );
			g.graphics.lineTo( 5, 3 );
			g.graphics.lineTo( 12, 3 );
			g.graphics.lineTo( 12, 5 );
			g.graphics.endFill();
		}
		
		
		private function CreateEndButton():void
		{
			var g:Sprite = _iconDisplay;
			g.graphics.clear();
			g.graphics.beginFill( getSkinColor(COLOR) );
			g.graphics.moveTo( 0, 5 );
			g.graphics.lineTo( 12, 5 );
			g.graphics.lineTo( 7, 0 );
			g.graphics.lineTo( 7, 3 );
			g.graphics.lineTo( 0, 3 );
			g.graphics.endFill();
		}
		
		
		override protected function onClick( e:MouseEvent ) : void
		{
			trace( "Subtitle start/end button pressed." );
			if (_state == START_STATE){
				this.State = END_STATE;
				dispatchEvent( new SubtitlingEvent( SubtitlingEvent.START ) );
			} else {
				this.State = START_STATE;
				dispatchEvent( new SubtitlingEvent( SubtitlingEvent.END ) );
			}
		}
		
		
	}
}
