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
		
		protected var iconVolumeMute:Object;
		protected var iconVolumeMedium:Object;
		protected var iconVolumeHigh:Object;

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
			
			iconVolumeMute = {
				'commands': [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2],
				'data': [10, 5.995, 11.05, 5.005, 13.18, 7.015, 15.31, 5.005, 16.37, 5.995, 14.230, 8.005, 16.37, 10.005, 15.310, 10.995, 13.18, 8.995, 11.05, 10.995, 10, 10.005, 12.13, 8.005, 10, 5.995, 10, 5.995, 0, 5, 0, 11, 4, 11, 9, 16, 9, 0, 4, 5, 0, 5, 0, 5]
			};
				
			iconVolumeMedium = {
				'commands': [1, 2, 2, 2, 2, 2, 1, 6, 2, 6, 2],
				'data': [0, 5, 0, 11, 4, 11, 9, 16, 9, 0, 4, 5, 13.5, 8, 13.5, 6.23, 12.5, 4.71, 11, 3.97, 11, 12, 12.5, 11.29, 13.5, 9.76, 13.5, 8, 13.5, 8]
			};
			
			iconVolumeHigh = {
				'commands': [1, 2, 6, 6, 2, 6, 6, 1, 6, 2, 6, 1, 2, 2, 2, 2, 2, 2, 2],
				'data': [11, 0, 11, 2.06, 13.89, 2.92, 16, 5.6, 16, 8.77, 16, 11.94, 13.89, 14.61, 11, 15.47, 11, 17.54, 15, 16.63, 18, 13.05, 18, 8.77, 18, 4.49, 15, 0.91, 11, 0, 13.5, 8.77, 13.5, 7, 12.5, 5.48, 11, 4.74, 11, 12.77, 12.5, 12.06, 13.5, 10.53, 13.5, 8.77, 0, 5.77, 0, 11.77, 4, 11.77, 9, 16.77, 9, 0.77, 4, 5.77, 0, 5.77, 0, 5.77]
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
				drawIcon(_iconDisplay, iconVolumeHigh);
				drawIcon(_iconDisplayHover, iconVolumeHigh, 'Hover');
				drawIcon(_iconDisplayActive, iconVolumeHigh, 'Active');
			}
			else
			{
				drawIcon(_iconDisplay, iconVolumeMute);
				drawIcon(_iconDisplayHover, iconVolumeMute, 'Hover');
				drawIcon(_iconDisplayActive, iconVolumeMute, 'Active');
			}

			_iconDisplay.height=14;
			_iconDisplay.scaleX=_iconDisplay.scaleY;
			_iconDisplayHover.height=14;
			_iconDisplayHover.scaleX=_iconDisplayHover.scaleY;
			_iconDisplayActive.height=14;
			_iconDisplayActive.scaleX=_iconDisplayActive.scaleY;

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
