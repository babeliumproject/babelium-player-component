package com.babeliumproject.player.controls.babelia
{
	import com.babeliumproject.player.ResourceData;
	import com.babeliumproject.player.controls.DictionarySkinnableButton;
	import com.babeliumproject.player.events.babelia.SubtitleButtonEvent;
	
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	
	import spark.components.ToggleButton;
	
	public class SubtitleButton extends DictionarySkinnableButton
	{
	
		
		private var _button:ToggleButton;
		private var _state:String;
		private var _boxColor:uint = 0xFFFFFF;
		private var _selected:Boolean;
		
		protected var iconCC:Object;
		
		public function SubtitleButton(state:Boolean = false)
		{
			super("SubtitleButton");
			
			_selected=false;
			
			iconCC = {
				'commands': [2,2,2,2],
				'data': [0,10,10,10,10,0,0,0]
			};
		}
		
		override public function dispose():void{
			super.dispose();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			drawIcon(_iconDisplay,iconCC);
			drawIcon(_iconDisplayHover,iconCC,'Hover');
			drawIcon(_iconDisplayActive,iconCC,'Active');
			
			_iconDisplay.width=14;
			_iconDisplay.height=14;
			_iconDisplayHover.width=14;
			_iconDisplayHover.height=14;
			_iconDisplayActive.width=14;
			_iconDisplayActive.height=14;
			
			var wc:Number=this.width/2;
			var hc:Number=this.height/2;
			
			_iconDisplay.x = wc - _iconDisplay.width/2;
			_iconDisplay.y = hc - _iconDisplay.height/2;
			_iconDisplayHover.x=wc - _iconDisplayHover.width/2;
			_iconDisplayHover.y=hc - _iconDisplayHover.height/2;
			_iconDisplayActive.x=wc - _iconDisplayActive.width/2;
			_iconDisplayActive.y=hc - _iconDisplayActive.height/2;
		}
		
		public function get selected():Boolean{
			return _selected;
		}
		
		public function set selected(value:Boolean):void{
			if(_selected == value) 
				return;
			
			_selected = value;
			
			if(_selected){
				_bgActive.visible=true;
				_iconDisplayActive.visible=true;
			} else {
				_bgActive.visible=false;
				_iconDisplayActive.visible=false;
			}
				
			//_button.selected = _selected;
			//_button.toolTip = _selected ? resourceManager.getString(ResourceData.PLAYER_RESOURCES,'HIDE_SUBTITLES') : resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SHOW_SUBTITLES');
		}
	
		override protected function onMouseOver(e:MouseEvent):void
		{
			trace("onMouseOver");
			_bgHover.visible=true;
			_bg.visible=false;
			
			_iconDisplayHover.visible=true;
			_iconDisplay.visible=false;
		}
			
		override protected function onMouseOut(e:MouseEvent):void
		{
			_bgHover.visible=false;
			_bg.visible=true;
			
			_iconDisplayHover.visible=false;
			_iconDisplay.visible=true;
		}
		
		override protected function onClick(e:MouseEvent):void{
			trace("onMouseClick");
			//Selected function appplies the element visibilty logic
			if(selected){
				selected=false;
			} else {
				selected=true;
			}
			
			
		}
		
		private function showHideSubtitles(e:MouseEvent) : void
		{
			_button.toolTip = _button.selected ? resourceManager.getString(ResourceData.PLAYER_RESOURCES,'HIDE_SUBTITLES') : resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SHOW_SUBTITLES');
				
			this.dispatchEvent(new SubtitleButtonEvent(SubtitleButtonEvent.STATE_CHANGED, _button.selected));
		}
	}
}
