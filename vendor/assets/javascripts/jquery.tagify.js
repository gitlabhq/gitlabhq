/* Author: Alicia Liu */

(function ($) {

	$.widget("ui.tagify", {
		options: {
			delimiters: [13, 188],          // what user can type to complete a tag in char codes: [enter], [comma]
			outputDelimiter: ',',           // delimiter for tags in original input field
			cssClass: 'tagify-container',   // CSS class to style the tagify div and tags, see stylesheet
			addTagPrompt: 'add tags'        // placeholder text
		},

		_create: function() {
			var self = this,
				el = self.element,
				opts = self.options;

			this.tags = [];

			// hide text field and replace with a div that contains it's own input field for entering tags
			this.tagInput = $("<input type='text'>")
				.attr( 'placeholder', opts.addTagPrompt )
				.keypress( function(e) {
					var $this = $(this),
					    pressed = e.which;

					for ( i in opts.delimiters ) {

						if (pressed == opts.delimiters[i]) {
							self.add( $this.val() );
							e.preventDefault(); 
							return false;
						}
					}
				})
				// for some reason, in Safari, backspace is only recognized on keyup
				.keyup( function(e) {
					var $this = $(this),
					    pressed = e.which;

					// if backspace is hit with no input, remove the last tag
					if (pressed == 8) { // backspace
						if ( $this.val() == "" ) {
							self.remove();
							return false;
						}
						return;
					}
				});

			this.tagDiv = $("<div></div>")
			    .addClass( opts.cssClass )
			    .click( function() {
			        $(this).children('input').focus();
			    })
			    .append( this.tagInput )
				.insertAfter( el.hide() );

			// if the field isn't empty, parse the field for tags, and prepopulate existing tags
			var initVal = $.trim( el.val() );

			if ( initVal ) {
				var initTags = initVal.split( opts.outputDelimiter );
				$.each( initTags, function(i, tag) {
				    self.add( tag );
				});
			}
		},

		_setOption: function( key, value ) {
			options.key = value;
		},

		// add a tag, public function		
		add: function(text) {
    		var self = this;
			text = text || self.tagInput.val();
			if (text) {
				var tagIndex = self.tags.length;

				var removeButton = $("<a href='#'>x</a>")
					.click( function() {
						self.remove( tagIndex );
						return false;
					});
				var newTag = $("<span></span>")
					.text( text )
					.append( removeButton );

				self.tagInput.before( newTag );
				self.tags.push( text );
				self.tagInput.val('');
			}
		},

		// remove a tag by index, public function
		// if index is blank, remove the last tag
		remove: function( tagIndex ) {
			var self = this;
			if ( tagIndex == null  || tagIndex === (self.tags.length - 1) ) {
				this.tagDiv.children("span").last().remove();
				self.tags.pop();
			}
			if ( typeof(tagIndex) == 'number' ) {
				// otherwise just hide this tag, and we don't mess up the index
				this.tagDiv.children( "span:eq(" + tagIndex + ")" ).hide();
				 // we rely on the serialize function to remove null values
				delete( self.tags[tagIndex] );
			}
		},

		// serialize the tags with the given delimiter, and write it back into the tagified field
		serialize: function() {
			var self = this;
			var delim = self.options.outputDelimiter;
			var tagsStr = self.tags.join( delim );

			// our tags might have deleted entries, remove them here
			var dupes = new RegExp(delim + delim + '+', 'g'); // regex: /,,+/g
			var ends = new RegExp('^' + delim + '|' + delim + '$', 'g');  // regex: /^,|,$/g
			var outputStr = tagsStr.replace( dupes, delim ).replace(ends, '');

			self.element.val(outputStr);
			return outputStr;
		},

		inputField: function() {
		    return this.tagInput;
		},

		containerDiv: function() {
		    return this.tagDiv;
		},

		// remove the div, and show original input
		destroy: function() {
		    $.Widget.prototype.destroy.apply(this);
			this.tagDiv.remove();
			this.element.show();
		}
	});

})(jQuery);