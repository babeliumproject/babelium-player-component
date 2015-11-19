package com.babeliumproject.player.controls.babelia
{
	import flash.events.MouseEvent;
	
	import com.babeliumproject.player.controls.DictionarySkinnableButton;
	import com.babeliumproject.player.events.babelia.RecStopButtonEvent;

	public class RecStopButton extends DictionarySkinnableButton
	{
		public static const REC_STATE:uint=0;
		public static const STOP_STATE:uint=1;

		private var _recMode:Boolean = false;
		private var _state:uint=STOP_STATE;

		public function RecStopButton()
		{
			super("RecStopButton");
		}
		
		override public function dispose():void{
			super.dispose();
			
			//There are no objects that need to be manually disposed
		}

		public function set state(value:uint):void
		{
			_state=value;
			invalidateDisplayList();
		}

		public function get state():uint
		{
			return _state;
		}
		
		public function set recMode(value:Boolean):void
		{
			_recMode=value;
			if(_recMode)
				state = REC_STATE;
		}
		
		public function get recMode():Boolean
		{
			return _recMode;	
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			if (_state == REC_STATE){
				createRecButton();
				_iconDisplay.x=this.width/2;
				_iconDisplay.y=this.height/2;
			}else{
				createStopButton();
				_iconDisplay.x = this.width/2 - _iconDisplay.width/2;
				_iconDisplay.y = this.height/2 - _iconDisplay.height/2;
			}
			
			addChild(_iconDisplay);
		}

		private function createRecButton():void
		{
			_iconDisplay.graphics.clear();
			_iconDisplay.graphics.beginFill(0xFF0000);
			_iconDisplay.graphics.drawCircle(0, 0, 5);
			_iconDisplay.graphics.endFill();
		}

		private function createStopButton():void
		{
			_iconDisplay.graphics.clear();
			_iconDisplay.graphics.beginFill(getSkinColor(COLOR));
			_iconDisplay.graphics.drawRect(0, 0, 10, 10);
			_iconDisplay.graphics.endFill();
		}

		override protected function onClick(e:MouseEvent):void
		{
			var cstate:uint=_state;
			if(_recMode){
				state = (_state == REC_STATE) ? STOP_STATE : REC_STATE;
			}
			dispatchEvent(new RecStopButtonEvent(RecStopButtonEvent.CLICK,cstate));
		}
	}
}
