package com.babeliumproject.player.controls.babelia
{
	import com.babeliumproject.player.ResourceData;
	import com.babeliumproject.player.controls.DictionarySkinnableComponent;

	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.media.Microphone;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;

	import mx.resources.ResourceManager;


	/**
	 * Merged from iñigo's:
	 * modules/configuration/microphone/barraSonido.mxml
	 **/
	public class MicActivityBar extends DictionarySkinnableComponent
	{
		/**
		 * Skin constants
		 */
		public static const BORDER_COLOR:String="bgColor";
		public static const BARBG_COLOR:String="barBgColor";
		public static const BAR_COLOR:String="barColor";
		public static const COLOR:String="textColor";

		private var _mic:Microphone;
		private var _micTimer:Timer;

		protected var inactiveIcon:Sprite;
		protected var activeIcon:Sprite;
		protected var maskShape:Sprite;

		protected var iconMic:Object;

		public function MicActivityBar()
		{
			super("MicActivityBar");

			iconMic={
				'commands': [1, 2, 6, 6, 2, 6, 6, 2, 1, 2, 6, 6, 2, 2, 2, 6, 2, 6, 6, 6, 6, 2, 6, 2, 2, 2], 
				'data': [70, 185, 70, 68, 70, 30.445, 100.445, 0, 138, 0, 175.556, 0, 206, 30.445, 206, 68, 206, 185, 206, 222.557, 175.556, 253.002, 138, 253.002, 100.445, 253.002, 70, 222.557, 70, 185, 70, 185, 236, 150, 236, 185, 236, 239.039, 192.037, 283.002, 138, 283.002, 83.963, 283.002, 40, 239.039, 40, 185, 40, 150, 0, 150, 0, 185, 0, 253.434, 50.071, 310.381, 115.5, 321.158, 115.5, 362.467, 77.248, 365.256, 49, 375.033, 49, 386.668, 49, 400.475, 88.784, 411.668, 137.861, 411.668, 186.937, 411.668, 226.721, 400.475, 226.721, 386.668, 226.721, 375.063, 198.61, 365.305, 160.499, 362.488, 160.499, 321.158, 225.929, 310.381, 276, 253.434, 276, 185, 276, 150, 236, 150, 236, 15], 
				'width': 276, 
				'height': 412
			};

			inactiveIcon=new Sprite();
			activeIcon=new Sprite();
			maskShape=new Sprite();

			addChild(inactiveIcon);
			addChild(activeIcon);
			addChild(maskShape);

			drawIcon(inactiveIcon, iconMic, [0x00FF00, 0xFFFF00], [85, 255]);
			drawIcon(activeIcon, iconMic, 0xD4D4D4);

			maskShape.graphics.beginFill(0xFFFFFF);
			maskShape.graphics.drawRect(0, 0, activeIcon.width, activeIcon.height);
			maskShape.graphics.endFill();

			activeIcon.mask=maskShape;
		}

		override public function dispose():void
		{
			super.dispose();

			if (_micTimer)
			{
				_micTimer.stop();
				_micTimer.removeEventListener(TimerEvent.TIMER, onTimerTick);
				_micTimer=null;
			}
		}

		public function set mic(mic:Microphone):void
		{
			_mic=mic;

			_micTimer=new Timer(20);
			_micTimer.addEventListener(TimerEvent.TIMER, onTimerTick);
			_micTimer.start();
		}

		private function onTimerTick(e:TimerEvent):void
		{
			updateMask();
		}

		protected function drawIcon(element:Sprite, pathData:Object, colorData:*, ratioData:Array=null):void
		{
			if (!element || !pathData)
				return;

			if (!pathData.hasOwnProperty('commands') || !pathData.hasOwnProperty('data') || !pathData.hasOwnProperty('height') || !pathData.hasOwnProperty('width'))
				return;

			var color:uint=0x000000;
			var alpha:Number=0.0;
			var commands:Vector.<int>=Vector.<int>(pathData.commands);
			var data:Vector.<Number>=Vector.<Number>(pathData.data);
			var iwidth:Number=pathData.width;
			var iheight:Number=pathData.height;

			if (colorData is Array)
			{
				var colors:Array=colorData as Array;
				var alphas:Array=[];
				var ratios:Array=ratioData;
				var angle:int=90;
				var numColors:int=colors.length;
				for (var i:int=0; i < numColors; i++)
				{
					colors[i]=new uint(colors[i]);
					alphas.push(1.0);
				}
				var type:String=GradientType.LINEAR;
				var matrix:Matrix=new Matrix();
				matrix.createGradientBox(iwidth, iheight, deg2rad(angle), 0, 0);
				element.graphics.beginGradientFill(type, colors, alphas, ratios, matrix);

			}
			else if (colorData is int)
			{
				color=new uint(colorData);
				alpha=1.0;
				element.graphics.beginFill(color, alpha);
			}
			else
			{
				element.graphics.beginFill(color, alpha);
			}

			element.graphics.drawPath(commands, data);
			element.graphics.endFill();
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			inactiveIcon.height=height;
			inactiveIcon.scaleX=inactiveIcon.scaleY;

			activeIcon.height=height;
			activeIcon.scaleX=activeIcon.scaleY;
			
			activeIcon.mask=null;
			maskShape.graphics.clear();
			maskShape.graphics.beginFill(0xFFFFFF);
			maskShape.graphics.drawRect(0, 0, activeIcon.width, activeIcon.height);
			maskShape.graphics.endFill();
			activeIcon.mask=maskShape;

			var wc:Number=width / 2;

			inactiveIcon.x=wc - inactiveIcon.width / 2;
			activeIcon.x=wc - activeIcon.width / 2;
			maskShape.x=wc - maskShape.width / 2;
		}

		protected function updateMask():void
		{
			var level:Number=_mic.activityLevel ? _mic.activityLevel : 0;
			var total:Number=activeIcon.height;
			var nh:Number=Math.round(total * (100 - level) / 100);
			maskShape.height=nh;
		}
	}
}
