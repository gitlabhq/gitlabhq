/**
 * jQuery Plugin: Sticky Tabs
 *
 * @author Aidan Lister <aidan@php.net>
 * @version 1.2.0
 */
(function ( $ ) {
    $.fn.stickyTabs = function( options ) {
        var context = this

        var settings = $.extend({
            getHashCallback: function(hash, btn) { return hash },
            selectorAttribute: "href",
            backToTop: false,
            initialTab: $('li.active > a', context)
        }, options );

        // Show the tab corresponding with the hash in the URL, or the first tab.
        var showTabFromHash = function() {
          var hash = settings.selectorAttribute == "href" ? window.location.hash : window.location.hash.substring(1);
          var selector = hash ? 'a[' + settings.selectorAttribute +'="' + hash + '"]' : settings.initialTab;
          $(selector, context).tab('show');
          setTimeout(backToTop, 1);
        }

        // We use pushState if it's available so the page won't jump, otherwise a shim.
        var changeHash = function(hash) {
          if (history && history.pushState) {
            history.pushState(null, null, window.location.pathname + window.location.search + '#' + hash);
          } else {
            scrollV = document.body.scrollTop;
            scrollH = document.body.scrollLeft;
            window.location.hash = hash;
            document.body.scrollTop = scrollV;
            document.body.scrollLeft = scrollH;
          }
        }

        var backToTop = function() {
          if (settings.backToTop === true) {
            window.scrollTo(0, 0);
          }
        }

        // Set the correct tab when the page loads
        showTabFromHash();

        // Set the correct tab when a user uses their back/forward button
        $(window).on('hashchange', showTabFromHash);

        // Change the URL when tabs are clicked
        $('a', context).on('click', function(e) {
          var hash = this.href.split('#')[1];
          var adjustedhash = settings.getHashCallback(hash, this);
          changeHash(adjustedhash);
          setTimeout(backToTop, 1);
        });

        return this;
    };
}( jQuery ));
