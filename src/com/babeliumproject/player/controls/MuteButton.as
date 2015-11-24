package com.babeliumproject.player.controls
{
	import flash.events.MouseEvent;

	public class MuteButton extends DictionarySkinnableButton
	{
		public static const MUTE:String="mute";
		public static const UNMUTE:String="unMute";

		private var _state:String=MUTE;

		protected var iconMute:Object;
		protected var iconUnMute:Object;

		public function MuteButton()
		{
			super("MuteButton");

			iconMute={
				'commands': [1, 2, 2, 2, 2, 1, 2, 2, 2],
				'data': [0, 2, 0, 8, 3, 8, 3, 2, 0, 2, 5, 2, 9, 0, 9, 10, 5, 8]
			};

			iconUnMute={
				'commands': [1, 2, 2, 2, 2, 1, 2, 2, 2],
				'data': [0, 2, 0, 8, 3, 8, 3, 2, 0, 2, 5, 2, 9, 0, 9, 10, 5, 8]
			};
		}

		override public function dispose():void
		{
			super.dispose();
		}

		public function set state(value:String):void
		{
			if (value && _state != value)
			{
				_state=value;
				invalidateDisplayList();
			}
		}

		public function get state():String
		{
			return _state;
		}

		override protected function onClick(e:MouseEvent):void
		{

		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			if (_state == MUTE)
			{
				drawIcon(_iconDisplay, iconMute);
				drawIcon(_iconDisplayHover, iconMute, 'Hover');
				drawIcon(_iconDisplayActive, iconMute, 'Active');
			}
			else
			{
				drawIcon(_iconDisplay, iconUnMute);
				drawIcon(_iconDisplayHover, iconUnMute, 'Hover');
				drawIcon(_iconDisplayActive, iconUnMute, 'Active');
			}

			_iconDisplay.width=14;
			_iconDisplay.height=14;
			_iconDisplayHover.width=14;
			_iconDisplayHover.height=14;
			_iconDisplayActive.width=14;
			_iconDisplayActive.height=14;

			var wc:Number=this.width / 2;
			var hc:Number=this.height / 2;

			_iconDisplay.x=wc - _iconDisplay.width / 2;
			_iconDisplay.y=hc - _iconDisplay.height / 2;
			_iconDisplayHover.x=wc - _iconDisplayHover.width / 2;
			_iconDisplayHover.y=hc - _iconDisplayHover.height / 2;
			_iconDisplayActive.x=wc - _iconDisplayActive.width / 2;
			_iconDisplayActive.y=hc - _iconDisplayActive.height / 2;
		}
	}
}
