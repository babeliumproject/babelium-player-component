package com.babeliumproject.player.controls.babelia
{
	import com.babeliumproject.player.events.babelia.SubtitlingEvent;
	import com.babeliumproject.player.controls.DictionarySkinnableButton;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class SubtitleEndButton extends DictionarySkinnableButton
	{		
		public function SubtitleEndButton()
		{
			super("SubtitleEndButton");
		}
		
		override public function dispose():void{
			super.dispose();
			
			//There are no objects that need to be manually disposed
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			createBtn();
		}
		
		
		private function createBtn() : void
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
			dispatchEvent( new SubtitlingEvent( SubtitlingEvent.END ) );
		}
		
	}
}