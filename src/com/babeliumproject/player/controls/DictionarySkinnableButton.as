package com.babeliumproject.player.controls
{
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import mx.controls.ToolTip;
	import mx.core.IToolTip;
	import mx.events.ToolTipEvent;
	import mx.utils.ObjectUtil;
	
	import spark.components.TextInput;

	public class DictionarySkinnableButton extends DictionarySkinnableComponent
	{
		public static const COLOR:String="color";
		
		public static const BACKGROUND_COLOR_HOVER:String="backgroundColorHover";
		public static const BORDER_COLOR_HOVER:String="borderColorHover";
		public static const BORDER_WIDTH_HOVER:String="borderWidthHover";
		public static const COLOR_HOVER:String="colorHover";
		
		public static const BACKGROUND_COLOR_ACTIVE:String="backgroundColorActive";
		public static const BORDER_COLOR_ACTIVE:String="borderColorActive";
		public static const BORDER_WIDTH_ACTIVE:String="borderWidthActive";
		public static const COLOR_ACTIVE:String="colorActive";
	
		protected var _bgHover:Sprite;
		protected var _bgActive:Sprite;
		
		protected var _iconDisplay:Sprite;
		protected var _iconDisplayHover:Sprite;
		protected var _iconDisplayActive:Sprite;

		public function DictionarySkinnableButton(name:String="DictionarySkinnableButton")
		{
			super(name);
			
			_bgHover=new Sprite();
			_bgActive=new Sprite();
			

			_iconDisplay=new Sprite();
			_iconDisplayHover=new Sprite();
			_iconDisplayActive=new Sprite();

			addChild(_bgActive);
			addChild(_bgHover);
			
			
			addChild(_iconDisplay);
			addChild(_iconDisplayActive);
			addChild(_iconDisplayHover);
			

			this.buttonMode=true;
			this.useHandCursor=true;

			this.addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			this.addEventListener(MouseEvent.CLICK, onClick);
			this.addEventListener(ToolTipEvent.TOOL_TIP_CREATE, onToolTipCreate);
			this.addEventListener(ToolTipEvent.TOOL_TIP_SHOW, onToolTipShow);
		}

		override public function dispose():void
		{
			super.dispose();
			this.removeEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			this.removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			this.removeEventListener(MouseEvent.CLICK, onClick);
			this.removeEventListener(ToolTipEvent.TOOL_TIP_CREATE, onToolTipCreate);
			this.removeEventListener(ToolTipEvent.TOOL_TIP_SHOW, onToolTipShow);
		}
		
		override public function set enabled(value:Boolean):void
		{	
			super.enabled=value;

			this.buttonMode=value;
			this.useHandCursor=value;

			if (value)
			{
				this.addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
				this.addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
				this.addEventListener(MouseEvent.CLICK, onClick);
			}
			else
			{
				this.removeEventListener(MouseEvent.ROLL_OVER, onMouseOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
				this.removeEventListener(MouseEvent.CLICK, onClick);
			}

			if (_bg)
				onMouseOut(null);
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			drawBackground(_bgHover,'Hover');
			drawBackground(_bgActive,'Active');

		}
		
		protected function drawIcon(element:Sprite,pathData:Object,state:String=''):void{
			if(!element || !pathData) return;
			
			if(!pathData.hasOwnProperty('commands') || !pathData.hasOwnProperty('data'))
				return;
			
			var commands:Vector.<int>=Vector.<int>(pathData.commands);
			var data:Vector.<Number>=Vector.<Number>(pathData.data);
			
			element.graphics.clear();
			element.graphics.beginFill(getSkinColor(COLOR+state));
			element.graphics.drawPath(commands,data);
			element.graphics.endFill();
		}


		protected function onMouseOver(e:MouseEvent):void
		{
			_bgHover.visible=true;
			_bgActive.visible=false;
			_bg.visible=false;
			
			_iconDisplayHover.visible=true;
			_iconDisplayActive.visible=false;
			_iconDisplay.visible=false;
		}


		protected function onMouseOut(e:MouseEvent):void
		{
			_bgActive.visible=false;
			_bgHover.visible=false;
			_bg.visible=true;
			
			_iconDisplayHover.visible=false;
			_iconDisplayActive.visible=false;
			_iconDisplay.visible=true;
		}

		protected function onClick(e:MouseEvent):void
		{
			return;
		}
		
		protected function onToolTipCreate(event:ToolTipEvent):void{
			var ct:ToolTip=new ToolTip();
			ct.setStyle("backgroundColor",0x333333);
			ct.setStyle("cornerRadius",0);
			ct.setStyle("color",0xFFFFFF);
			ct.setStyle("fontSize",12);
			ct.setStyle("fontWeight","bold");
			ct.setStyle("borderVisible",false);
			event.toolTip=ct;
		}
		
		protected function onToolTipShow(event:ToolTipEvent):void{
			var pt:Point=new Point(0, 0);
			pt=event.currentTarget.contentToGlobal(pt);
			event.toolTip.y=pt.y-event.toolTip.height-4;
		}

		private function getBitmapFilter():BitmapFilter
		{
			var color:Number=0x000000;
			var angle:Number=90;
			var alpha:Number=1.0;
			var blurX:Number=4;
			var blurY:Number=4;
			var distance:Number=0;
			var strength:Number=0.90;
			var inner:Boolean=true;
			var knockout:Boolean=false;
			var quality:Number=BitmapFilterQuality.HIGH;
			return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout);
		}

		//----------------------------------
		//  toolTip
		//----------------------------------

		[Inspectable(category="General", defaultValue="null")]

		/**
		 *  @private
		 */
		private var _explicitToolTip:Boolean=false;

		/**
		 *  @private
		 */
		override public function set toolTip(value:String):void
		{
			super.toolTip=value;

			_explicitToolTip=value != null;
		}


	}
}
