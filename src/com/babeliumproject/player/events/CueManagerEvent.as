package com.babeliumproject.player.events
{
	
	import flash.events.Event;
	
	public class CueManagerEvent extends Event
	{
		
		public static const SUBTITLES_RETRIEVED:String = "subtitlesRetrieved";
		
		public function CueManagerEvent(type:String)
		{
			super(type);
		}
		
		override public function clone():Event{
			return new CueManagerEvent(type);
		}
		
	}
}