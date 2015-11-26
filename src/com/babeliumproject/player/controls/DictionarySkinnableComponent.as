package com.babeliumproject.player.controls
{
	import com.babeliumproject.utils.IDisposableObject;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;
	import mx.utils.ObjectUtil;

	/**
     *  The DictionarySkinnableComponent class is the base class for all dictionary-based
	 *  skinnable components. Subclasses must override the methods to add their own skin
	 *  properties to the dictionary.
	 *
	 */
	public class DictionarySkinnableComponent extends UIComponent implements IDisposableObject
	{
		public static const BACKGROUND_COLOR:String='backgroundColor';
		public static const BORDER_COLOR:String='borderColor';
		public static const BORDER_WIDTH:String='borderWidth';
		
		public static const BORDER_RIGHT_COLOR:String='borderRightColor';
		public static const BORDER_RIGHT_WIDTH:String='borderRightWidth';
		public static const BORDER_LEFT_COLOR:String='borderLeftColor';
		public static const BORDER_LEFT_WIDTH:String='borderLeftWidth';
		
		
		protected var _bg:Sprite;
		
		private var _skinProperties:Object;
		public var COMPONENT_NAME:String;

		public function DictionarySkinnableComponent(name:String="DictionarySkinnableComponent")
		{
			super();
			COMPONENT_NAME=name;
			_skinProperties=new Object();
			
			_bg=new Sprite();
			addChild(_bg);
		}

		/**
		 * Disposes any object that could remain pinned to the memory and therefore not get
		 * marked to be collected when the garbage collector is called.
		 *
		 * Override this method in subclasses to remove any possible memory pinnings,
		 * such as: event listeners, binded setters, binded properties or dictionaries.
		 */
		public function dispose():void
		{
			_skinProperties=null;
		}

		/**
		 * Removes the specified child DisplayObject instance from the child list of the DisplayObjectContainer instance.
		 * If the child parameter is not a child of this object nothing is removed and the error is suppressed.
		 *
		 * @param child
		 */
		protected function removeChildSuppressed(child:DisplayObject):void
		{
			try
			{
				if (child)
				{
					this.removeChild(child);
				}
			}
			catch (error:ArgumentError)
			{
				//Suppress error
			}
		}
		
		protected function drawBackground(element:Sprite,state:String=''):void{
			
			var color:uint=0x000000;
			var alpha:Number=0.0;
			
			if(!element) return;
			
			element.graphics.clear();
			
			var pColor:*=getSkinProperty(BACKGROUND_COLOR+state);
			
			if(pColor is Array){
				var colors:Array=pColor as Array;
				var alphas:Array=[];
				var ratios:Array=[];
				var angle:int=90;
				var numColors:int = colors.length;
				for (var i:int=0; i<numColors; i++){
					colors[i]=new uint(colors[i]);
					alphas.push(1.0);
					ratios.push(Math.floor((255/(numColors-1))*i));
				}
				var type:String=GradientType.LINEAR;
				var matrix:Matrix=new Matrix();
				matrix.createGradientBox(width, height, deg2rad(angle), 0, 0);
				element.graphics.beginGradientFill(type, colors, alphas, ratios, matrix);
				
			} else if (pColor is int) {
				color= new uint(pColor);
				alpha=1.0;
				element.graphics.beginFill(color,alpha);
			} else {
				element.graphics.beginFill(color,alpha);
			}
			
			var borderWidth:int=getSkinColor(BORDER_WIDTH+state) ? getSkinColor(BORDER_WIDTH+state) : 0;
			var availableWidth:int=width - borderWidth;
			var availableHeight:int=height - borderWidth;
			if(borderWidth > 0){
				element.graphics.lineStyle(borderWidth, getSkinColor(BORDER_COLOR+state));
			}
				
			element.graphics.drawRect(0, 0, availableWidth, availableHeight);
			element.graphics.endFill();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			drawBackground(_bg);
		}
		
		protected function deg2rad(degrees:Number):Number{
			return degrees * Math.PI / 180;
		}

		/**
		 * Prints the available style properties to the debugging log 
		 * @param obj
		 * 
		 */		
		public function availableProperties(obj:Array=null):void
		{
			trace(ObjectUtil.toString(obj));
		}

		/**
		 * Sets color for a skinProperty
		 */
		public function setSkinProperty(name:String, value:*):void
		{
			_skinProperties[name]=value;
		}

		/**
		 * Gets color from a skinProperty
		 */
		public function getSkinColor(propertyName:String):uint
		{
			if (!_skinProperties)
				return 0;

			if (!_skinProperties.hasOwnProperty(propertyName))
				return 0;

			return new uint(_skinProperties[propertyName]);
		}

		/**
		 * Returns the value of a property of this skin
		 */
		public function getSkinProperty(name:String):*
		{
			if (!_skinProperties)
				return null;

			if (!_skinProperties.hasOwnProperty(name))
				return null;

			return _skinProperties[name];
		}

		public function refresh():void
		{
			invalidateDisplayList();
		}

	}
}
