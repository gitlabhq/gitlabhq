/**
 * Endless Scroll plugin for jQuery
 *
 * v1.4.8
 *
 * Copyright (c) 2008 Fred Wu
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 */

/**
 * Usage:
 *
 * // using default options
 * $(document).endlessScroll();
 *
 * // using some custom options
 * $(document).endlessScroll({
 *   fireOnce: false,
 *   loader: "<div class=\"loading\"><div>",
 *   callback: function(){
 *     alert("test");
 *   }
 * });
 *
 * Configuration options:
 *
 * bottomPixels  integer          the number of pixels from the bottom of the page that triggers the event
 * fireOnce      boolean          only fire once until the execution of the current event is completed
 * loader        string           the HTML to be displayed during loading
 * data          string|function  plain HTML data, can be either a string or a function that returns a string,
 *                                when passed as a function it accepts one argument: fire sequence (the number
 *                                of times the event triggered during the current page session)
 * insertAfter   string           jQuery selector syntax: where to put the loader as well as the plain HTML data
 * callback      function         callback function, accepts one argument: fire sequence (the number of times
 *                                the event triggered during the current page session)
 * resetCounter  function         resets the fire sequence counter if the function returns true, this function
 *                                could also perform hook actions since it is applied at the start of the event
 * ceaseFire     function         stops the event (no more endless scrolling) if the function returns true
 *
 * Usage tips:
 *
 * The plugin is more useful when used with the callback function, which can then make AJAX calls to retrieve content.
 * The fire sequence argument (for the callback function) is useful for 'pagination'-like features.
 */

export const setupEndlessScroll = ($) => {

  $.fn.endlessScroll = function(options) {

    var defaults = {
      bottomPixels  : 50,
      fireOnce      : true,
      loader        : "<br />Loading…<br />",
      data          : "",
      insertAfter   : "div:last",
      resetCounter  : function() { return false; },
      callback      : function() { return true; },
      ceaseFire     : function() { return false; }
    };

    var options       = $.extend({}, defaults, options),
        data          = false,
        firing        = true,
        fired         = false,
        fireSequence  = 0,
        is_scrollable;

    if (options.ceaseFire.apply(this) === true)
      firing = false;

    if (firing === true) {
      $(this).scroll(function() {
        if (options.ceaseFire.apply(this) === true) {
          firing = false;
          return; // Scroll will still get called, but nothing will happen
        }

        if (this == document || this == window) {
          is_scrollable = $(document).height() - $(window).height() <= $(window).scrollTop() + options.bottomPixels;
        } else {
          // calculates the actual height of the scrolling container
          var inner_wrap = $(".endless_scroll_inner_wrap", this);
          if (inner_wrap.length == 0)
            inner_wrap = $(this).wrapInner("<div class=\"endless_scroll_inner_wrap\" />").find(".endless_scroll_inner_wrap");
          is_scrollable = inner_wrap.length > 0 &&
            (inner_wrap.height() - $(this).height() <= $(this).scrollTop() + options.bottomPixels);
        }

        if (is_scrollable && (options.fireOnce == false || (options.fireOnce == true && fired != true))) {
          if (options.resetCounter.apply(this) === true) fireSequence = 0;

          fired = true;
          fireSequence++;

          $(options.insertAfter).after("<div id=\"endless_scroll_loader\">" + options.loader + "</div>");

          data = typeof options.data == 'function' ? options.data.apply(this, [fireSequence]) : options.data;

          if (data !== false) {
            $(options.insertAfter).after("<div>" + data + "</div>");

            options.callback.apply(this, [fireSequence]);

            fired = false;
          }

          $("#endless_scroll_loader").remove();
        }
      });
    }
  };
};
