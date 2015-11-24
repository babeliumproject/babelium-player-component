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
		private var _state:String;
		private var _selected:Boolean;
		
		protected var iconCC:Object;
		
		public function SubtitleButton(state:Boolean = false)
		{
			super("SubtitleButton");
			
			_selected=false;
			
			iconCC = {
				'commands': [1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 1, 6, 6, 2, 6, 6, 6, 6, 2, 6, 6, 6, 6, 2, 1, 6, 6, 2, 6, 6, 6, 6, 2, 6, 6, 6, 6, 2],
				'data': [19.6, 0, 14.500000000000002, 0.0886, 9.200000000000001, -0.0657, 4.100000000000001, 1, 1.9400000000000013, 1.4849999999999999, 0.7500000000000013, 3.57, 0.4800000000000013, 5.62, -0.1519999999999987, 10.42, -0.06099999999999872, 15.330000000000002, 0.3550000000000013, 20.12, 0.5650000000000013, 22.36, 1.4250000000000014, 24.93, 3.8250000000000015, 25.62, 8.505, 26.740000000000002, 13.385000000000002, 26.619, 18.125000000000004, 26.78, 23.615000000000002, 26.7282, 29.225, 26.844800000000003, 34.625, 25.811, 36.895, 25.404, 38.205, 23.201, 38.505, 21.061, 39.145, 16.371, 39.043, 11.621, 38.693000000000005, 6.861000000000001, 38.493, 4.591000000000001, 37.593, 1.6910000000000007, 34.89300000000001, 1.0610000000000008, 29.893000000000008, -0.00899999999999923, 24.69300000000001, 0.1490000000000008, 19.593000000000007, 0.06100000000000083, 19.6, 0, 10.88, 3.91, 11.677000000000001, 3.8867000000000003, 12.48, 3.9836, 13.260000000000002, 4.222, 16.630000000000003, 4.998, 18.410000000000004, 8.532, 18.540000000000003, 11.752, 14.260000000000002, 11.752, 13.260000000000002, 11.252, 13.46, 8.382000000000001, 11.360000000000001, 8.572000000000001, 8.950000000000001, 8.382000000000001, 8.330000000000002, 11.252, 8.260000000000002, 13.152000000000001, 8.2428, 15.192, 7.997000000000002, 17.922, 10.010000000000002, 19.122, 12.05, 20.212, 13.900000000000002, 18.082, 13.820000000000002, 16.122, 18.660000000000004, 16.122, 18.560000000000002, 18.622, 17.560000000000002, 21.322, 15.460000000000004, 22.822, 11.760000000000005, 25.422, 5.950000000000005, 23.721999999999998, 4.360000000000005, 19.422, 2.810000000000005, 15.522, 2.890000000000005, 10.822000000000001, 5.050000000000004, 7.222000000000001, 6.280000000000005, 5.092000000000001, 8.590000000000003, 3.8920000000000012, 10.960000000000004, 3.8220000000000014, 10.88, 3.91, 27.58, 3.91, 28.377, 3.8867000000000003, 29.18, 3.9837000000000002, 29.959999999999997, 4.222, 33.33, 4.998, 35.11, 8.532, 35.239999999999995, 11.752, 30.959999999999994, 11.752, 29.962999999999994, 11.321000000000002, 30.114999999999995, 8.432, 28.049999999999994, 8.632000000000001, 25.649999999999995, 8.436000000000002, 25.019999999999992, 11.322000000000001, 24.959999999999994, 13.192, 24.942799999999995, 15.232, 24.696999999999992, 17.962, 26.709999999999994, 19.162, 28.749999999999993, 20.252, 30.599999999999994, 18.122, 30.519999999999992, 16.162, 35.35999999999999, 16.162, 35.14699999999999, 18.701999999999998, 34.169999999999995, 21.362, 32.019999999999996, 22.881999999999998, 28.339999999999996, 25.461999999999996, 22.549999999999997, 23.759999999999998, 20.919999999999995, 19.502, 19.369999999999994, 15.631999999999998, 19.419999999999995, 10.941999999999998, 21.575999999999993, 7.302, 22.805999999999994, 5.172, 25.15599999999999, 3.9619999999999997, 27.545999999999992, 3.8919999999999995, 27.58, 3.91]
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
			
			var scaleC:Number=14 / _iconDisplay.height;
			
			_iconDisplay.width=_iconDisplay.width*scaleC;
			_iconDisplay.height=_iconDisplay.height*scaleC;
			_iconDisplayHover.width=_iconDisplay.width*scaleC;
			_iconDisplayHover.height=_iconDisplay.height*scaleC;
			_iconDisplayActive.width=_iconDisplay.width*scaleC;
			_iconDisplayActive.height=_iconDisplay.height*scaleC;
			
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
				toolTip=resourceManager.getString(ResourceData.PLAYER_RESOURCES,'HIDE_SUBTITLES');
				_bgActive.visible=true;
				_iconDisplayActive.visible=true;
			} else {
				toolTip=resourceManager.getString(ResourceData.PLAYER_RESOURCES,'SHOW_SUBTITLES');
				_bgActive.visible=false;
				_iconDisplayActive.visible=false;
			}
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
			this.dispatchEvent(new SubtitleButtonEvent(SubtitleButtonEvent.STATE_CHANGED, _selected));
		}
	}
}
