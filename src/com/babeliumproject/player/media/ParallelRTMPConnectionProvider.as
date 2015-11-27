/*    
 * Copyright 2008 Anssi Piirainen, FlowPlayer
 * Modified for Babelium by Babelium Team
 */

package com.babeliumproject.player.media
{
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.utils.Timer;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;


	public class ParallelRTMPConnectionProvider {
		
		protected static const log:ILogger=getLogger(ParallelRTMPConnectionProvider);
		
		
		protected var _successListener:Function;
		protected var _failureListener:Function;
		protected var _rtmpConnector:ParallelRTMPConnector;
		protected var _rtmptConnector:ParallelRTMPConnector;
		private var _succeededConnector:ParallelRTMPConnector;
		
		protected var _connection:NetConnection;
		protected var _netConnectionUrl:String;
		protected var _proxyType:String;
		protected var _failOverDelay:int;
		
		protected var _bwInfo:Object;
		protected var _id:String;
		
		public function ParallelRTMPConnectionProvider(netConnectionUrl:String, proxyType:String = "best", failOverDelay:int = 250) {
			_netConnectionUrl = netConnectionUrl;
			_proxyType = proxyType;
			_failOverDelay = failOverDelay;
			log.debug("ParallelRTMPConnectionProvider created");
		}
		
		public function connect(url:String, successListener:Function, objectEncoding:uint, connectionArgs:Array):void {
			
			_successListener = successListener;
			
			var configuredUrl:String = getNetConnectionUrl();
			if (! configuredUrl && _failureListener != null) {
				_failureListener("netConnectionURL is not defined");
			}
			var parts:Array = getUrlParts(configuredUrl);
			var connArgs:Array = connectionArgs;
			
			if (hasConnectionToSameServerWithSameArgs(parts[1], connArgs)) {
				log.debug("already connected to server " + parts[1] + ", with same connection arguments -> calling success listener");
				if (successListener != null) {
					successListener(_connection);
				}
				return;
			}
			
			successListener = null;
			if (_connection) {
				log.debug("doConnect(): closing previous connection");
				_connection.close();
				_connection = null;
			}
			
			if (parts && (parts[0] == 'rtmp' || parts[0] == 'rtmpe')) {
				
				log.debug("will connect using RTMP and RTMPT in parallel");
				_rtmpConnector = createConnector((parts[0] == 'rtmp' ? 'rtmp' : 'rtmpe') + '://' + parts[1]);
				_rtmptConnector = createConnector((parts[0] == 'rtmp' ? 'rtmpt' : 'rtmpte') + '://' + parts[1]);
				
				doConnect(_rtmpConnector, _proxyType, objectEncoding, connArgs);
				
				// RTMPT connect is started after 250 ms
				//#163 weak reference
				var delay:Timer = new Timer(_failOverDelay, 1);
				delay.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void {
					doConnect(_rtmptConnector, _proxyType, objectEncoding, connArgs);
				}, false, 0 , true);
				delay.start();
				
			} else {
				log.debug("connecting to URL " + configuredUrl);
				_rtmpConnector = createConnector(configuredUrl);
				doConnect(_rtmpConnector, _proxyType, objectEncoding, connArgs);
			}
		}
		
		private function hasConnectionToSameServerWithSameArgs(host:String, args:Array):Boolean {
			log.debug("hasConnectionToSameServerWithSameArgs ? previous URI == " + (_connection && _connection.uri));
			if (! _succeededConnector) return false;
			if (! _connection) return false;
			if (! _connection.connected) return false;
			
			var parts:Array = getUrlParts(_connection.uri);
			log.debug("hasConnectionToSameServerWithSameArgs ? previous host == " + parts[1] + " current host == " + host);
			
			if (host != parts[1]) return false;
			
			log.debug("hasConnectionToSameServerWithSameArgs(), old connection args:", _succeededConnector.connectionArgs);
			log.debug("hasConnectionToSameServerWithSameArgs(), new connection args:", args);
			
			if (hasElements(args) && ! hasElements(_succeededConnector.connectionArgs)
				|| ! hasElements(args) && hasElements(_succeededConnector.connectionArgs)) {
				log.debug("connection args arrays are different (empty and non-empty)");
				return false;
			}
			if (args && _succeededConnector.connectionArgs && ! arraysAreEqual(_succeededConnector.connectionArgs, args)) {
				log.debug("connection args arrays are nonequal");
				return false;
			}
			
			return true;
		}
		
		private function hasElements(args:Array):Boolean {
			return args && args.length > 0;
		}
		
		private function arraysAreEqual(arr1:Array, arr2:Array):Boolean{
			if(arr1.length != arr2.length)
			{
				return false;
			}
			var len:Number = arr1.length;
			for(var i:Number = 0; i < len; i++)
			{
				if(arr1[i] !== arr2[i])
				{
					return false;
				}
			}
			return true;
		}
		
		protected function createConnector(url:String):ParallelRTMPConnector {
			return new ParallelRTMPConnector(url, onConnectorSuccess, onConnectorFailure);
		}
		
		private function doConnect(connector:ParallelRTMPConnector, proxyType:String, objectEncoding:uint, connectionArgs:Array):void {
			if (connectionArgs.length > 0) {
				connector.connect(_proxyType, objectEncoding, connectionArgs);
			} else {
				connector.connect(_proxyType, objectEncoding, null);
			}
		}
		
		protected function onConnectorSuccess(connector:ParallelRTMPConnector, connection:NetConnection):void {
			log.debug(connector + " established a connection");
			if (_connection) return;
			
			_connection = connection;
			_succeededConnector = connector;
			
			if (connector == _rtmptConnector && _rtmpConnector) {
				_rtmpConnector.stop();
			} else if (_rtmptConnector) {
				_rtmptConnector.stop();
			}
			_successListener(connection);
		}
		
		//#391 add message argument required by some connection providers
		protected function onConnectorFailure(message:String = null):void {
			if (isFailedOrNotUsed(_rtmpConnector) && isFailedOrNotUsed(_rtmptConnector) && _failureListener != null) {
				_failureListener(message);
			}
		}
		
		private function isFailedOrNotUsed(connector:ParallelRTMPConnector):Boolean {
			if (! connector) return true;
			return connector.failed;
		}
		
		private function getUrlParts(url:String):Array {
			var pos:int = url.indexOf('://');
			if (pos > 0) {
				return [url.substring(0, pos), url.substring(pos + 3)];
			}
			return null;
		}
		
		protected function getNetConnectionUrl():String {
			log.debug("using netConnectionUrl from config" + _netConnectionUrl);
			return _netConnectionUrl;
		}
		
		protected function isRtmpUrl(url:String):Boolean {
			return url && url.toLowerCase().indexOf("rtmp") == 0;
		}
		
		public function set onFailure(listener:Function):void {
			_failureListener = listener;
		}
		
		public function handeNetStatusEvent(event:NetStatusEvent):Boolean {
			return true;
		}
		
		public function get connection():NetConnection {
			return _connection;
		}
	}
}