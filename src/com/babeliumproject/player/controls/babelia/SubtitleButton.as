package com.babeliumproject.player.controls.babelia
{
	import com.babeliumproject.player.ResourceData;
	import com.babeliumproject.player.controls.DictionarySkinnableComponent;
	import com.babeliumproject.player.events.babelia.SubtitleButtonEvent;
	
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	
	import spark.components.ToggleButton;
	
	public class SubtitleButton extends DictionarySkinnableComponent
	{
		/**
		 * SKIN CONSTANTS
		 */
		public static const BG_COLOR:String = "bgColor";
		
		public static const BG_GRADIENT_ANGLE:String = "bgGradientAngle";
		public static const BG_GRADIENT_START_COLOR:String = "bgGradientStartColor";
		public static const BG_GRADIENT_END_COLOR:String = "bgGradientEndColor";
		public static const BG_GRADIENT_START_ALPHA:String = "bgGradientStartAlpha";
		public static const BG_GRADIENT_END_ALPHA:String = "bgGradientEndAlpha";
		public static const BG_GRADIENT_START_RATIO:String = "bgGradientStartRatio";
		public static const BG_GRADIENT_END_RATIO:String = "bgGradientEndRatio";
		public static const BORDER_COLOR:String = "borderColor";
		public static const BORDER_WEIGHT:String = "borderWeight";
		
		
		private var _button:ToggleButton;
		private var _state:String;
		private var _boxColor:uint = 0xFFFFFF;
		private var _selected:Boolean;
		
		public function SubtitleButton(state:Boolean = false)
		{
			super("SubtitleButton"); // Required to setup skinable component
			
			_button = new ToggleButton();
			_button.buttonMode = true;
			_button.label = "CC";
			_button.setStyle("fontSize",14);
			_button.setStyle("fontWeight", "bold");
			_button.setStyle("cornerRadius", 0);
			_button.setStyle("borderWeight",0);
		
			_button.selected = state ? true : false;
			_button.toolTip = _button.selected ? resourceManager.getString(ResourceData.PLAYER_RESOURCES,'HIDE_SUBTITLES') : resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SHOW_SUBTITLES');

			_button.addEventListener(MouseEvent.CLICK, showHideSubtitles);
			
			addChild( _button );
		}
		
		override public function dispose():void{
			super.dispose();
			
			if(_button){
				_button.removeEventListener(MouseEvent.CLICK,showHideSubtitles);
				removeChildSuppressed(_button);
				_button=null;
			}
		}
		
		override public function availableProperties(obj:Array = null) : void
		{
			super.availableProperties([BG_COLOR]);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			_button.width=width;
			_button.height=height;
		}
		
		public function set selected(value:Boolean):void{
			if(enabled){
				if(_selected == value) return;
				
				_selected = value;
				_button.selected = _selected;
				_button.toolTip = _selected ? resourceManager.getString(ResourceData.PLAYER_RESOURCES,'HIDE_SUBTITLES') : resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SHOW_SUBTITLES');
			}
		}
		
		override public function set enabled(value:Boolean) : void
		{
			if(_button) _button.enabled = value;
			super.enabled=value;
		}
		
		private function showHideSubtitles(e:MouseEvent) : void
		{
			_button.toolTip = _button.selected ? resourceManager.getString(ResourceData.PLAYER_RESOURCES,'HIDE_SUBTITLES') : resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SHOW_SUBTITLES');
				
			this.dispatchEvent(new SubtitleButtonEvent(SubtitleButtonEvent.STATE_CHANGED, _button.selected));
		}
	}
}
