package com.babeliumproject.player.controls
{
	import com.babeliumproject.player.events.StopEvent;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class StopButton extends DictionarySkinnableButton
	{		
		public function StopButton()
		{
			super("StopButton");
		}
		
		override public function dispose():void{
			super.dispose();
			
			//There are no objects that need to be manually disposed
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			createStopBtn();
			_iconDisplay.x = this.width/2 - _iconDisplay.width/2;
			_iconDisplay.y = this.height/2 - _iconDisplay.height/2;
			addChild(_iconDisplay);
		}
		
		private function createStopBtn() : void
		{
			var g:Sprite = _iconDisplay;
			g.graphics.clear();
			g.graphics.beginFill( getSkinColor(COLOR) );
			g.graphics.drawRect( 0, 0, 10, 10 );
			g.graphics.endFill();
		}

		override protected function onClick( e:MouseEvent ) : void
		{
			dispatchEvent( new StopEvent( StopEvent.STOP_CLICK ) );
		}
		
	}
}
