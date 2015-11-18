package com.babeliumproject.player.controls
{
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class ElapsedTime extends DictionarySkinnableComponent
	{
		public static const COLOR:String="textColor";

		private var _timeBox:TextField;
		private var tf:TextFormat=new TextFormat();

		private var intTime:uint;
		private var intDuration:uint;

		private var strTime:String="0:00";
		private var strDuration:String="0:00";

		public function ElapsedTime()
		{
			super("ElapsedTime");

			_timeBox=new TextField();
			_timeBox.text=strTime+"/"+strDuration;
			_timeBox.selectable=false;

			tf.bold=false;
			tf.align="center";
			tf.font="Arial";

			_timeBox.setTextFormat(tf);

			addChild(_timeBox);
		}
		
		override public function dispose():void{
			super.dispose();
			
			//There are no objects that need to be manually disposed
		}

		override public function availableProperties(obj:Array=null):void
		{
			super.availableProperties([BACKGROUND_COLOR, BORDER_COLOR, BORDER_WIDTH, COLOR]);
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			_timeBox.width=width;
			_timeBox.height=height;
			trace("TextField: "+_timeBox.width+"x"+_timeBox.height+" th: "+ _timeBox.textHeight+" y:"+Math.floor((_timeBox.height-_timeBox.textHeight)/2));
			_timeBox.y=Math.round((_timeBox.height-_timeBox.textHeight)/2)-1;
			tf.color=getSkinColor(COLOR);
		}

		public function updateElapsedTime(curTime:Number, duration:Number):void
		{
			var change:Boolean;
			var intt:uint=uint(curTime);
			if (intTime != intt)
			{
				intTime=intt;
				change=true;
				var itimemin:uint=uint(intt / 60);
				var itimesec:uint=uint(intt % 60);
				strTime= ""+itimemin + ":" + zeroPad(itimesec,2);
			}
			var intd:uint=uint(duration);
			if (intDuration != intd)
			{
				intDuration=intd;
				change=true;
				var idurationmin:uint=uint(duration / 60);
				var idurationsec:uint=uint(duration % 60);
				strDuration= ""+idurationmin + ":" + zeroPad(idurationsec,2);
			}

			//Update display only once per second and if there are any changes
			if (change)
			{
				_timeBox.text=strTime + "/" + strDuration;
				_timeBox.setTextFormat(tf);
			}
		}

		public function zeroPad(number:int, width:int):String
		{
			var ret:String="" + number;
			while (ret.length < width)
				ret="0" + ret;
			return ret;
		}
	}
}
