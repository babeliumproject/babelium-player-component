package com.babeliumproject.player.media
{	
	import com.babeliumproject.player.events.StreamingEvent;
	
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;

	public class ASoundManager extends AMediaManager
	{
		
		private var _snd:Sound;
		private var _channel:SoundChannel;
		
		private var _currentTime:Number;
		
		public function ASoundManager(url:String, id:String)
		{
			super(id);
		}
		
		override public function setup(... args):void{
			if(args.length){
				//URL should be previously parsed with a general purpose HTTP regexp
				var url:String = (args[0] is String) ? args[0] : '';
				_streamUrl=url;
			}
			
			connect();
		}
		
		private function connect():void{
			_connected=true;
			dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
		}
		
		override protected function initiateStream():void{
			_snd = new Sound();
			
			var request:URLRequest = new URLRequest(_streamUrl);
			
			_snd.load(request);
			_snd.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
		}
		
		override public function play():void{
			_channel = _snd.play();
		}
		
		override public function stop():void{
			_channel.stop();
			_snd.close();
		}
		
		override public function pause():void{
			_currentTime = _channel.position;
			_channel.stop();
		}
		
		override public function resume():void{
			_snd.play(_currentTime);
		}
		
		override public function seek(seconds:Number):void{
			_snd.play(seconds);
		}
		
		override public function get duration():Number
		{
			return _snd.length / 1000;
		}	
		
		override public function get loadedFraction():Number
		{
			return _snd.bytesLoaded / _snd.bytesTotal;
		}
		
		override public function get currentTime():Number
		{
			return _channel.position / 1000;
		}
	}
}