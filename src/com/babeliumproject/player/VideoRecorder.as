/**
 * NOTES
 *
 */

package com.babeliumproject.player
{
	import avmplus.getQualifiedClassName;
	
	import com.babeliumproject.player.assets.PlayerIcons;
	import com.babeliumproject.player.controls.*;
	import com.babeliumproject.player.controls.OverlayPlayButtonSkin;
	import com.babeliumproject.player.controls.babelia.*;
	import com.babeliumproject.player.events.*;
	import com.babeliumproject.player.events.babelia.*;
	import com.babeliumproject.player.media.*;
	import com.babeliumproject.player.timedevent.CaptionManager;
	import com.babeliumproject.player.timedevent.TimeMarkerManager;
	import com.babeliumproject.player.timedevent.TimelineEventDispatcher;
	import com.babeliumproject.utils.PrivacyRights;
	import com.babeliumproject.utils.TimeMetadataParser;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.media.*;
	import flash.net.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.*;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.effects.AnimateProperty;
	import mx.events.CloseEvent;
	import mx.events.EffectEvent;
	import mx.graphics.SolidColor;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceManager;
	import mx.utils.ObjectUtil;
	
	import spark.components.Button;
	import spark.components.Image;
	import spark.primitives.BitmapImage;
	import spark.primitives.Graphic;
	import spark.primitives.Path;
	
	//import vo.ResponseVO;

	public class VideoRecorder extends VideoPlayer
	{
		/**
		 * Skin related constants
		 */
		public static const COUNTDOWN_COLOR:String="countdownColor";
		public static const ROLEBG_COLOR:String="roleBgColor";
		public static const ROLEBORDER_COLOR:String="roleBorderColor";

		/**
		 * Interface components
		 */
		private var _subtitleButton:SubtitleButton;
		private var _subtitlePanel:UIComponent;
		private var _subtitleBox:SubtitleTextBox;
		private var _arrowPanel:ArrowPanel;
		//private var _roleTalkingPanel:RoleTalkingPanel;
		private var _micActivityBar:MicActivityBar;
		private var _subtitlingControls:UIComponent;
		private var _subtitleStartEnd:SubtitleStartEndButton;
		private var _bgArrow:Sprite;

		/**
		 * Recording related variables
		 */

		/**
		 * States
		 * NOTE:
		 * XXXX XXX1: split video panel into 2 views
		 * XXXX XX1X: recording modes
		 */
		public static const PLAY_STATE:int=0; // 0000 0000
		public static const PLAY_PARALLEL_STATE:int=1; // 0000 0001
		public static const RECORD_PARALLEL_MIC_STATE:int=2; // 0000 0010
		public static const RECORD_PARALLEL_WEBCAM_STATE:int=3; // 0000 0011
		public static const UPLOAD_MODE_STATE:int=4; // 0000 0100

		private const SPLIT_FLAG:int=1; // XXXX XXX1
		private const RECORD_MODE_MASK:int=2; // XXXX XX1X
		private const UPLOAD_FLAG:int=4; // XXXX X1XX

		private var _state:int;

		protected const COUNTDOWN_TIMER_SECS:int=5;
		protected const TIMELINE_TIMER_DELAY:int=50; // Delay in ms.

		//The meaning of the gain is as follows:
		//0 silences the input audio. 50 is normal input (1x boost). 100 is boosted input (2x boost)
		protected const DEFAULT_MIC_GAIN:int=70;

		protected var _recordMedia:AMediaManager;
		protected var _recordMediaUrl:String;
		protected var _recordMediaNetConnectionUrl:String;
		protected var _recordMediaReady:Boolean;
		protected var _recordUseWebcam:Boolean;

		protected var _parallelMedia:AMediaManager;
		protected var _parallelMediaUrl:String;
		protected var _parallelMediaNetConnectionUrl:String;
		protected var _parallelMediaReady:Boolean;
		protected var _parallelMediaPlaying:Boolean;

		private var _camVideo:Video;
		private var _blackPixelsBetweenVideos:uint=0;
		private var _lastVideoHeight:Number=0;

		private var _mic:Microphone;
		private var _camera:Camera;
		private var _cameraWidth:int;
		private var _cameraHeight:int;
		private var _micCamEnabled:Boolean=false;

		private var _userdevmgr:UserDeviceManager;
		private var _privUnlock:PrivacyRights;

		private var _captionmgr:CaptionManager;
		private var _captionText:String;
		private var _captionColor:int;
		private var _captionsLoaded:Boolean=false;

		private var _markermgr:TimelineEventDispatcher;

		private var _timeMarkers:Object;
		private var _pollTimeline:Boolean=false;

		private var _countdown:Timer;
		private var _countdownTxt:TextField;
		private var _countdownTxtFormat:TextFormat;

		private var _fileName:String;
		private var _recordingMuted:Boolean=false;

		protected var _parallelMuteOverride:Boolean=false;
		
		protected var _parallelMuted:Boolean=false;
		protected var _parallelLastVolume:Number;
		protected var _parallelCurrentVolume:Number;
		protected var _micSilenced:Boolean;
		protected var _micCurrentGain:Number;
		protected var _micLastGain:Number;

		private var _displayCaptions:Boolean=false;
		private var _displayEventArrows:Boolean=false;

		[Bindable]
		public var secondStreamState:int;

		private var _ttimer:Timer;

		public static const SUBTILE_INSERT_DELAY:Number=0.5;

		private var _micImage:Graphic;
		private var _overlayButton:Button;


		/**
		 * CONSTRUCTOR
		 */
		public function VideoRecorder()
		{
			super("VideoRecorder"); // Required for setup skinable component

			_captionmgr=new CaptionManager();

			_subtitleButton=new SubtitleButton();
			_subtitleButton.height=26;
			_subtitleButton.width=50;
			_playerControls.addChild(_subtitleButton);

			_subtitlePanel=new UIComponent();
			_subtitleBox=new SubtitleTextBox();
			_subtitlePanel.visible=false;
			_subtitlePanel.addChild(_subtitleBox);

			_arrowPanel=new ArrowPanel();

			_countdownTxtFormat=new TextFormat();
			_countdownTxtFormat.bold=true;
			_countdownTxtFormat.size=30;
			_countdownTxtFormat.font="Arial";
			_countdownTxt=new TextField();
			_countdownTxt.text="5";
			_countdownTxt.selectable=false;
			_countdownTxt.visible=false;
			_countdownTxt.defaultTextFormat=_countdownTxtFormat;

			_camVideo=new Video();
			_camVideo.visible=false;

			_micImage=new Graphic();
			var p:Path=new Path();
			var f:SolidColor=new SolidColor();
			p.fill=f;
			f.color=PlayerIcons.cord_microphone_icon.color;
			p.data=PlayerIcons.cord_microphone_icon.path;
			_micImage.addElement(p);
	
			_micImage.height=PlayerIcons.cord_microphone_icon.height;
			_micImage.width=PlayerIcons.cord_microphone_icon.width;
			_micImage.visible=false;

			_subtitleStartEnd=new SubtitleStartEndButton();
			_subtitleStartEnd.visible=false;

			_playerControls.addChild(_subtitleStartEnd);

			_micActivityBar=new MicActivityBar();
			_micActivityBar.height=22;
			_micActivityBar.visible=false;

			_micCurrentGain=DEFAULT_MIC_GAIN;
			_parallelCurrentVolume=DEFAULT_VOLUME;
			_parallelLastVolume=DEFAULT_VOLUME;

			_overlayButton=new Button();
			_overlayButton.setStyle("skinClass", OverlayPlayButtonSkin);
			_overlayButton.width=128;
			_overlayButton.height=128;
			_overlayButton.buttonMode=true;
			_overlayButton.visible=false;
			_overlayButton.addEventListener(MouseEvent.CLICK, overlayClicked);

			/**
			 * Events listeners
			 **/
			_subtitleButton.addEventListener(SubtitleButtonEvent.STATE_CHANGED, onSubtitleButtonClicked);
			_subtitleStartEnd.addEventListener(SubtitlingEvent.START, onSubtitlingEvent);
			_subtitleStartEnd.addEventListener(SubtitlingEvent.END, onSubtitlingEvent);
			//_recStopBtn.addEventListener(RecStopButtonEvent.CLICK, onRecStopEvent);

			//Remove the upper layers to reorder
			removeChild(_busyIndicator);
			removeChild(_topLayer);
			removeChild(_scrubBar);
			removeChild(_playerControls);
			
			addChild(_micImage);
			addChild(_camVideo);
	
			addChild(_micActivityBar);
			addChild(_arrowPanel);

			addChild(_subtitlePanel);
			addChild(_playerControls);
			addChild(_scrubBar);
			addChild(_countdownTxt);
			addChild(_topLayer);
			addChild(_busyIndicator);
			addChild(_overlayButton);

			/**
			 * Adds skinable components to dictionary
			 */
			putSkinableComponent(COMPONENT_NAME, this);
			putSkinableComponent(_subtitleButton.COMPONENT_NAME, _subtitleButton);
			putSkinableComponent(_subtitleBox.COMPONENT_NAME, _subtitleBox);
			putSkinableComponent(_arrowPanel.COMPONENT_NAME, _arrowPanel);
			putSkinableComponent(_subtitleStartEnd.COMPONENT_NAME, _subtitleStartEnd);
			putSkinableComponent(_micActivityBar.COMPONENT_NAME, _micActivityBar);
		}

		public function setCaptions(captions:Object, cinstance:Object=null):void
		{
			if (_captionmgr)
			{
				removeEventListener(PollingEvent.ENTER_FRAME, _captionmgr.onIntervalTimer);
				_captionmgr.removeAllMarkers();
				_captionmgr.reset();
			}
			if (!captions)
				return;

			if (!_captionmgr)
				_captionmgr=new CaptionManager();

			_captionsLoaded=_captionmgr.parseCaptions(captions, this, cinstance);

			if (_captionsLoaded)
			{
				_subtitleButton.enabled=true;
			}
			else
			{
				logger.debug("Captions could not be parsed");
			}

			if (_displayCaptions)
			{
				addEventListener(PollingEvent.ENTER_FRAME, _captionmgr.onIntervalTimer, false, 0, true);
				pollTimeline=true;
			}
		}

		public function setTimeMarkers(markers:Array):void
		{
			if (!_markermgr)
				_markermgr=new TimelineEventDispatcher();
			_markermgr.removeAllMarkers();
			_markermgr.addMarkers(markers);
		}

		public function showCaption(args:Object):void
		{
			if (args)
			{
				_captionText=String(args.text);
				_captionColor=int(args.color);
				_subtitleBox.setText(_captionText, _captionColor);
			}
		}

		public function hideCaption(args:Object=null):void
		{
			_subtitleBox.setText(null);
		}

		public function set displayCaptions(value:Boolean):void
		{
			if (_displayCaptions == value)
				return;

			_displayCaptions=value;
			_subtitlePanel.visible=_displayCaptions;
			_subtitleButton.selected=_displayCaptions;

			if (_displayCaptions)
			{
				addEventListener(PollingEvent.ENTER_FRAME, _captionmgr.onIntervalTimer, false, 0, true);
				pollTimeline=true;
			}
			else
			{
				removeEventListener(PollingEvent.ENTER_FRAME, _captionmgr.onIntervalTimer);
				pollTimeline=false;
			}

			invalidateDisplayList();
		}

		public function get displayCaptions():Boolean
		{
			return _displayCaptions;
		}

		public function set pollTimeline(value:Boolean):void
		{
			if (_pollTimeline == value)
				return;

			_pollTimeline=value;

			if (_pollTimeline)
			{
				if (!_ttimer)
				{
					_ttimer=new Timer(TIMELINE_TIMER_DELAY, 0);
				}
				_ttimer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
				_ttimer.start();
			}
			else
			{
				if (_ttimer)
				{
					_ttimer.removeEventListener(TimerEvent.TIMER, onTimerTick);
					_ttimer.reset();
				}
			}
		}

		public function get pollTimeline():Boolean
		{
			return _pollTimeline;
		}

		private function onTimerTick(e:TimerEvent):void
		{
			if (streamReady(_media))
			{
				this.dispatchEvent(new PollingEvent(PollingEvent.ENTER_FRAME, _media.currentTime));
			}
			//if (streamReady(_recNsc)){
			//	//If the user didn't stop recording after _maxRecTime elapsed, force a stop
			//	if ((_maxRecTime - _recNsc.netStream.time) <=0){
			//		abortRecording();
			//	}
			//}
		}

		/**
		 * @param arrows: ArrayCollection[{time:Number,role:String}]
		 * @param selectedRole: selected role by the user.
		 * 						This makes the arrows be red or black.
		 */
		public function setArrows(timemetadata:Object):void
		{
			if (!timemetadata || !_duration)
				return;

			_arrowPanel.setArrows(timemetadata, _duration);
			_scrubBar.setMarks(timemetadata, _duration);
		}

		// remove arrows from panel
		public function removeArrows():void
		{
			_arrowPanel.removeArrows();
			_scrubBar.removeMarks();
		}

		// show/hide arrow panel
		protected function set displayEventArrows(value:Boolean):void
		{
			if (_state != PLAY_STATE)
			{
				_displayEventArrows=value;
				_arrowPanel.visible=_displayEventArrows;
			}
			else
			{
				_arrowPanel.visible=false;
			}
			invalidateDisplayList();
		}

		protected function get displayEventArrows():Boolean
		{
			return _displayEventArrows;
		}

		/*
		public function startTalking(role:String, duration:Number):void
		{
			if (!_roleTalkingPanel.talking)
				_roleTalkingPanel.setTalking(role, duration);
		}*/

		/**
		 * Enable/disable subtitling controls
		 */
		public function set subtitlingControls(flag:Boolean):void
		{
			_subtitleStartEnd.visible=flag;
			this.updateDisplayList(0, 0); //repaint component
		}

		public function get subtitlingControls():Boolean
		{
			return _subtitlingControls.visible;
		}

		/**
		 * Autoplay
		 */
		override public function set autoPlay(tf:Boolean):void
		{
			super.autoPlay=tf;
			tf ? _overlayButton.visible=false : _overlayButton.visible=true;
		}

		protected function getInternalState():int
		{
			return _state;
		}

		protected function setInternalState(state:int):void
		{
			if (_state == state)
				return;

			_state=state;

			//Changes the layout of the items in the video display area
			switchPerspective();

			//dispatchEvent(new VideoRecorderEvent(VideoRecorderEvent.RECORDER_STATE_CHANGED,_state));
		}

		/**
		 * Video player's state
		 */
		/*
		public function get state():int
		{
			return _state;
		}

		public function set state(state:int):void
		{
			stopVideo();

			if (state == PLAY_BOTH_STATE || state == PLAY_STATE)
				enableControls();

			_state=state;
			switchPerspective();
		}*/

		public function overlayClicked(event:MouseEvent):void
		{
			_ppBtn.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		}

		override protected function onPPBtnChanged(e:Event):void
		{
			super.onPPBtnChanged(e);
			if (_overlayButton.visible)
				_overlayButton.visible=false;
		}

		public function getMicGain():void
		{
			_micCurrentGain;
		}

		public function setMicGain():void
		{

		}
		
		public function forcedMuteParallel():void{
			muteParallel();
			_parallelMuteOverride=true;
		}
		
		public function forcedUnMuteParallel():void{
			_parallelMuteOverride=false;
			unMuteParallel();
		}
		
		public function isParallelMuted():Boolean{
			return _parallelMuted;
		}
		
		public function muteParallel():void{
			if(!isParallelMuted()){
				_parallelMuted=true;
				if (_state & RECORD_MODE_MASK)
				{
					var newGain:Number=0;
					_micLastGain=_micCurrentGain;
					
					if(!_parallelMuteOverride){
						if (_mic)
							_mic.gain=newGain;
					}
				}
				else if (_state == PLAY_PARALLEL_STATE)
				{
					var newVolume:Number=0;
					
					//Store the volume that we had before muting to restore to that volume when unmuting
					_parallelLastVolume=_parallelCurrentVolume;
					
					if(!_parallelMuteOverride){
						if (_parallelMedia)
							_parallelMedia.volume=newVolume;
					}
				}
			}
		}
		
		public function unMuteParallel():void{
			if(isParallelMuted()){
				_parallelMuted=false;
				if (_state & RECORD_MODE_MASK)
				{
					var newGain:Number=_micLastGain;
					
					if(!_parallelMuteOverride){
						if (_mic)
							_mic.gain=newGain;
					}
				}
				else if (_state == PLAY_PARALLEL_STATE)
				{
					var newVolume:Number=_parallelLastVolume;
					
					if(!_parallelMuteOverride){
						if (_parallelMedia)
							_parallelMedia.volume=newVolume;
					}
				}
			}
		}

		/**
		 *  Highlight components
		 **/
		public function set highlight(flag:Boolean):void
		{
			_arrowPanel.highlight=flag;
			//_roleTalkingPanel.highlight=flag;
		}


		/**
		 * Get video time
		 **/
		public function get streamTime():Number
		{
			return _media.currentTime;
		}

		override public function setVolume(value:Number):void{
			if(_state==PLAY_PARALLEL_STATE){
				if (!isNaN(value) && value >= 0 && value <= 100)
				{
					_currentVolume=value;
					_parallelCurrentVolume=value;
					if(!_muteOverride){
						if(_media) _media.volume = value;
					}
					if(!_parallelMuteOverride){
						if(_parallelMedia) _parallelMedia.volume = value;
					}
				}
			} else {
				super.setVolume(value);
			}
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var additionalY:Number = _micActivityBar.visible ? _micActivityBar.height : 0;
			
			_playerControls.y+=additionalY;
			_scrubBar.y+=additionalY;
			
			_subtitleButton.x=_playerControls.width-_subtitleButton.width;
			_audioSlider.x=_subtitleButton.y-_audioSlider.width;
			
			_audioSlider.refresh();
			_subtitleButton.refresh();

			_micActivityBar.width=_videoWidth;
			_micActivityBar.x=_defaultMargin;
			_micActivityBar.refresh();
			_micActivityBar.y=_scrubBar.y - _micActivityBar.height;
			
			if (_subtitleStartEnd.visible)
			{
				_subtitleButton.includeInLayout=false;
				_subtitleButton.visible=false;
				
				_subtitleStartEnd.x=_ppBtn.x + _ppBtn.width;
				_eTime.x=_subtitleStartEnd.x+_subtitleStartEnd.width;
				_audioSlider.x=_playerControls.width-_audioSlider.width;
			}
			else
			{
				_subtitleButton.includeInLayout=true;
				_subtitleButton.visible=true;
				
				_eTime.x=_ppBtn.x + _ppBtn.width;
				_subtitleButton.x=_playerControls.width - _subtitleButton.width;
				_audioSlider.x=_subtitleButton.x - _audioSlider.width;
			}

			
			_subtitlePanel.width=_playerControls.width;
			_subtitlePanel.height=_videoHeight * 0.75;
			_subtitlePanel.x=_defaultMargin;
			_subtitlePanel.y=_videoHeight - _subtitlePanel.height;


			_subtitleBox.y=0;
			_subtitleBox.resize(_videoWidth, _videoHeight * 0.75);

			// Resize arrowPanel
			_arrowPanel.resize(_scrubBar.width, 16);
			_arrowPanel.x=_scrubBar.x;
			_arrowPanel.y=_scrubBar.y - _arrowPanel.height;
		
			// Countdown
			_countdownTxtFormat.color=getSkinColor(COUNTDOWN_COLOR);
			_countdownTxt.setTextFormat(_countdownTxtFormat);
			
			_countdownTxt.x=_videoWidth / 2 - 10;
			_countdownTxt.y=_videoHeight / 2 - 10;
			_countdownTxt.width=_videoWidth;
			_countdownTxt.height=_videoHeight;

			//Play overlay
			_overlayButton.width=_videoWidth;
			_overlayButton.height=_videoHeight;

			drawBG();
		}

		override protected function drawBG():void
		{

			/**
			 * Recalculate total height
			 */

			_micActivityBar.height=22;

			var h4:Number=_micActivityBar.visible ? _micActivityBar.height : 0;

			totalHeight=_videoHeight + h4 + _scrubBar.height + _playerControls.height;

			_bg.graphics.clear();

			_bg.graphics.beginFill(getSkinColor(BG_COLOR));
			_bg.graphics.drawRect(0, 0, width, height);
			_bg.graphics.endFill();

			_errorSprite.updateDisplayList(width, height);
		}

		/**
		 * Overriden play video:
		 * - Adds a listener to video widget
		 */
		override public function playVideo():void
		{
			if (_state == PLAY_PARALLEL_STATE)
			{
				playVideoParallel();
			}
			else
			{
				super.playVideo();
			}
		}

		protected function playVideoParallel():void
		{
			var lState:int=_media ? _media.streamState : -1;
			var rState:int=_parallelMedia ? _parallelMedia.streamState : -1;

			switch (lState)
			{
				case AMediaManager.STREAM_UNINITIALIZED:
				{
					logger.debug("[playVideoParallel] Streams are uninitialized");
					_forcePlay=true;
					loadParallelVideo();
					break;
				}
				case AMediaManager.STREAM_INITIALIZED:
				{
					logger.debug("[playVideoParallel] Streams are initialized");
					startVideo();
					break;
				}
				case AMediaManager.STREAM_SEEKING_START:
				{
					logger.debug("[playVideoParallel] Cannot start playing while previous seek is not complete");
					break;
				}
				case AMediaManager.STREAM_PAUSED:
				{
					resumeVideo();
					break;
				}
				case AMediaManager.STREAM_READY:
				{
					logger.debug("[playVideoParallel] Streams are ready but the buffer is not full");
					break;
				}
				case AMediaManager.STREAM_FINISHED:
				{
					logger.debug("[playVideoParallel] Streams are finished. Autorewind?");
					seekTo(0);
					pauseVideo();
				}
				default:
				{
					break;
				}
			}
		}

		override public function seekTo(seconds:Number):void
		{
			super.seekTo(seconds);
			if (_state == PLAY_PARALLEL_STATE)
			{
				_parallelMedia.seek(seconds);
			}
		}

		/**
		 * Overriden pause video:
		 * - Pauses talk if any role is talking
		 * - Pauses second stream if any
		 */
		override public function pauseVideo():void
		{
			//This won't work, exit right away
			if (_state & RECORD_MODE_MASK && _micCamEnabled)
			{
				return;

					//if (_recordMedia.streamState == AMediaManager.STREAM_SEEKING_START)
					//	return;
					//if (streamReady(_recordMedia) && (_recordMedia.streamState == AMediaManager.STREAM_STARTED || _recordMedia.streamState == AMediaManager.STREAM_BUFFERING))
					//	_recordMedia.netStream.togglePause();
			}

			if (_state == PLAY_PARALLEL_STATE)
			{
				if (_parallelMedia.streamState == AMediaManager.STREAM_SEEKING_START)
					return;
				if (streamReady(_parallelMedia) && (_parallelMedia.streamState == AMediaManager.STREAM_STARTED || _parallelMedia.streamState == AMediaManager.STREAM_BUFFERING))
					_parallelMedia.netStream.togglePause();
			}

			super.pauseVideo();

			//if (_roleTalkingPanel.talking)
			//	_roleTalkingPanel.pauseTalk();
		}

		/**
		 * Overriden resume video:
		 * - Resumes talk if any role is talking
		 * - Resumes secon stream if any
		 */
		override public function resumeVideo():void
		{
			//This won't work, exit right away
			if (_state & RECORD_MODE_MASK && _micCamEnabled)
			{
				return;

					//if (_recordMedia.streamState == AMediaManager.STREAM_SEEKING_START)
					//	return;
					//if (streamReady(_recordMedia) && _recordMedia.streamState == AMediaManager.STREAM_PAUSED){
					//	_recordMedia.netStream.togglePause();
					//}
			}

			if (_state == PLAY_PARALLEL_STATE)
			{
				if (_parallelMedia.streamState == AMediaManager.STREAM_SEEKING_START)
					return;
				if (streamReady(_parallelMedia) && _parallelMedia.streamState == AMediaManager.STREAM_PAUSED)
				{
					_parallelMedia.netStream.togglePause();
				}
			}

			super.resumeVideo();

			//if (_roleTalkingPanel.talking)
			//	_roleTalkingPanel.resumeTalk();

		}

		/**
		 * Overriden stop video:
		 * - Stops talk if any role is talking
		 * - Stops second stream if any
		 */
		override public function stopVideo():void
		{
			super.stopVideo();

			if (_state & RECORD_MODE_MASK && _micCamEnabled)
			{
				if (streamReady(_recordMedia))
				{
					_recordMedia.stop();
					_camVideo.clear();
				}
			}

			if (_state == PLAY_PARALLEL_STATE)
			{
				if (streamReady(_parallelMedia))
				{
					_parallelMedia.stop();
					_camVideo.clear();
				}
			}

			//if (_roleTalkingPanel.talking)
			//	_roleTalkingPanel.stopTalk();

			hideCaption();
		}

		override public function endVideo():void
		{
			super.endVideo();

			if (_state & RECORD_MODE_MASK && _micCamEnabled)
			{
				if (streamReady(_recordMedia))
				{
					_recordMedia.netStream.close(); //Cleans the cache of the video
					_recordMedia=null;
					_recordMediaReady=false;
				}
			}

			if (_state == PLAY_PARALLEL_STATE)
			{
				if (streamReady(_parallelMedia))
				{
					_parallelMedia.netStream.close(); //Cleans the cache of the video
					_parallelMedia=null;
					_parallelMediaReady=false;
				}
			}
		}

		/**
		 * Overriden on seek end:
		 * - clear subtitles from panel
		 **/
		override protected function onScrubberDropped(e:Event):void
		{
			if (!_media)
				return;
			
			var seconds:Number=_scrubBar.seekPosition(_duration);
			
			_media.seek(seconds);
			if (_state == PLAY_PARALLEL_STATE && _parallelMedia)
			{
				_parallelMedia.seek(seconds);
			}
			
			//super.onScrubberDropped(e);
			hideCaption();
		}

		/**
		 * On subtitle button clicked:
		 * - Do show/hide subtitle panel
		 */
		private function onSubtitleButtonClicked(e:SubtitleButtonEvent):void
		{
			if (e.state)
				doShowSubtitlePanel();
			else
				doHideSubtitlePanel();
		}

		/**
		 * Subtitle Panel's show animation
		 */
		private function doShowSubtitlePanel():void
		{
			_subtitlePanel.visible=true;
			var a1:AnimateProperty=new AnimateProperty();
			a1.target=_subtitlePanel;
			a1.property="alpha";
			a1.toValue=1;
			a1.duration=250;
			a1.play();

			this.drawBG(); // Repaint bg
		}

		/**
		 * Subtitle Panel's hide animation
		 */
		private function doHideSubtitlePanel():void
		{
			var a1:AnimateProperty=new AnimateProperty();
			a1.target=_subtitlePanel;
			a1.property="alpha";
			a1.toValue=0;
			a1.duration=250;
			a1.play();
			a1.addEventListener(EffectEvent.EFFECT_END, onHideSubtitleBar);
		}

		private function onHideSubtitleBar(e:Event):void
		{
			_subtitlePanel.visible=false;
			this.drawBG(); // Repaint bg
		}

		/**
		 * On subtitling controls clicked: start or end subtitling button
		 * This method adds ns.time to event and gives it to parent component
		 *
		 * NOTE: Made public because the subtitling module has it's own subtitling
		 * controls that need access to the current video time.
		 */
		public function onSubtitlingEvent(e:SubtitlingEvent):void
		{
			var time:Number=_media.currentTime;
			this.dispatchEvent(new SubtitlingEvent(e.type, time - SUBTILE_INSERT_DELAY));
		}


		/**
		 * Switch video's perspective based on video player's
		 * actual state
		 */
		private function switchPerspective():void
		{
			switch (_state)
			{
				case RECORD_PARALLEL_WEBCAM_STATE:
				{
					splitVideoPanel();
					break;
				}
				case RECORD_PARALLEL_MIC_STATE:
				{
					resetVideoDisplay();
					break;
				}
				case UPLOAD_MODE_STATE:
				{
					resetVideoDisplay();
					scaleCamVideo(_videoWidth, _videoHeight, false);
					break;
				}
				case PLAY_PARALLEL_STATE:
				{
					splitVideoPanel();
					break;
				}
				default: //PLAY_STATE
				{
					playLayout();
					break;
				}
			}
			invalidateDisplayList();
		}

		protected function playLayout():void
		{
			resetAppearance();
			freeMedia(_recordMedia);
			freeMedia(_parallelMedia);
			_autoPlayOverride=false;
			enableControls();
		}

		protected function playParallelLayout():void
		{

		}

		protected function recordParallelLayout():void
		{

		}

		// Prepare countdown timer
		private function startCountdown():void
		{
			_countdown=new Timer(1000, COUNTDOWN_TIMER_SECS);
			_countdown.addEventListener(TimerEvent.TIMER, onCountdownTick, false, 0, true);
			_countdown.start();
		}

		// On Countdown tick
		private function onCountdownTick(tick:TimerEvent):void
		{
			if (_countdown.currentCount == _countdown.repeatCount)
			{
				_countdownTxt.visible=false;
				_video.visible=true;

				if (_state == RECORD_PARALLEL_WEBCAM_STATE || _state == UPLOAD_MODE_STATE)
				{
					_camVideo.visible=true;
					_micImage.visible=true;
				}

				// Reset countdown timer
				_countdownTxt.text="5";
				_countdownTxt.setTextFormat(_countdownTxtFormat);
				_countdown.stop();
				_countdown.reset();

				startRecording();
			}
			else if (_state != PLAY_STATE)
			{
				_countdownTxt.text=new String(5 - _countdown.currentCount);
				_countdownTxt.setTextFormat(_countdownTxtFormat);
			}
		}


		private function prepareDevices():void
		{
			_camera=null;
			_mic=null;
			_userdevmgr=new UserDeviceManager();
			_userdevmgr.useMicAndCamera=_recordUseWebcam;
			_userdevmgr.addEventListener(UserDeviceEvent.DEVICE_STATE_CHANGE, deviceStateHandler, false, 0, true);
			_userdevmgr.initDevices();
		}

		private function configureDevices():void
		{
			_micCamEnabled=_userdevmgr.deviceAccessGranted;
			if (_recordUseWebcam)
			{
				_camera=_userdevmgr.camera;
				_cameraWidth=_userdevmgr.defaultCameraWidth;
				_cameraHeight=_userdevmgr.defaultCameraHeight;
				_camera.setMode(_cameraWidth, _cameraHeight, 15, false);
			}
			_mic=_userdevmgr.microphone;
			_mic.rate=_userdevmgr.defaultMicRate;
			_mic.setUseEchoSuppression(_userdevmgr.defaultMicEchoSuppression);
			_mic.setSilenceLevel(0, 60000000);
			_micActivityBar.mic=_mic;

			//_camVideo.width=_userdevmgr.defaultCameraWidth;
			//_camVideo.height=_userdevmgr.defaultCameraHeight;
			_camVideo.attachCamera(_camera);
			_camVideo.smoothing=true;

			_video.visible=false;
			_camVideo.visible=false;
			_micImage.visible=false;
			_countdownTxt.visible=true;

			prepareRecording();
			startCountdown();
		}

		private function deviceStateHandler(event:UserDeviceEvent):void
		{
			var devstate:int=event.state;
			if (!_privUnlock)
			{
				if (devstate == UserDeviceEvent.DEVICE_ACCESS_GRANTED)
				{
					configureDevices();
				}
				else
				{
					var appwindow:DisplayObjectContainer=FlexGlobals.topLevelApplication.parent;
					var modal:Boolean=true;
					_privUnlock=new PrivacyRights();
					_privUnlock.addEventListener(UserDeviceEvent.ACCEPT, privacyAcceptHandler, false, 0, true);
					_privUnlock.addEventListener(UserDeviceEvent.RETRY, privacyRetryHandler, false, 0, true);
					_privUnlock.addEventListener(UserDeviceEvent.CANCEL, privacyCancelHandler, false, 0, true);
					_privUnlock.displayState(devstate);
					PopUpManager.addPopUp(_privUnlock, appwindow, modal);
					PopUpManager.centerPopUp(_privUnlock);
					if (devstate == UserDeviceEvent.DEVICE_ACCESS_NOT_GRANTED)
					{
						_userdevmgr.showPrivacySettings();
					}
				}
			}
			else
			{
				_privUnlock.displayState(devstate);
				if (devstate == UserDeviceEvent.DEVICE_ACCESS_NOT_GRANTED)
				{
					_userdevmgr.showPrivacySettings();
				}
			}
		}

		private function privacyAcceptHandler(event:Event):void
		{
			PopUpManager.removePopUp(_privUnlock);
			_privUnlock.removeEventListener(UserDeviceEvent.ACCEPT, privacyAcceptHandler);
			_privUnlock.removeEventListener(UserDeviceEvent.RETRY, privacyRetryHandler);
			_privUnlock.removeEventListener(UserDeviceEvent.CANCEL, privacyCancelHandler);
			_privUnlock=null;
			_userdevmgr.removeEventListener(UserDeviceEvent.DEVICE_STATE_CHANGE, deviceStateHandler);
			configureDevices();
		}

		private function privacyRetryHandler(event:Event):void
		{
			_userdevmgr.initDevices();
		}

		private function privacyCancelHandler(event:Event):void
		{
			PopUpManager.removePopUp(_privUnlock);
			_privUnlock.removeEventListener(UserDeviceEvent.ACCEPT, privacyAcceptHandler);
			_privUnlock.removeEventListener(UserDeviceEvent.RETRY, privacyRetryHandler);
			_privUnlock.removeEventListener(UserDeviceEvent.CANCEL, privacyCancelHandler);
			_privUnlock=null;
			_userdevmgr.removeEventListener(UserDeviceEvent.DEVICE_STATE_CHANGE, deviceStateHandler);
			dispatchEvent(new RecordingEvent(RecordingEvent.USER_DEVICE_ACCESS_DENIED));
		}


		private function prepareRecording():void
		{
			// Disable seek
			seekUsingScrubber=false;

			disableControls();

			_micActivityBar.visible=true;
			_micActivityBar.mic=_mic;
		}

		/**
		 * Start recording
		 */
		private function startRecording():void
		{
			if (!(_state & RECORD_MODE_MASK))
				return; // security check

			//if (_started)
			//	resumeVideo();
			//else
			playVideo();

			if (_state & RECORD_MODE_MASK)
			{
				muteParallel(); // mic starts muted
			}

			_ppBtn.state=PlayButton.PAUSE_STATE;

			_recordMedia.publish(_mic, _camera);
		}


		/**
		 * Split video panel into 2 views
		 */
		private function splitVideoPanel():void
		{
			//The stage should be splitted only when the right state is set
			if (!(_state & SPLIT_FLAG))
				return;

			var w:Number=_videoWidth / 2 - _blackPixelsBetweenVideos;
			//var h:int=Math.ceil(w * 0.75); //_video.height / _video.width);
			var h:Number=_videoHeight;
			
			/*
			if (_videoHeight != h) // cause we can call twice to this method
				_lastVideoHeight=_videoHeight; // store last value

			_videoHeight=h;
			*/
			
			var scaleY:Number=h / _video.height;
			var scaleX:Number=w / _video.width;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

			_video.y=Math.floor(h / 2 - (_video.height * scaleC) / 2);
			_video.x=Math.floor(w / 2 - (_video.width * scaleC) / 2);
			_video.y+=_defaultMargin;
			_video.x+=_defaultMargin;

			_video.width*=scaleC;
			_video.height*=scaleC;

			//Resize the cam display
			scaleCamVideo(w, h);

			updateDisplayList(0, 0); // repaint

			//trace("The video panel has been splitted");
		}

		/**
		 * Recover video panel's original size
		 */
		private function resetVideoDisplay():void
		{
			logger.info("Reset video display");
			// NOTE: problems with _videoWrapper.width
			/*
			if (_lastVideoHeight > _videoHeight)
				_videoHeight=_lastVideoHeight;
			*/
			scaleVideo();

			_camVideo.visible=false;
			_micImage.visible=false;
			_micActivityBar.visible=false;
		}

		private function scaleCamVideo(w:Number, h:Number, split:Boolean=true):void
		{

			var scaleY:Number=h / _cameraHeight;
			var scaleX:Number=w / _cameraWidth;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

			_camVideo.width=_cameraWidth * scaleC;
			_camVideo.height=_cameraHeight * scaleC;

			if (split)
			{
				_camVideo.y=Math.floor(h / 2 - _camVideo.height / 2);
				_camVideo.x=Math.floor(w / 2 - _camVideo.width / 2);
				_camVideo.y+=_defaultMargin;
				_camVideo.x+=(w + _defaultMargin);
			}
			else
			{
				_camVideo.y=_defaultMargin + 2;
				_camVideo.height-=4;
				_camVideo.x=_defaultMargin + 2;
				_camVideo.width-=4;
			}


			_micImage.y=(_videoHeight - _micImage.height) / 2;
			_micImage.x=_videoWidth - _micImage.width - (_camVideo.width - _micImage.width) / 2;
		}

		override protected function scaleVideo():void
		{
			super.scaleVideo();
			if (_state & SPLIT_FLAG)
			{
				var w:Number=_videoWidth / 2 - _blackPixelsBetweenVideos;
				var h:int=_videoHeight;

				/*
				if (_videoHeight != h)
					_lastVideoHeight=_videoHeight;

				_videoHeight=h;
				*/
				
				var scaleY:Number=h / _video.height;
				var scaleX:Number=w / _video.width;
				var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

				_video.y=Math.floor(h / 2 - (_video.height * scaleC) / 2);
				_video.x=Math.floor(w / 2 - (_video.width * scaleC) / 2);
				_video.y+=_defaultMargin;
				_video.x+=_defaultMargin;

				_video.width*=scaleC;
				_video.height*=scaleC;
			}
		}

		public function unattachUserDevices():void
		{
			if (_recordMedia)
			{
				_recordMedia.removeEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess);
				_recordMedia.removeEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure);
				_recordMedia.removeEventListener(MediaStatusEvent.STATE_CHANGED, onStreamStateChange);
				_recordMedia.removeEventListener(MediaStatusEvent.METADATA_RETRIEVED, onMetaData);
				_recordMedia.unpublish();
			}

			_camVideo.attachNetStream(null);
			_camVideo.attachCamera(null);
			_camVideo.clear();

			_camera=null;
			_mic=null;
			_recordMedia=null;
		}

		/**
		 * The overriden loadVideoByUrl accepts parallel media loading
		 * @param param
		 */
		override public function loadVideoByUrl(param:Object, timemarkers:Object=null):void
		{
			unattachUserDevices();
			hideCaption();
			seekUsingScrubber=true;
			if (!param)
				return;
			if (getQualifiedClassName(param) == 'Object')
			{
				if (param.leftMedia)
				{
					var lmedia:Object=parseMediaObject(param.leftMedia);
					logger.debug(ObjectUtil.toString(lmedia));
					_mediaNetConnectionUrl=lmedia.netConnectionUrl;
					_mediaUrl=lmedia.mediaUrl;
					_mediaPosterUrl=lmedia.mediaPosterUrl;

					var rmedia:Object;
					if (param.rightMedia)
					{
						rmedia=parseMediaObject((param.rightMedia as Object));
					}
					if (lmedia && rmedia)
					{
						setInternalState(PLAY_PARALLEL_STATE);
						_parallelMediaNetConnectionUrl=rmedia.netConnectionUrl;
						_parallelMediaUrl=rmedia.mediaUrl;
						loadParallelVideo();
					}
					else if (lmedia)
					{
						setInternalState(PLAY_STATE);
						loadVideo();
					}
				}
				else if (param.recordMedia)
				{
					var recmedia:Object=parseMediaObject(param.recordMedia);
					var playmedia:Object;
					if (param.playbackMedia)
					{
						playmedia=parseMediaObject(param.playbackMedia);
					}
					if (recmedia && playmedia)
					{

						_recordMediaNetConnectionUrl=recmedia.netConnectionUrl;
						_recordMediaUrl=recmedia.mediaUrl;
						_mediaNetConnectionUrl=playmedia.netConnectionUrl;
						_mediaUrl=playmedia.mediaUrl;
						_mediaPosterUrl=playmedia.mediaPosterUrl;
						setInternalState(_recordUseWebcam ? RECORD_PARALLEL_WEBCAM_STATE : RECORD_PARALLEL_MIC_STATE);
					}
					else if (recmedia)
					{
						_mediaNetConnectionUrl=null;
						_mediaUrl=null;
						_mediaPosterUrl=null;
						_recordMediaNetConnectionUrl=recmedia.netConnectionUrl;
						_recordMediaUrl=recmedia.mediaUrl;
					}
					loadRecordVideo();
				}
				else
				{
					var media:Object=parseMediaObject(param);
					_mediaNetConnectionUrl=media.netConnectionUrl;
					_mediaUrl=media.mediaUrl;
					_mediaPosterUrl=media.mediaPosterUrl;
					setInternalState(PLAY_STATE);
					loadVideo();
				}
			}
			prepareTimeMarkers(timemarkers);
		}

		protected function loadParallelVideo():void
		{
			_mediaReady=false;
			_parallelMediaReady=false;
			logger.info("Load parallel videos: {0}, {1}", [_mediaNetConnectionUrl + '/' + _mediaUrl, _parallelMediaNetConnectionUrl + '/' + _parallelMediaUrl]);
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

				//Close the streams and free the their resources
				freeMedia(_media);
				freeMedia(_parallelMedia);
				_media=null;
				_parallelMedia=null;

				if (_mediaNetConnectionUrl)
				{
					_media=new ARTMPManager("leftStream");
					_media.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_media.setup(_mediaNetConnectionUrl, _mediaUrl);
				}
				else
				{
					_media=new AVideoManager("leftStream");
					_media.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_media.setup(_mediaUrl);
				}

				if (_parallelMediaNetConnectionUrl)
				{
					_parallelMedia=new ARTMPManager("rightStream");
					_parallelMedia.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_parallelMedia.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_parallelMedia.setup(_parallelMediaNetConnectionUrl, _parallelMediaUrl);
				}
				else
				{
					_parallelMedia=new AVideoManager("rightStream");
					_parallelMedia.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_parallelMedia.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_parallelMedia.setup(_parallelMediaUrl);
				}
			}
		}

		public function loadRecordVideo():void
		{
			_mediaReady=false;
			_recordMediaReady=false;

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

			//Close the streams and free their resources
			freeMediaResources();
			_media=null;
			_recordMedia=null;
			_parallelMedia=null;

			if (_mediaUrl != '')
			{
				if (_mediaNetConnectionUrl)
				{
					_media=new ARTMPManager("playStream");
					_media.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_media.setup(_mediaNetConnectionUrl, _mediaUrl);
				}
				else
				{
					_media=new AVideoManager("playStream");
					_media.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_media.setup(_mediaUrl);
				}
			}
			if (_recordMediaUrl != '')
			{
				if (_recordMediaNetConnectionUrl)
				{
					_recordMedia=new ARTMPManager("recordStream");
					_recordMedia.addEventListener(MediaStatusEvent.STREAM_SUCCESS, onStreamSuccess, false, 0, true);
					_recordMedia.addEventListener(MediaStatusEvent.STREAM_FAILURE, onStreamFailure, false, 0, true);
					_recordMedia.setup(_recordMediaNetConnectionUrl, _recordMediaUrl);
				}
				else
				{
					//To record media a netconnectionurl is a must, if not provided
					logger.debug("NetConnectionUrl for record media not provided. Can't record.");
						//onStreamFailure();
				}
			}
		}

		private function prepareTimeMarkers(timemarkers:Object):void
		{
			if (_markermgr)
			{
				removeEventListener(PollingEvent.ENTER_FRAME, _markermgr.onIntervalTimer);
			}
			//Set the timeline event markers
			if (timemarkers)
			{
				_timeMarkers=timemarkers;
				var parsedTimeMarkers:Array=TimeMetadataParser.parseRoleMarkers(timemarkers, this);
				if (parsedTimeMarkers)
				{
					//Add a listener to poll for event points
					setTimeMarkers(parsedTimeMarkers);
					addEventListener(PollingEvent.ENTER_FRAME, _markermgr.onIntervalTimer, false, 0, true);
					//Enable the timeline timer
					pollTimeline=true;
				}
				else
				{
					logger.debug("No valid time markers found in given data");
				}
			}
			else
			{
				_timeMarkers=null;
				logger.debug("Time marker data is null");
			}
		}

		public function recordVideo(media:Object, useWebcam:Boolean, timemarkers:Object):void
		{
			_recordUseWebcam=useWebcam;

			//Override autoPlay to avoid loading until the rest is done.
			_autoPlayOverride=true;
			_videoPlaying=false;

			if (media)
			{
				//Load the exercise to play alongside the recording, if any
				loadVideoByUrl(media, timemarkers);
				//Remove the exercise poster, we don't need it when about to record something
				_topLayer.removeChildren();
			}
		}

		override protected function onStreamSuccess(event:Event):void
		{
			var mobj:Object=event.currentTarget;

			//Deep equality of Object checks if both objects have the same memref
			if (mobj === _media)
			{
				_mediaReady=true;
			}
			if (mobj === _parallelMedia)
			{
				_parallelMediaReady=true;
			}
			if (mobj === _recordMedia)
			{
				_recordMediaReady=true;
			}

			//State belongs to the recording state group
			if (_state & RECORD_MODE_MASK)
			{
				if (_mediaReady && _recordMediaReady)
				{
					_video.attachNetStream(_media.netStream);
					_media.volume=_currentVolume;
					_media.addEventListener(MediaStatusEvent.METADATA_RETRIEVED, onMetaData, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STATE_CHANGED, onStreamStateChange, false, 0, true);

					_recordMedia.volume=_currentVolume;
					_recordMedia.addEventListener(MediaStatusEvent.STATE_CHANGED, onStreamStateChange, false, 0, true);

					prepareDevices();
				}
			}
			else if (_state != PLAY_STATE)
			{
				if (_parallelMediaReady && _mediaReady)
				{
					if(_topLayer.contains(_errorSprite)){
						_topLayer.removeChild(_errorSprite);
					}
					//Start with the same volume for both streams
					_parallelCurrentVolume=_currentVolume;
					
					_video.attachNetStream(_media.netStream);
					_video.visible=true;
					_media.volume=_currentVolume;
					_media.addEventListener(MediaStatusEvent.METADATA_RETRIEVED, onMetaData, false, 0, true);
					_media.addEventListener(MediaStatusEvent.STATE_CHANGED, onStreamStateChange, false, 0, true);

					_camVideo.attachNetStream(_parallelMedia.netStream);
					_camVideo.visible=true;
					_micImage.visible=true;
					_parallelMedia.volume=_parallelCurrentVolume;

					if (_timeMarkers)
					{
						//If the parallel play has timemarkers start with a muted right stream
						muteParallel();
					}

					_parallelMedia.addEventListener(MediaStatusEvent.METADATA_RETRIEVED, onMetaData, false, 0, true);
					_parallelMedia.addEventListener(MediaStatusEvent.STATE_CHANGED, onStreamStateChange, false, 0, true);
					if (autoPlay || _forcePlay)
					{
						startVideo();
						_forcePlay=false;
					}
				}
			}
			else
			{
				super.onStreamSuccess(event);
			}
		}

		override protected function startVideo():void
		{
			if (_state == PLAY_STATE || _state & RECORD_MODE_MASK)
			{
				super.startVideo();
			}
			else
			{
				if (!(_state & RECORD_MODE_MASK))
				{
					if (!_parallelMediaReady)
						return;
					try
					{
						_parallelMedia.play();
						super.startVideo();
					}
					catch (e:Error)
					{
						_parallelMediaReady=false;
							//logger.error("Error while loading video. [{0}] {1}", [e.errorID, e.message]);
					}
				}
			}
		}

		override public function onMetaData(event:MediaStatusEvent):void
		{
			var mobj:Object=event.currentTarget;
			
			super.onMetaData(event);

			if(mobj === _parallelMedia){
				var pv:Boolean=_parallelMedia.hasVideo;
				_camVideo.visible=pv;
				_micImage.visible=!pv;
			}
			
			//The duration of the media is required to set the arrows and the scrubber marks
			if (_timeMarkers)
			{
				setArrows(_timeMarkers);
				displayEventArrows=true;
			}
		}

		override protected function onStreamStateChange(event:MediaStatusEvent):void
		{
			var mobj:Object=event.currentTarget;

			//Deep equality of Object checks if both objects have the same memref
			if (mobj === _media)
			{
				if (event.state == AMediaManager.STREAM_SEEKING_START || event.state == AMediaManager.STREAM_READY)
				{
					if (_captionmgr)
						_captionmgr.reset();
					if (_markermgr)
						_markermgr.reset();
				}
				if (event.state == AMediaManager.STREAM_FINISHED)
				{
					if (_captionmgr){
						_captionmgr.reset();
					}
					if (_markermgr){
						_markermgr.reset();
					}
					_camVideo.clear();
					hideCaption();
					
					//Unlock mute overrides just in case
					_muteOverride=false;
					_parallelMuteOverride=false;
					
					if (_state & RECORD_MODE_MASK || _state == UPLOAD_MODE_STATE)
					{
						//Stop the media, remove the listeners, close the NetConnection and set to null
						freeMedia(_recordMedia);
						_autoPlayOverride=false;
						logger.info("Stream recording finished: {0}", [_recordMediaUrl]);

						dispatchEvent(new RecordingEvent(RecordingEvent.END, _recordMediaUrl));
						enableControls();
					}
					else
						dispatchEvent(new RecordingEvent(RecordingEvent.REPLAY_END));
				}
				super.onStreamStateChange(event);
			}
		}

		override public function resetComponent():void
		{
			_autoPlayOverride=true;
			setInternalState(PLAY_STATE);
			super.resetComponent();
			_autoPlayOverride=false;
			_topLayer.removeChildren();
			if (_captionmgr)
			{
				_captionmgr.removeEventListener(PollingEvent.ENTER_FRAME, onTimerTick);
				_captionmgr.removeAllMarkers();
				_captionmgr=null;
			}
			if (_markermgr)
			{
				_markermgr.removeEventListener(PollingEvent.ENTER_FRAME, onTimerTick);
				_markermgr.removeAllMarkers();
				_markermgr=null;
			}
		}

		override protected function resetAppearance():void
		{
			super.resetAppearance();
			resetVideo(_camVideo);
			resetVideoDisplay();
			_micImage.visible=false;
			_micActivityBar.visible=false;
			hideCaption();
			removeArrows();
			displayEventArrows=false;
		}

		override protected function freeMediaResources():void
		{
			super.freeMediaResources();
			freeMedia(_recordMedia);
			freeMedia(_parallelMedia);
		}
	}
}
