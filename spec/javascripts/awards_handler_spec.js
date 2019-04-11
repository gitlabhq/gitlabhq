import $ from 'jquery';
import Cookies from 'js-cookie';
import loadAwardsHandler from '~/awards_handler';
import '~/lib/utils/common_utils';

window.gl = window.gl || {};
window.gon = window.gon || {};

let openAndWaitForEmojiMenu;
let awardsHandler = null;
const urlRoot = gon.relative_url_root;

const lazyAssert = function(done, assertFn) {
  setTimeout(function() {
    assertFn();
    done();
    // Maybe jasmine.clock here?
  }, 333);
};

describe('AwardsHandler', function() {
  preloadFixtures('snippets/show.html');
  beforeEach(function(done) {
    loadFixtures('snippets/show.html');
    loadAwardsHandler(true)
      .then(obj => {
        awardsHandler = obj;
        spyOn(awardsHandler, 'postEmoji').and.callFake((button, url, emoji, cb) => cb());
        done();
      })
      .catch(fail);

    let isEmojiMenuBuilt = false;
    openAndWaitForEmojiMenu = function() {
      return new Promise(resolve => {
        if (isEmojiMenuBuilt) {
          resolve();
        } else {
          $('.js-add-award')
            .eq(0)
            .click();
          const $menu = $('.emoji-menu');
          $menu.one('build-emoji-menu-finish', () => {
            isEmojiMenuBuilt = true;
            resolve();
          });
        }
      });
    };
  });

  afterEach(function() {
    // restore original url root value
    gon.relative_url_root = urlRoot;

    // Undo what we did to the shared <body>
    $('body').removeAttr('data-page');

    awardsHandler.destroy();
  });

  describe('::showEmojiMenu', function() {
    it('should show emoji menu when Add emoji button clicked', function(done) {
      $('.js-add-award')
        .eq(0)
        .click();
      lazyAssert(done, function() {
        const $emojiMenu = $('.emoji-menu');

        expect($emojiMenu.length).toBe(1);
        expect($emojiMenu.hasClass('is-visible')).toBe(true);
        expect($emojiMenu.find('.js-emoji-menu-search').length).toBe(1);
        expect($('.js-awards-block.current').length).toBe(1);
      });
    });

    it('should also show emoji menu for the smiley icon in notes', function(done) {
      $('.js-add-award.note-action-button').click();
      lazyAssert(done, function() {
        const $emojiMenu = $('.emoji-menu');

        expect($emojiMenu.length).toBe(1);
      });
    });

    it('should remove emoji menu when body is clicked', function(done) {
      $('.js-add-award')
        .eq(0)
        .click();
      lazyAssert(done, function() {
        const $emojiMenu = $('.emoji-menu');
        $('body').click();

        expect($emojiMenu.length).toBe(1);
        expect($emojiMenu.hasClass('is-visible')).toBe(false);
        expect($('.js-awards-block.current').length).toBe(0);
      });
    });

    it('should not remove emoji menu when search is clicked', function(done) {
      $('.js-add-award')
        .eq(0)
        .click();
      lazyAssert(done, function() {
        const $emojiMenu = $('.emoji-menu');
        $('.emoji-search').click();

        expect($emojiMenu.length).toBe(1);
        expect($emojiMenu.hasClass('is-visible')).toBe(true);
        expect($('.js-awards-block.current').length).toBe(1);
      });
    });
  });

  describe('::addAwardToEmojiBar', function() {
    it('should add emoji to votes block', function() {
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      const $emojiButton = $votesBlock.find('[data-name=heart]');

      expect($emojiButton.length).toBe(1);
      expect($emojiButton.next('.js-counter').text()).toBe('1');
      expect($votesBlock.hasClass('hidden')).toBe(false);
    });

    it('should remove the emoji when we click again', function() {
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      const $emojiButton = $votesBlock.find('[data-name=heart]');

      expect($emojiButton.length).toBe(0);
    });

    it('should decrement the emoji counter', function() {
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      const $emojiButton = $votesBlock.find('[data-name=heart]');
      $emojiButton.next('.js-counter').text(5);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);

      expect($emojiButton.length).toBe(1);
      expect($emojiButton.next('.js-counter').text()).toBe('4');
    });
  });

  describe('::userAuthored', function() {
    it('should update tooltip to user authored title', function() {
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'sam');
      awardsHandler.userAuthored($thumbsUpEmoji);

      expect($thumbsUpEmoji.data('originalTitle')).toBe(
        'You cannot vote on your own issue, MR and note',
      );
    });

    it('should restore tooltip back to initial vote list', function() {
      jasmine.clock().install();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'sam');
      awardsHandler.userAuthored($thumbsUpEmoji);
      jasmine.clock().tick(2801);
      jasmine.clock().uninstall();

      expect($thumbsUpEmoji.data('originalTitle')).toBe('sam');
    });
  });

  describe('::getAwardUrl', function() {
    it('returns the url for request', function() {
      expect(awardsHandler.getAwardUrl()).toBe('http://test.host/snippets/1/toggle_award_emoji');
    });
  });

  describe('::addAward and ::checkMutuality', function() {
    it('should handle :+1: and :-1: mutuality', function() {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      const $thumbsDownEmoji = $votesBlock.find('[data-name=thumbsdown]').parent();
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);

      expect($thumbsUpEmoji.hasClass('active')).toBe(true);
      expect($thumbsDownEmoji.hasClass('active')).toBe(false);
      $thumbsUpEmoji.tooltip();
      $thumbsDownEmoji.tooltip();
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsdown', true);

      expect($thumbsUpEmoji.hasClass('active')).toBe(false);
      expect($thumbsDownEmoji.hasClass('active')).toBe(true);
    });
  });

  describe('::removeEmoji', function() {
    it('should remove emoji', function() {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAward($votesBlock, awardUrl, 'fire', false);

      expect($votesBlock.find('[data-name=fire]').length).toBe(1);
      awardsHandler.removeEmoji($votesBlock.find('[data-name=fire]').closest('button'));

      expect($votesBlock.find('[data-name=fire]').length).toBe(0);
    });
  });

  describe('::addYouToUserList', function() {
    it('should prepend "You" to the award tooltip', function() {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'sam, jerry, max, and andy');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);
      $thumbsUpEmoji.tooltip();

      expect($thumbsUpEmoji.data('originalTitle')).toBe('You, sam, jerry, max, and andy');
    });

    it('handles the special case where "You" is not cleanly comma separated', function() {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'sam');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);
      $thumbsUpEmoji.tooltip();

      expect($thumbsUpEmoji.data('originalTitle')).toBe('You and sam');
    });
  });

  describe('::removeYouToUserList', function() {
    it('removes "You" from the front of the tooltip', function() {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'You, sam, jerry, max, and andy');
      $thumbsUpEmoji.addClass('active');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);
      $thumbsUpEmoji.tooltip();

      expect($thumbsUpEmoji.data('originalTitle')).toBe('sam, jerry, max, and andy');
    });

    it('handles the special case where "You" is not cleanly comma separated', function() {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'You and sam');
      $thumbsUpEmoji.addClass('active');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);
      $thumbsUpEmoji.tooltip();

      expect($thumbsUpEmoji.data('originalTitle')).toBe('sam');
    });
  });

  describe('::searchEmojis', () => {
    it('should filter the emoji', function(done) {
      openAndWaitForEmojiMenu()
        .then(() => {
          expect($('[data-name=angel]').is(':visible')).toBe(true);
          expect($('[data-name=anger]').is(':visible')).toBe(true);
          awardsHandler.searchEmojis('ali');

          expect($('[data-name=angel]').is(':visible')).toBe(false);
          expect($('[data-name=anger]').is(':visible')).toBe(false);
          expect($('[data-name=alien]').is(':visible')).toBe(true);
          expect($('.js-emoji-menu-search').val()).toBe('ali');
        })
        .then(done)
        .catch(err => {
          done.fail(`Failed to open and build emoji menu: ${err.message}`);
        });
    });

    it('should clear the search when searching for nothing', function(done) {
      openAndWaitForEmojiMenu()
        .then(() => {
          awardsHandler.searchEmojis('ali');

          expect($('[data-name=angel]').is(':visible')).toBe(false);
          expect($('[data-name=anger]').is(':visible')).toBe(false);
          expect($('[data-name=alien]').is(':visible')).toBe(true);
          awardsHandler.searchEmojis('');

          expect($('[data-name=angel]').is(':visible')).toBe(true);
          expect($('[data-name=anger]').is(':visible')).toBe(true);
          expect($('[data-name=alien]').is(':visible')).toBe(true);
          expect($('.js-emoji-menu-search').val()).toBe('');
        })
        .then(done)
        .catch(err => {
          done.fail(`Failed to open and build emoji menu: ${err.message}`);
        });
    });
  });

  describe('emoji menu', function() {
    const emojiSelector = '[data-name="sunglasses"]';
    const openEmojiMenuAndAddEmoji = function() {
      return openAndWaitForEmojiMenu().then(() => {
        const $menu = $('.emoji-menu');
        const $block = $('.js-awards-block');
        const $emoji = $menu.find(`.emoji-menu-list:not(.frequent-emojis) ${emojiSelector}`);

        expect($emoji.length).toBe(1);
        expect($block.find(emojiSelector).length).toBe(0);
        $emoji.click();

        expect($menu.hasClass('.is-visible')).toBe(false);
        expect($block.find(emojiSelector).length).toBe(1);
      });
    };

    it('should add selected emoji to awards block', function(done) {
      openEmojiMenuAndAddEmoji()
        .then(done)
        .catch(err => {
          done.fail(`Failed to open and build emoji menu: ${err.message}`);
        });
    });

    it('should remove already selected emoji', function(done) {
      openEmojiMenuAndAddEmoji()
        .then(() => {
          $('.js-add-award')
            .eq(0)
            .click();
          const $block = $('.js-awards-block');
          const $emoji = $('.emoji-menu').find(
            `.emoji-menu-list:not(.frequent-emojis) ${emojiSelector}`,
          );
          $emoji.click();

          expect($block.find(emojiSelector).length).toBe(0);
        })
        .then(done)
        .catch(err => {
          done.fail(`Failed to open and build emoji menu: ${err.message}`);
        });
    });
  });

  describe('frequently used emojis', function() {
    beforeEach(() => {
      // Clear it out
      Cookies.set('frequently_used_emojis', '');
    });

    it('shouldn\'t have any "Frequently used" heading if no frequently used emojis', function(done) {
      return openAndWaitForEmojiMenu()
        .then(() => {
          const emojiMenu = document.querySelector('.emoji-menu');
          Array.prototype.forEach.call(emojiMenu.querySelectorAll('.emoji-menu-title'), title => {
            expect(title.textContent.trim().toLowerCase()).not.toBe('frequently used');
          });
        })
        .then(done)
        .catch(err => {
          done.fail(`Failed to open and build emoji menu: ${err.message}`);
        });
    });

    it('should have any frequently used section when there are frequently used emojis', function(done) {
      awardsHandler.addEmojiToFrequentlyUsedList('8ball');

      return openAndWaitForEmojiMenu()
        .then(() => {
          const emojiMenu = document.querySelector('.emoji-menu');
          const hasFrequentlyUsedHeading = Array.prototype.some.call(
            emojiMenu.querySelectorAll('.emoji-menu-title'),
            title => title.textContent.trim().toLowerCase() === 'frequently used',
          );

          expect(hasFrequentlyUsedHeading).toBe(true);
        })
        .then(done)
        .catch(err => {
          done.fail(`Failed to open and build emoji menu: ${err.message}`);
        });
    });

    it('should disregard invalid frequently used emoji that are being attempted to be added', function() {
      awardsHandler.addEmojiToFrequentlyUsedList('8ball');
      awardsHandler.addEmojiToFrequentlyUsedList('invalid_emoji');
      awardsHandler.addEmojiToFrequentlyUsedList('grinning');

      expect(awardsHandler.getFrequentlyUsedEmojis()).toEqual(['8ball', 'grinning']);
    });

    it('should disregard invalid frequently used emoji already set in cookie', function() {
      Cookies.set('frequently_used_emojis', '8ball,invalid_emoji,grinning');

      expect(awardsHandler.getFrequentlyUsedEmojis()).toEqual(['8ball', 'grinning']);
    });
  });
});
