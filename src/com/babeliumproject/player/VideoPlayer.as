package com.babeliumproject.player
{

	import avmplus.getQualifiedClassName;
	
	import com.babeliumproject.player.controls.AudioSlider;
	import com.babeliumproject.player.controls.BitmapSprite;
	import com.babeliumproject.player.controls.ControlBar;
	import com.babeliumproject.player.controls.ElapsedTime;
	import com.babeliumproject.player.controls.ErrorSprite;
	import com.babeliumproject.player.controls.PlayButton;
	import com.babeliumproject.player.controls.ScrubberBar;
	import com.babeliumproject.player.controls.XMLSkinnableComponent;
	import com.babeliumproject.player.events.MediaStatusEvent;
	import com.babeliumproject.player.events.ScrubberBarEvent;
	import com.babeliumproject.player.events.StopEvent;
	import com.babeliumproject.player.events.VideoPlayerEvent;
	import com.babeliumproject.player.events.VolumeEvent;
	import com.babeliumproject.player.media.AMediaManager;
	import com.babeliumproject.player.media.ARTMPManager;
	import com.babeliumproject.player.media.AVideoManager;
	import com.babeliumproject.utils.BusyIndicator;
	import com.babeliumproject.utils.IDisposableObject;
	
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.media.Video;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;
	
	import spark.components.Group;

	public class VideoPlayer extends XMLSkinnableComponent
	{
		protected static const logger:ILogger=getLogger(VideoPlayer);

		//Style property constants
		public static const BG_COLOR:String="bgColor";
		public static const BORDER_COLOR:String="borderColor";
		public static const VIDEOBG_COLOR:String="videoBgColor";

		public static const DEFAULT_VOLUME:Number=70;

		protected var _video:Video;

		private var _state:String=null;

		protected var _smooth:Boolean=true;
		protected var _autoScale:Boolean=true;
		protected var _currentTime:Number=0;
		protected var _autoPlay:Boolean=false;
		protected var _autoPlayOverride:Boolean=false;
		protected var _duration:Number=0;
		protected var _started:Boolean=false;
		protected var _defaultMargin:Number=0;

		//Ignore user's volume preferences while active
		protected var _muteOverride:Boolean=false;

		private var _bgVideo:Sprite;
		public var _ppBtn:PlayButton;
		//public var _stopBtn:StopButton;

		protected var _eTime:ElapsedTime;
		//protected var _bg:Sprite;
		protected var _playerControls:ControlBar;
		protected var _scrubBar:ScrubberBar;
		protected var _audioSlider:AudioSlider;
		protected var _videoHeight:Number=200;
		protected var _videoWidth:Number=320;

		protected var _videoDisplayWidth:Number;
		protected var _videoDisplayHeight:Number;

		protected var _mediaPosterUrl:String;
		protected var _topLayer:Sprite;
		protected var _posterSprite:BitmapSprite;
		protected var _errorSprite:ErrorSprite;
		protected var _media:AMediaManager;
		protected var _mediaUrl:String;
		protected var _mediaNetConnectionUrl:String;
		protected var _mediaReady:Boolean;
		protected var _currentVolume:Number;
		protected var _lastVolume:Number;
		protected var _muted:Boolean=false;
		protected var _forcePlay:Boolean;
		protected var _videoPlaying:Boolean;
		protected var _lastWidth:int;
		protected var _lastHeight:int;

		protected var _busyIndicator:BusyIndicator;


		public function VideoPlayer(name:String="VideoPlayer")
		{
			super(name);

			_currentVolume=DEFAULT_VOLUME;
			_lastVolume=DEFAULT_VOLUME;

			_bg=new Sprite();
			_bgVideo=new Sprite();
			_topLayer=new Sprite();
			_video=new Video();
			_video.smoothing=_smooth;

			_busyIndicator=new BusyIndicator();
			_busyIndicator.width=48;
			_busyIndicator.height=48;
			_busyIndicator.visible=false;
			
			_scrubBar=new ScrubberBar();

			_playerControls=new ControlBar();
			_playerControls.height=26;
			_playerControls.width=this.width;

			_ppBtn=new PlayButton();
			_ppBtn.height=26;
			_ppBtn.width=40;
			
			_eTime=new ElapsedTime();
			_eTime.height=26;
			_eTime.width=75;
			
			_audioSlider=new AudioSlider(_currentVolume / 100); //Audio slider uses fraction values
			_audioSlider.height=26;
			_audioSlider.width=80;
			
			_playerControls.addChild(_ppBtn);
			_playerControls.addChild(_eTime);
			_playerControls.addChild(_audioSlider);

			_errorSprite=new ErrorSprite(null, width, height);


			addEventListener(FlexEvent.CREATION_COMPLETE, onComplete, false, 0, true);
			_ppBtn.addEventListener(MouseEvent.CLICK, onPPBtnChanged, false, 0, true);
			_audioSlider.addEventListener(VolumeEvent.VOLUME_CHANGED, onVolumeChange, false, 0, true);

			addChild(_bg);
			addChild(_bgVideo);
			addChild(_video);
			addChild(_playerControls);
			addChild(_scrubBar);
			addChild(_topLayer);
			addChild(_busyIndicator);

			/**
			 * Adds skinable components to dictionary
			 */
			putSkinableComponent(COMPONENT_NAME, this);
			putSkinableComponent(_playerControls.COMPONENT_NAME, _playerControls);
			putSkinableComponent(_audioSlider.COMPONENT_NAME, _audioSlider);
			putSkinableComponent(_audioSlider.muteBtn.COMPONENT_NAME, _audioSlider.muteBtn);
			putSkinableComponent(_eTime.COMPONENT_NAME, _eTime);
			putSkinableComponent(_ppBtn.COMPONENT_NAME, _ppBtn);
			putSkinableComponent(_scrubBar.COMPONENT_NAME, _scrubBar);
		}

		public function loadVideoByUrl(param:Object, timemarkers:Object=null):void
		{
			var parsedMedia:Object=parseMediaObject(param);
			if (parsedMedia)
			{
				_mediaNetConnectionUrl=parsedMedia.netConnectionUrl;
				_mediaUrl=parsedMedia.mediaUrl;
				_mediaPosterUrl=parsedMedia.mediaPosterUrl;
				loadVideo();
			}
		}

		protected function parseMediaObject(param:Object):Object
		{
			var mediaObj:Object=new Object();
			var netConnectionUrl:String;
			var mediaUrl:String;
			var mediaPosterUrl:String;
			logger.debug(getQualifiedClassName(param));
			if (param is Object)
			{
				if (!param.mediaUrl)
				{
					return null;
				}
				mediaUrl=param.mediaUrl;
				mediaPosterUrl=param.mediaPosterUrl || null;
				netConnectionUrl=param.netConnectionUrl || null;
			}
			else if (param is String)
			{
				mediaUrl=String(param) || null;
			}
			else
			{
				return null;
			}

			mediaObj.netConnectionUrl=netConnectionUrl;
			mediaObj.mediaUrl=mediaUrl;
			mediaObj.mediaPosterUrl=mediaPosterUrl;

			return mediaObj;
		}

		protected function loadVideo():void
		{
			_mediaReady=false;
			logger.info("Load video: {0}", [_mediaNetConnectionUrl + '/' + _mediaUrl]);
			if (_mediaUrl != '')
			{

				_busyIndicator.visible=true;
				resetAppearance();

				if (!autoPlay)
				{
					if (_mediaPosterUrl)
					{
						_posterSprite=new BitmapSprite(_mediaPosterUrl, _lastWidth, _lastHeight);
						_topLayer.addChild(_posterSprite);
					}
				}

				if (streamReady(_media))
				{
					_media.netStream.dispose();
				}

				_media=null;
				if (_mediaNetConnectionUrl)
				{
					_media=new ARTMPManager("playbackStream");
					_media.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_media.setup(_mediaNetConnectionUrl, _mediaUrl);
				}
				else
				{
					_media=new AVideoManager("playbackStream");
					_media.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_media.setup(_mediaUrl);
				}
			}
		}

		protected function streamReady(stream:AMediaManager):Boolean
		{
			return stream && stream.netStream;
		}

		protected function onStreamSuccess(event:Event):void
		{
			var evt:Object=Object(event);
			
			if(_topLayer.contains(_errorSprite)){
				_topLayer.removeChild(_errorSprite);
			}

			_video.attachNetStream(_media.netStream);
			_video.visible=true;
			_media.volume=_currentVolume;
			_media.addEventListener(MediaStatusEvent.METADATA_RETRIEVED, onMetaData, false, 0, true);
			_media.addEventListener(MediaStatusEvent.STATE_CHANGED, onStreamStateChange, false, 0, true);
			if (_mediaUrl != '')
			{
				_mediaReady=true;
				if (autoPlay || _forcePlay)
				{
					startVideo();
					_forcePlay=false;
				}
			}
		}

		protected function onStreamFailure(event:Event):void
		{
			var evt:Object=Object(event);
			_errorSprite.setLocaleAwareErrorMessage(evt.message);
			_topLayer.removeChildren();
			_topLayer.addChild(_errorSprite);
			_busyIndicator.visible=false;
			resetAppearance();
			freeMediaResources();
			invalidateDisplayList();
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.ON_ERROR, false, false, 100, evt.message));
		}

		protected function onStreamStateChange(event:MediaStatusEvent):void
		{
			_busyIndicator.visible=false;
			if (event.state == AMediaManager.STREAM_FINISHED)
			{
				_video.clear(); //Clean the last frame
				_videoPlaying=false;
				_ppBtn.state=PlayButton.PLAY_STATE;
				trace("[" + event.streamid + "] Stream Finished");
			}
			if (event.state == AMediaManager.STREAM_STARTED)
			{
				_videoPlaying=true;
				_ppBtn.state=PlayButton.PAUSE_STATE;
			}

			if (event.state == AMediaManager.STREAM_PAUSED)
			{

				_ppBtn.state=PlayButton.PLAY_STATE;
			}

			if (event.state == AMediaManager.STREAM_BUFFERING)
			{
				_busyIndicator.visible=true;
			}

			if (event.state == AMediaManager.STREAM_SEEKING_START)
			{
				//
			}

			if (event.state == AMediaManager.STREAM_READY)
			{
				dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.ON_READY));
			}

			//dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.STREAM_STATE_CHANGED, event.state));
		}

		protected function startVideo():void
		{
			trace("Start video");
			if (!_mediaReady)
				return;
			try
			{
				_media.play();
			}
			catch (e:Error)
			{
				_mediaReady=false;
					//logger.error("Error while loading video. [{0}] {1}", [e.errorID, e.message]);
			}
		}


		public function set autoPlay(value:Boolean):void
		{
			_autoPlay=value;
		}

		public function get autoPlay():Boolean
		{
			return _autoPlayOverride ? false : _autoPlay;
		}

		public function set videoSmooting(value:Boolean):void
		{
			_smooth=value;
		}

		public function get videoSmooting():Boolean
		{
			return _smooth;
		}

		public function set autoScale(value:Boolean):void
		{
			_autoScale=value;
		}

		public function get autoScale():Boolean
		{
			return _autoScale;
		}

		/**
		 * Seek
		 */
		public function set seekUsingScrubber(value:Boolean):void
		{
			if (value)
			{
				_scrubBar.addEventListener(ScrubberBarEvent.SCRUBBER_DROPPED, onScrubberDropped, false, 0, true);
				_scrubBar.addEventListener(ScrubberBarEvent.SCRUBBER_DRAGGING, onScrubberDragging, false, 0, true);
			}
			else
			{
				_scrubBar.removeEventListener(ScrubberBarEvent.SCRUBBER_DROPPED, onScrubberDropped);
				_scrubBar.removeEventListener(ScrubberBarEvent.SCRUBBER_DRAGGING, onScrubberDragging);
			}

			_scrubBar.enableSeek(value);
		}

		public function seekTo(seconds:Number):void
		{
			_scrubBar.updateProgress(seconds, _duration);
			_media.seek(seconds);
		}

		/**
		 * Enable/disable controls
		 **/
		public function set controlsEnabled(flag:Boolean):void
		{
			flag ? enableControls() : disableControls();

		}

		public function toggleControls():void
		{
			(_ppBtn.enabled) ? disableControls() : enableControls();
		}

		public function enableControls():void
		{
			_ppBtn.enabled=true;
			//_stopBtn.enabled=true;
		}

		public function disableControls():void
		{
			_ppBtn.enabled=false;
			//_stopBtn.enabled=false;
		}

		/**
		 * Duration
		 */
		public function get duration():Number
		{
			return _duration;
		}

		public function forcedMute():void
		{
			mute();
			_muteOverride=true;
		}

		public function forcedUnMute():void
		{
			_muteOverride=false;
			unMute();
		}

		public function mute():void
		{
			if (!isMuted())
			{
				_muted=true;
				//Store the volume that we had before muting to restore to that volume when unmuting
				_lastVolume=_currentVolume;
				var newVolume:Number=0;

				if (!_muteOverride)
				{
					//Make sure we have a working NetStream object before setting its sound transform
					if (_media)
						_media.volume=newVolume;
				}
			}
		}

		public function unMute():void
		{
			if (isMuted())
			{
				_muted=false;
				var newVolume:Number=_lastVolume;

				if (!_muteOverride)
				{
					//Make sure we have a working NetStream object before setting its sound transform
					if (_media)
						_media.volume=newVolume;
				}
			}
		}

		public function isMuted():Boolean
		{
			return _muted;
		}

		public function getVolume():Number
		{
			return _currentVolume;
		}

		public function setVolume(value:Number):void
		{
			if (!isNaN(value) && value >= 0 && value <= 100)
			{
				_currentVolume=value;
				if (!_muteOverride)
				{
					if (_media)
						_media.volume=value;
				}
			}
		}

		/** Overriden */

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			this.graphics.clear();

			_bgVideo.graphics.clear();
			_bgVideo.graphics.beginFill(getSkinColor(VIDEOBG_COLOR));
			_bgVideo.graphics.drawRect(_defaultMargin, _defaultMargin, _videoWidth, _videoHeight);
			_bgVideo.graphics.endFill();
			
			_scrubBar.width=_videoWidth;
			_scrubBar.y=_defaultMargin+_videoHeight;
			_scrubBar.x=_defaultMargin;
			
			_playerControls.width=_videoWidth;
			_playerControls.y=_scrubBar.y+_scrubBar.height;
			_playerControls.x=_defaultMargin;

			_ppBtn.x=0;
			_eTime.x=_ppBtn.x+_ppBtn.width;
			_audioSlider.x=_playerControls.width-_audioSlider.width;
			
			_ppBtn.refresh();
			_eTime.refresh();
			_audioSlider.refresh();

			_busyIndicator.x=(_videoWidth - _busyIndicator.width) / 2;
			_busyIndicator.y=(_videoHeight - _busyIndicator.height) / 2;
			_busyIndicator.setStyle('symbolColor', 0xFFFFFF);

			drawBG();
		}

		public function set videoDisplayWidth(value:Number):void
		{
			if (_videoDisplayWidth != value)
			{
				var nominalWidth:Number=_videoDisplayWidth;
				width=nominalWidth;
			}
		}

		public function get videoDisplayWidth():Number
		{
			return _videoDisplayWidth;
		}

		public function set videoDisplayHeight(value:Number):void
		{
			if (_videoDisplayHeight != value)
			{
				var nominalHeight:Number=_videoDisplayHeight + _playerControls.height;
				height=nominalHeight;
			}
		}

		public function get videoDisplayHeight():Number
		{
			return _videoDisplayHeight;
		}

		/**
		 * Set width/height of video widget
		 */
		override public function set width(w:Number):void
		{
			totalWidth=w;
			_videoWidth=w - 2 * _defaultMargin;
			this.updateDisplayList(0, 0); // repaint
		}

		override public function set height(h:Number):void
		{
			totalHeight=h;
			_videoHeight=h - 2 * _defaultMargin;
			this.updateDisplayList(0, 0); // repaint
		}

		/**
		 * Set total width/height of videoplayer
		 */
		protected function set totalWidth(w:Number):void
		{
			super.width=w;
		}

		protected function set totalHeight(h:Number):void
		{
			super.height=h;
		}

		/**
		 * Draws a background for videoplayer
		 */
		protected function drawBG():void
		{
			totalHeight=_defaultMargin * 2 + _videoHeight + _playerControls.height;

			_bg.graphics.clear();

			_bg.graphics.beginFill(getSkinColor(BORDER_COLOR));
			_bg.graphics.drawRect(0, 0, width, height);
			_bg.graphics.endFill();
			_bg.graphics.beginFill(getSkinColor(BG_COLOR));
			_bg.graphics.drawRect(3, 3, width - 6, height - 6);
			_bg.graphics.endFill();

			_errorSprite.updateDisplayList(width, height);
		}

		/**
		 * On creation complete
		 */
		private function onComplete(e:FlexEvent):void
		{
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CREATION_COMPLETE));
		}

		public function playVideo():void
		{
			var streamState:int=_media ? _media.streamState : -1;

			switch (streamState)
			{
				case AMediaManager.STREAM_UNINITIALIZED:
				{
					logger.debug("[playVideo] Stream is uninitialized");
					_forcePlay=true;
					loadVideo();
					break;
				}
				case AMediaManager.STREAM_INITIALIZED:
				{
					logger.debug("[playVideo] Stream is initialized");
					startVideo();
					break;
				}
				case AMediaManager.STREAM_SEEKING_START:
				{
					logger.debug("[playVideo] Cannot start playing while previous seek is not complete");
					break;
				}
				case AMediaManager.STREAM_PAUSED:
				{
					resumeVideo();
					break;
				}
				case AMediaManager.STREAM_READY:
				{
					logger.debug("[playVideo] Stream is ready but the buffer is not full");
					break;
				}
				case AMediaManager.STREAM_FINISHED:
				{
					logger.debug("[playVideo] Stream is finished. Autorewind?");
					seekTo(0);
					pauseVideo();
				}
				default:
				{
					break;
				}
			}
		}

		public function pauseVideo():void
		{
			var streamState:int=_media.streamState;
			if (streamState == AMediaManager.STREAM_SEEKING_START)
				return;
			if (streamReady(_media) && (streamState == AMediaManager.STREAM_STARTED || streamState == AMediaManager.STREAM_BUFFERING || streamState == AMediaManager.STREAM_SEEKING_END))
			{
				_media.netStream.togglePause();
				logger.debug("[pauseVideo] TogglePause");
			}
		}

		public function resumeVideo():void
		{
			if (_media.streamState == AMediaManager.STREAM_SEEKING_START)
				return;
			if (streamReady(_media) && _media.streamState == AMediaManager.STREAM_PAUSED)
			{
				_media.netStream.togglePause();
			}
		}

		public function stopVideo():void
		{
			if (streamReady(_media))
			{
				//_nsc.play(false);
				_media.stop();
				_video.clear();
					//_videoReady=false;
			}
		}

		public function endVideo():void
		{
			stopVideo();
			if (streamReady(_media))
			{
				_media.netStream.close(); //Cleans the cache of the video
				_media=null;
				_mediaReady=false;
			}
		}

		public function onMetaData(event:MediaStatusEvent):void
		{
			_duration=_media.duration;
			_video.width=_media.videoWidth;
			_video.height=_media.videoHeight;

			this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.METADATA_RETRIEVED));

			scaleVideo();
			this.addEventListener(Event.ENTER_FRAME, updateProgress, false, 0, true);
		}

		/**
		 * On play button clicked
		 */
		protected function onPPBtnChanged(e:Event):void
		{
			if (_mediaReady)
			{
				if (_media.streamState == AMediaManager.STREAM_PAUSED || !_videoPlaying)
				{
					playVideo();
				}
				else
				{
					pauseVideo();
				}
			}
		}

		/**
		 * On stop button clicked
		 */
		protected function onStopBtnClick(e:StopEvent):void
		{
			stopVideo();
		}

		/**
		 * Updatting video progress
		 */
		private function updateProgress(e:Event):void
		{
			if (!_media)
				return;

			_currentTime=_media.currentTime;
			_scrubBar.updateProgress(_currentTime, _duration);

			// if not streaming show loading progress
			if (!_mediaNetConnectionUrl)
				_scrubBar.updateLoaded(_media.bytesLoaded / _media.bytesTotal);

			_eTime.updateElapsedTime(_currentTime, _duration);
		}

		protected function onScrubberDropped(e:Event):void
		{
			if (!_media)
				return;

			_media.seek(_scrubBar.seekPosition(_duration));
		}

		protected function onScrubberDragging(e:Event):void
		{
			if (!_media)
				return;
		}

		/**
		 * On volume change
		 */
		private function onVolumeChange(e:VolumeEvent):void
		{
			this.setVolume(e.volumeAmount * 100);
		}

		/**
		 * Scaling video image
		 */
		protected function scaleVideo():void
		{
			if (!autoScale)
			{
				//trace("Scaling info");

				//If the scalation is different in height and width take the smaller one
				var scaleY:Number=_videoHeight / _video.height;
				var scaleX:Number=_videoWidth / _video.width;
				var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

				//Center the video in the stage
				_video.y=Math.floor(_videoHeight / 2 - (_video.height * scaleC) / 2);
				_video.x=Math.floor(_videoWidth / 2 - (_video.width * scaleC) / 2);

				//Leave space for the margins
				_video.y+=_defaultMargin;
				_video.x+=_defaultMargin;

				//Scale the video
				_video.width=Math.ceil(_video.width * scaleC);
				_video.height=Math.ceil(_video.height * scaleC);

					//trace("Scaling info");

					// 1 black pixel, being smarter
					//_video.y+=1;
					//_video.height-=2;
					//_video.x+=1;
					//_video.width-=2;
			}
			else
			{
				_video.width=_videoWidth;
				_video.height=_videoHeight;
				_video.y=_defaultMargin + 2;
				_video.height-=4;
				_video.x=_defaultMargin + 2;
				_video.width-=4;
			}
		}

		/**
		 * Resets videoplayer appearance
		 **/
		protected function resetAppearance():void
		{
			_scrubBar.updateProgress(0, 10);
			_eTime.updateElapsedTime(0, 0);
			resetVideo(_video);
		}

		public function resetComponent():void
		{
			resetAppearance();
			freeMediaResources();
		}

		protected function freeMediaResources():void
		{
			freeMedia(_media);
		}

		protected function freeMedia(media:AMediaManager):void
		{

			if (media)
			{
				logger.debug("Destroy media: " + media.getStreamId());
				media.removeEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess);
				media.removeEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure);
				media.removeEventListener(MediaStatusEvent.STATE_CHANGED, onStreamStateChange);
				media.removeEventListener(MediaStatusEvent.METADATA_RETRIEVED, onMetaData);
				media.unpublish();
			}
			media=null;
		}

		protected function resetVideo(video:Video):void
		{
			if (video)
			{
				logger.debug("Clear video object");
				video.clear();
				video.attachNetStream(null);
				video.attachCamera(null);
			}
		}
		
		override public function dispose():void{
			super.dispose();
			var i:int=0,l:int=this.numChildren;
			if(l){
				for(i=0; i<l; i++){
					var child:* = this.getChildAt(i) as IDisposableObject;
					if(child){
						child.dispose();
					}
				}
			}
		}
	}
}
