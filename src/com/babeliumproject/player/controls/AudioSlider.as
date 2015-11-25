package com.babeliumproject.player.controls
{
	import com.babeliumproject.player.events.VolumeEvent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.charts.CategoryAxis;
	import mx.effects.AnimateProperty;
	import mx.events.EffectEvent;

	public class AudioSlider extends DictionarySkinnableComponent
	{
		public static const BG_COLOR:String="bgColor";
		public static const BARBG_COLOR:String="barBgColor";
		public static const BAR_COLOR:String="barColor";
		public static const SCRUBBER_COLOR:String="scrubberColor";
		public static const SCRUBBERBORDER_COLOR:String="scrubberBorderColor";

		private var _barMarginX:uint=5;
		private var _barMarginY:uint=5;

		private var _bar:Sprite;
		private var _barFill:Sprite;
		private var _scrubber:Sprite;

		private var _defaultY:Number=0;
		private var _defaultX:Number=0;

		private var a1:AnimateProperty;
		private var a2:AnimateProperty;

		private var _currentVolume:Number=0.5;
		
		private var _muted:Boolean=false;
		private var _mutedX:Number=0;
		private var _doingMute:Boolean=false;

		public var muteBtn:MuteButton;

		
		public function AudioSlider(initialVolume:Number)
		{
			super("AudioSlider");

			_currentVolume=initialVolume;

			muteBtn=new MuteButton();
			muteBtn.height=26;
			muteBtn.width=26;
			
			_bar=new Sprite();
			_bar.useHandCursor=true;
			_bar.buttonMode=true;

			_barFill=new Sprite();
			_barFill.useHandCursor=true;
			_barFill.buttonMode=true;

			_scrubber=new Sprite();
			_scrubber.useHandCursor=true;
			_scrubber.buttonMode=true;

			addChild(muteBtn);
			addChild(_bar);
			addChild(_barFill);
			addChild(_scrubber);

			//EventListeners
			_scrubber.addEventListener(MouseEvent.MOUSE_DOWN, onScrubberMouseDown);
			_bar.addEventListener(MouseEvent.CLICK, onAreaClick);
			_barFill.addEventListener(MouseEvent.CLICK, onAreaClick);
			
			muteBtn.addEventListener(MouseEvent.CLICK, muteClicked);
		}

		override public function dispose():void
		{
			super.dispose();
			if (_scrubber)
			{
				_scrubber.removeEventListener(MouseEvent.MOUSE_DOWN, onScrubberMouseDown);
				removeChildSuppressed(_scrubber);
				_scrubber=null;
			}
			if (_bar)
			{
				_bar.removeEventListener(MouseEvent.CLICK, onAreaClick);
				removeChildSuppressed(_bar);
				_bar=null;
			}
			if (_barFill)
			{
				_barFill.removeEventListener(MouseEvent.CLICK, onAreaClick);
				removeChildSuppressed(_barFill);
				_barFill=null;
			}
			if (muteBtn)
			{
				muteBtn.removeEventListener(MouseEvent.CLICK, muteClicked);
				removeChildSuppressed(muteBtn);
				muteBtn=null;
			}
			if (a1)
			{
				a1.removeEventListener(EffectEvent.EFFECT_END, volumeChanged);
				a1.removeEventListener(EffectEvent.EFFECT_END, muteClickVolumeChange);
				a1.stop();
				a1=null;
			}
			if (a2)
			{
				a2.stop();
				a2=null;
			}

			//These two should have been removed when the dragging ended, but just in case
			this.parentApplication.removeEventListener(MouseEvent.MOUSE_UP, onScrubberDrop);
			this.removeEventListener(Event.ENTER_FRAME, updateAmount);

		}

		public function getCurrentVolume():Number
		{
			return _currentVolume;
		}

		public function get muted():Boolean
		{
			return _muted;
		}

		public function set muted(value:Boolean):void
		{
			if (value == _muted)
				return;

			_bar.useHandCursor=!value;
			_bar.buttonMode=!value;

			_barFill.useHandCursor=!value;
			_barFill.buttonMode=!value;

			_scrubber.useHandCursor=!value;
			_scrubber.buttonMode=!value;

			muteBtn.useHandCursor=!value;
			muteBtn.buttonMode=!value;

			if (!value)
			{
				_scrubber.addEventListener(MouseEvent.MOUSE_DOWN, onScrubberMouseDown);
				_bar.addEventListener(MouseEvent.CLICK, onAreaClick);
				_barFill.addEventListener(MouseEvent.CLICK, onAreaClick);
	
				muteBtn.addEventListener(MouseEvent.CLICK, muteClicked);
			}
			else
			{
				_scrubber.removeEventListener(MouseEvent.MOUSE_DOWN, onScrubberMouseDown);
				_bar.removeEventListener(MouseEvent.CLICK, onAreaClick);
				_barFill.removeEventListener(MouseEvent.CLICK, onAreaClick);
				muteBtn.removeEventListener(MouseEvent.CLICK, muteClicked);
			}

			muteClicked(null); // Click event
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			var _barWidth:int=width - muteBtn.width - (_barMarginX * 2);
			var _barHeight:int=10;
			
			_barMarginY=(height-_barHeight)/2;

			createBox(_bar, getSkinColor(BARBG_COLOR), _barWidth, _barHeight, false, 0, 0, 1);
			_bar.x=muteBtn.width + _barMarginX;
			_bar.y=_barMarginY;

			createBox(_scrubber, getSkinColor(SCRUBBER_COLOR), _barHeight + 1, _barHeight + 1, true, getSkinColor(SCRUBBERBORDER_COLOR));

			var volW:Number=_currentVolume * (_barWidth - _scrubber.width);
			var _volAmountWidth:Number=Number(volW.toFixed(0));
			var _volAmountHeight:Number=_barHeight;

			_defaultX=_bar.x;
			_defaultY=_scrubber.y=height / 2 - _scrubber.height / 2;
			_scrubber.x=_bar.x + _volAmountWidth;


			createBox(_barFill, getSkinColor(BAR_COLOR), _volAmountWidth, _volAmountHeight, false, 0, 0, 1);
			_barFill.x=_bar.x;
			_barFill.y=_bar.y;

			trace("[Volume display changed] CurrentVolume: " + _currentVolume * 100 + "%, AmountBar: " + _volAmountWidth + "/" + _barWidth);
		}

		private function createBox(b:Sprite, color:Object, bWidth:Number, bHeight:Number, border:Boolean=false, borderColor:uint=0, borderSize:Number=1, alpha:Number=1):void
		{
			b.graphics.clear();
			b.graphics.beginFill(color as uint, alpha);
			if (border)
				b.graphics.lineStyle(borderSize, borderColor);
			b.graphics.drawRect(0, 0, bWidth, bHeight);
			b.graphics.endFill();
		}


		private function onScrubberMouseDown(e:MouseEvent):void
		{
			addEventListener(Event.ENTER_FRAME, updateAmount);

			var rx:int=_bar.x;
			var ry:int=_defaultY;
			var rwidth:int=_bar.width-_scrubber.width;
			var rheight:int=0;
			var draggingRectangle:Rectangle=new Rectangle(rx,ry,rwidth,rheight);
			
			_scrubber.startDrag(false, draggingRectangle);

			this.parentApplication.addEventListener(MouseEvent.MOUSE_UP, onScrubberDrop);
		}


		private function onScrubberDrop(e:MouseEvent):void
		{
			_muted=false;

			this.parentApplication.removeEventListener(MouseEvent.MOUSE_UP, onScrubberDrop);

			_scrubber.stopDrag();

			removeEventListener(Event.ENTER_FRAME, updateAmount);

			updateAmount();
			volumeChanged();
		}


		private function updateAmount(e:Event=null):void
		{
			_barFill.width=_scrubber.x - _defaultX;
		}


		private function onAreaClick(e:MouseEvent):void
		{
			var _x:Number=mouseX;

			if (_x > (_bar.x + _bar.width - _scrubber.width))
				_x=_bar.x + _bar.width - _scrubber.width;


			a1=new AnimateProperty();
			a1.target=_scrubber;
			a1.property="x";
			a1.toValue=_x;
			a1.duration=250;
			a1.play();
			a1.addEventListener(EffectEvent.EFFECT_END, volumeChanged);

			a2=new AnimateProperty();
			a2.target=_barFill;
			a2.property="width";
			a2.toValue=_x - _defaultX;
			a2.duration=250;
			a2.play();

		}


		private function volumeChanged(e:EffectEvent=null):void
		{
			_currentVolume=_barFill.width / (_bar.width - _scrubber.width);

			dispatchEvent(new VolumeEvent(VolumeEvent.VOLUME_CHANGED, _currentVolume));
		}

		private function muteClickVolumeChange(event:EffectEvent):void
		{
			if (_muted)
			{
				dispatchEvent(new VolumeEvent(VolumeEvent.VOLUME_CHANGED, _currentVolume));
				muteBtn.state=MuteButton.MUTE;
				_muted=false;

			}
			else
			{
				dispatchEvent(new VolumeEvent(VolumeEvent.VOLUME_CHANGED, 0));
				muteBtn.state=MuteButton.UNMUTE;
				_muted=true;
			}
			_doingMute=false;
		}

		private function muteClicked(e:MouseEvent):void
		{
			if (_doingMute)
				return; // Avoiding stack overflow

			_doingMute=true;

			var _x:Number=_muted == true ? _mutedX : _defaultX;

			if (_currentVolume == 0 && !_muted)
			{
				_x=_defaultX + _bar.width / 2 - _scrubber.width;
				_currentVolume=0.5;
				_muted=true;
			}

			if (!_muted)
				_mutedX=_scrubber.x;

			a1=new AnimateProperty();
			a1.target=_scrubber;
			a1.property="x";
			a1.toValue=_x;
			a1.duration=250;
			a1.play();

			//Don't use anonymous functions as event listeners, they should be identifiable
			a1.addEventListener(EffectEvent.EFFECT_END, muteClickVolumeChange);

			a2=new AnimateProperty();
			a2.target=_barFill;
			a2.property="width";
			a2.toValue=_x - _defaultX;
			a2.duration=250;
			a2.play();
		}

	}
}
