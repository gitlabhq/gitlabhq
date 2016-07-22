
/*= require awards_handler */

/*= require jquery */

/*= require jquery.cookie */

/*= require ./fixtures/emoji_menu */
var awardsHandler, lazyAssert;

awardsHandler = null;

window.gl || (window.gl = {});

window.gon || (window.gon = {});

gl.emojiAliases = function() {
  return {
    '+1': 'thumbsup',
    '-1': 'thumbsdown'
  };
};

gon.award_menu_url = '/emojis';

lazyAssert = function(done, assertFn) {
  return setTimeout(function() {
    assertFn();
    return done();
  }, 333);
};

describe('AwardsHandler', function() {
  fixture.preload('awards_handler.html');
  beforeEach(function() {
    fixture.load('awards_handler.html');
    awardsHandler = new AwardsHandler;
    spyOn(awardsHandler, 'postEmoji').and.callFake((function(_this) {
      return function(url, emoji, cb) {
        return cb();
      };
    })(this));
    return spyOn(jQuery, 'get').and.callFake(function(req, cb) {
      return cb(window.emojiMenu);
    });
  });
  describe('::showEmojiMenu', function() {
    it('should show emoji menu when Add emoji button clicked', function(done) {
      $('.js-add-award').eq(0).click();
      return lazyAssert(done, function() {
        var $emojiMenu;
        $emojiMenu = $('.emoji-menu');
        expect($emojiMenu.length).toBe(1);
        expect($emojiMenu.hasClass('is-visible')).toBe(true);
        expect($emojiMenu.find('#emoji_search').length).toBe(1);
        return expect($('.js-awards-block.current').length).toBe(1);
      });
    });
    it('should also show emoji menu for the smiley icon in notes', function(done) {
      $('.note-action-button').click();
      return lazyAssert(done, function() {
        var $emojiMenu;
        $emojiMenu = $('.emoji-menu');
        return expect($emojiMenu.length).toBe(1);
      });
    });
    return it('should remove emoji menu when body is clicked', function(done) {
      $('.js-add-award').eq(0).click();
      return lazyAssert(done, function() {
        var $emojiMenu;
        $emojiMenu = $('.emoji-menu');
        $('body').click();
        expect($emojiMenu.length).toBe(1);
        expect($emojiMenu.hasClass('is-visible')).toBe(false);
        return expect($('.js-awards-block.current').length).toBe(0);
      });
    });
  });
  describe('::addAwardToEmojiBar', function() {
    it('should add emoji to votes block', function() {
      var $emojiButton, $votesBlock;
      $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      $emojiButton = $votesBlock.find('[data-emoji=heart]');
      expect($emojiButton.length).toBe(1);
      expect($emojiButton.next('.js-counter').text()).toBe('1');
      return expect($votesBlock.hasClass('hidden')).toBe(false);
    });
    it('should remove the emoji when we click again', function() {
      var $emojiButton, $votesBlock;
      $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      $emojiButton = $votesBlock.find('[data-emoji=heart]');
      return expect($emojiButton.length).toBe(0);
    });
    return it('should decrement the emoji counter', function() {
      var $emojiButton, $votesBlock;
      $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      $emojiButton = $votesBlock.find('[data-emoji=heart]');
      $emojiButton.next('.js-counter').text(5);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      expect($emojiButton.length).toBe(1);
      return expect($emojiButton.next('.js-counter').text()).toBe('4');
    });
  });
  describe('::getAwardUrl', function() {
    return it('should return the url for request', function() {
      return expect(awardsHandler.getAwardUrl()).toBe('/gitlab-org/gitlab-test/issues/8/toggle_award_emoji');
    });
  });
  describe('::addAward and ::checkMutuality', function() {
    return it('should handle :+1: and :-1: mutuality', function() {
      var $thumbsDownEmoji, $thumbsUpEmoji, $votesBlock, awardUrl;
      awardUrl = awardsHandler.getAwardUrl();
      $votesBlock = $('.js-awards-block').eq(0);
      $thumbsUpEmoji = $votesBlock.find('[data-emoji=thumbsup]').parent();
      $thumbsDownEmoji = $votesBlock.find('[data-emoji=thumbsdown]').parent();
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);
      expect($thumbsUpEmoji.hasClass('active')).toBe(true);
      expect($thumbsDownEmoji.hasClass('active')).toBe(false);
      $thumbsUpEmoji.tooltip();
      $thumbsDownEmoji.tooltip();
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsdown', true);
      expect($thumbsUpEmoji.hasClass('active')).toBe(false);
      return expect($thumbsDownEmoji.hasClass('active')).toBe(true);
    });
  });
  describe('::removeEmoji', function() {
    return it('should remove emoji', function() {
      var $votesBlock, awardUrl;
      awardUrl = awardsHandler.getAwardUrl();
      $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAward($votesBlock, awardUrl, 'fire', false);
      expect($votesBlock.find('[data-emoji=fire]').length).toBe(1);
      awardsHandler.removeEmoji($votesBlock.find('[data-emoji=fire]').closest('button'));
      return expect($votesBlock.find('[data-emoji=fire]').length).toBe(0);
    });
  });
  describe('search', function() {
    return it('should filter the emoji', function() {
      $('.js-add-award').eq(0).click();
      expect($('[data-emoji=angel]').is(':visible')).toBe(true);
      expect($('[data-emoji=anger]').is(':visible')).toBe(true);
      $('#emoji_search').val('ali').trigger('keyup');
      expect($('[data-emoji=angel]').is(':visible')).toBe(false);
      expect($('[data-emoji=anger]').is(':visible')).toBe(false);
      return expect($('[data-emoji=alien]').is(':visible')).toBe(true);
    });
  });
  return describe('emoji menu', function() {
    var openEmojiMenuAndAddEmoji, selector;
    selector = '[data-emoji=sunglasses]';
    openEmojiMenuAndAddEmoji = function() {
      var $block, $emoji, $menu;
      $('.js-add-award').eq(0).click();
      $menu = $('.emoji-menu');
      $block = $('.js-awards-block');
      $emoji = $menu.find(".emoji-menu-list-item " + selector);
      expect($emoji.length).toBe(1);
      expect($block.find(selector).length).toBe(0);
      $emoji.click();
      expect($menu.hasClass('.is-visible')).toBe(false);
      return expect($block.find(selector).length).toBe(1);
    };
    it('should add selected emoji to awards block', function() {
      return openEmojiMenuAndAddEmoji();
    });
    return it('should remove already selected emoji', function() {
      var $block, $emoji;
      openEmojiMenuAndAddEmoji();
      $('.js-add-award').eq(0).click();
      $block = $('.js-awards-block');
      $emoji = $('.emoji-menu').find(".emoji-menu-list-item " + selector);
      $emoji.click();
      return expect($block.find(selector).length).toBe(0);
    });
  });
});
