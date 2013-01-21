/**
 * @depends jquery
 * @name jquery.scrollto
 * @package jquery-scrollto {@link http://balupton.com/projects/jquery-scrollto}
 */

/**
 * jQuery Aliaser
 */
(function(window,undefined){
	// Prepare
	var jQuery, $, ScrollTo;
	jQuery = $ = window.jQuery;

	/**
	 * jQuery ScrollTo (balupton edition)
	 * @version 1.2.0
	 * @date July 9, 2012
	 * @since 0.1.0, August 27, 2010
	 * @package jquery-scrollto {@link http://balupton.com/projects/jquery-scrollto}
	 * @author Benjamin "balupton" Lupton {@link http://balupton.com}
	 * @copyright (c) 2010 Benjamin Arthur Lupton {@link http://balupton.com}
	 * @license MIT License {@link http://creativecommons.org/licenses/MIT/}
	 */
	ScrollTo = $.ScrollTo = $.ScrollTo || {
		/**
		 * The Default Configuration
		 */
		config: {
			duration: 400,
			easing: 'swing',
			callback: undefined,
			durationMode: 'each',
			offsetTop: 0,
			offsetLeft: 0
		},

		/**
		 * Configure ScrollTo
		 */
		configure: function(options){
			// Apply Options to Config
			$.extend(ScrollTo.config, options||{});

			// Chain
			return this;
		},

		/**
		 * Perform the Scroll Animation for the Collections
		 * We use $inline here, so we can determine the actual offset start for each overflow:scroll item
		 * Each collection is for each overflow:scroll item
		 */
		scroll: function(collections, config){
			// Prepare
			var collection, $container, container, $target, $inline, position,
				containerScrollTop, containerScrollLeft,
				containerScrollTopEnd, containerScrollLeftEnd,
				startOffsetTop, targetOffsetTop, targetOffsetTopAdjusted,
				startOffsetLeft, targetOffsetLeft, targetOffsetLeftAdjusted,
				scrollOptions,
				callback;

			// Determine the Scroll
			collection = collections.pop();
			$container = collection.$container;
			container = $container.get(0);
			$target = collection.$target;

			// Prepare the Inline Element of the Container
			$inline = $('<span/>').css({
				'position': 'absolute',
				'top': '0px',
				'left': '0px'
			});
			position = $container.css('position');

			// Insert the Inline Element of the Container
			$container.css('position','relative');
			$inline.appendTo($container);

			// Determine the top offset
			startOffsetTop = $inline.offset().top;
			targetOffsetTop = $target.offset().top;
			targetOffsetTopAdjusted = targetOffsetTop - startOffsetTop - parseInt(config.offsetTop,10);

			// Determine the left offset
			startOffsetLeft = $inline.offset().left;
			targetOffsetLeft = $target.offset().left;
			targetOffsetLeftAdjusted = targetOffsetLeft - startOffsetLeft - parseInt(config.offsetLeft,10);

			// Determine current scroll positions
			containerScrollTop = container.scrollTop;
			containerScrollLeft = container.scrollLeft;

			// Reset the Inline Element of the Container
			$inline.remove();
			$container.css('position',position);

			// Prepare the scroll options
			scrollOptions = {};

			// Prepare the callback
			callback = function(event){
				// Check
				if ( collections.length === 0 ) {
					// Callback
					if ( typeof config.callback === 'function' ) {
						config.callback.apply(this,[event]);
					}
				}
				else {
					// Recurse
					ScrollTo.scroll(collections,config);
				}
				// Return true
				return true;
			};

			// Handle if we only want to scroll if we are outside the viewport
			if ( config.onlyIfOutside ) {
				// Determine current scroll positions
				containerScrollTopEnd = containerScrollTop + $container.height();
				containerScrollLeftEnd = containerScrollLeft + $container.width();

				// Check if we are in the range of the visible area of the container
				if ( containerScrollTop < targetOffsetTopAdjusted && targetOffsetTopAdjusted < containerScrollTopEnd ) {
					targetOffsetTopAdjusted = containerScrollTop;
				}
				if ( containerScrollLeft < targetOffsetLeftAdjusted && targetOffsetLeftAdjusted < containerScrollLeftEnd ) {
					targetOffsetLeftAdjusted = containerScrollLeft;
				}
			}

			// Determine the scroll options
			if ( targetOffsetTopAdjusted !== containerScrollTop ) {
				scrollOptions.scrollTop = targetOffsetTopAdjusted;
			}
			if ( targetOffsetLeftAdjusted !== containerScrollLeft ) {
				scrollOptions.scrollLeft = targetOffsetLeftAdjusted;
			}

			// Perform the scroll
			if ( $.browser.safari && container === document.body ) {
				window.scrollTo(scrollOptions.scrollLeft, scrollOptions.scrollTop);
				callback();
			}
			else if ( scrollOptions.scrollTop || scrollOptions.scrollLeft ) {
				$container.animate(scrollOptions, config.duration, config.easing, callback);
			}
			else {
				callback();
			}

			// Return true
			return true;
		},

		/**
		 * ScrollTo the Element using the Options
		 */
		fn: function(options){
			// Prepare
			var collections, config, $container, container;
			collections = [];

			// Prepare
			var	$target = $(this);
			if ( $target.length === 0 ) {
				// Chain
				return this;
			}

			// Handle Options
			config = $.extend({},ScrollTo.config,options);

			// Fetch
			$container = $target.parent();
			container = $container.get(0);

			// Cycle through the containers
			while ( ($container.length === 1) && (container !== document.body) && (container !== document) ) {
				// Check Container for scroll differences
				var scrollTop, scrollLeft;
				scrollTop = $container.css('overflow-y') !== 'visible' && container.scrollHeight !== container.clientHeight;
				scrollLeft =  $container.css('overflow-x') !== 'visible' && container.scrollWidth !== container.clientWidth;
				if ( scrollTop || scrollLeft ) {
					// Push the Collection
					collections.push({
						'$container': $container,
						'$target': $target
					});
					// Update the Target
					$target = $container;
				}
				// Update the Container
				$container = $container.parent();
				container = $container.get(0);
			}

			// Add the final collection
			collections.push({
				'$container': $(
					($.browser.msie || $.browser.mozilla) ? 'html' : 'body'
				),
				'$target': $target
			});

			// Adjust the Config
			if ( config.durationMode === 'all' ) {
				config.duration /= collections.length;
			}

			// Handle
			ScrollTo.scroll(collections,config);

			// Chain
			return this;
		}
	};

	// Apply our jQuery Prototype Function
	$.fn.ScrollTo = $.ScrollTo.fn;

})(window);
