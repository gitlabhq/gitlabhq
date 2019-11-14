/* eslint-disable no-return-assign */

import $ from 'jquery';
import syntaxHighlight from '~/syntax_highlight';

describe('Syntax Highlighter', function() {
  const stubUserColorScheme = function(value) {
    if (window.gon == null) {
      window.gon = {};
    }
    return (window.gon.user_color_scheme = value);
  };
  describe('on a js-syntax-highlight element', function() {
    beforeEach(function() {
      return setFixtures('<div class="js-syntax-highlight"></div>');
    });

    it('applies syntax highlighting', function() {
      stubUserColorScheme('monokai');
      syntaxHighlight($('.js-syntax-highlight'));

      expect($('.js-syntax-highlight')).toHaveClass('monokai');
    });
  });

  describe('on a parent element', function() {
    beforeEach(function() {
      return setFixtures(
        '<div class="parent">\n  <div class="js-syntax-highlight"></div>\n  <div class="foo"></div>\n  <div class="js-syntax-highlight"></div>\n</div>',
      );
    });

    it('applies highlighting to all applicable children', function() {
      stubUserColorScheme('monokai');
      syntaxHighlight($('.parent'));

      expect($('.parent, .foo')).not.toHaveClass('monokai');
      expect($('.monokai').length).toBe(2);
    });

    it('prevents an infinite loop when no matches exist', function() {
      setFixtures('<div></div>');
      const highlight = function() {
        return syntaxHighlight($('div'));
      };

      expect(highlight).not.toThrow();
    });
  });
});
