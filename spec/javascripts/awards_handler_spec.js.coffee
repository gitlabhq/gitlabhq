###
//= require awards_handler
###
###
//= require jquery
###
###
//= require jquery.cookie
###
###
//= require ./fixtures/emoji_menu
###

awardsHandler      = null
window.gl        or= {}
window.gon       or= {}
gl.emojiAliases    = -> return { '+1': 'thumbsup', '-1': 'thumbsdown' }
gon.award_menu_url = '/emojis'


lazyAssert = (done, assertFn) ->

  setTimeout -> # Maybe jasmine.clock here?
    assertFn()
    done()
  , 333


describe 'AwardsHandler', ->

  fixture.preload 'awards_handler.html'

  beforeEach ->
    fixture.load 'awards_handler.html'
    awardsHandler = new AwardsHandler
    spyOn(awardsHandler, 'postEmoji').and.callFake (url, emoji, cb) => cb()
    spyOn(jQuery, 'get').and.callFake (req, cb) -> cb window.emojiMenu


  describe '::showEmojiMenu', ->

    it 'should show emoji menu when Add emoji button clicked', (done) ->

      $('.js-add-award').eq(0).click()

      lazyAssert done, ->
        $emojiMenu = $ '.emoji-menu'
        expect($emojiMenu.length).toBe 1
        expect($emojiMenu.hasClass('is-visible')).toBe yes
        expect($emojiMenu.find('#emoji_search').length).toBe 1
        expect($('.js-awards-block.current').length).toBe 1


    it 'should also show emoji menu for the smiley icon in notes', (done) ->

      $('.note-action-button').click()

      lazyAssert done, ->
        $emojiMenu = $ '.emoji-menu'
        expect($emojiMenu.length).toBe 1


    it 'should remove emoji menu when body is clicked', (done) ->

      $('.js-add-award').eq(0).click()

      lazyAssert done, ->
        $emojiMenu = $('.emoji-menu')
        $('body').click()
        expect($emojiMenu.length).toBe 1
        expect($emojiMenu.hasClass('is-visible')).toBe no
        expect($('.js-awards-block.current').length).toBe 0


  describe '::addAwardToEmojiBar', ->

    it 'should add emoji to votes block', ->

      $votesBlock = $('.js-awards-block').eq 0
      awardsHandler.addAwardToEmojiBar $votesBlock, 'heart', no

      $emojiButton = $votesBlock.find '[data-emoji=heart]'

      expect($emojiButton.length).toBe 1
      expect($emojiButton.next('.js-counter').text()).toBe '1'
      expect($votesBlock.hasClass('hidden')).toBe no


    it 'should remove the emoji when we click again', ->

      $votesBlock = $('.js-awards-block').eq 0
      awardsHandler.addAwardToEmojiBar $votesBlock, 'heart', no
      awardsHandler.addAwardToEmojiBar $votesBlock, 'heart', no
      $emojiButton = $votesBlock.find '[data-emoji=heart]'

      expect($emojiButton.length).toBe 0


    it 'should decrement the emoji counter', ->

      $votesBlock = $('.js-awards-block').eq 0
      awardsHandler.addAwardToEmojiBar $votesBlock, 'heart', no

      $emojiButton = $votesBlock.find '[data-emoji=heart]'
      $emojiButton.next('.js-counter').text 5

      awardsHandler.addAwardToEmojiBar $votesBlock, 'heart', no

      expect($emojiButton.length).toBe 1
      expect($emojiButton.next('.js-counter').text()).toBe '4'


  describe '::getAwardUrl', ->

    it 'should return the url for request', ->

      expect(awardsHandler.getAwardUrl()).toBe '/gitlab-org/gitlab-test/issues/8/toggle_award_emoji'


  describe '::addAward and ::checkMutuality', ->

    it 'should handle :+1: and :-1: mutuality', ->

      awardUrl         = awardsHandler.getAwardUrl()
      $votesBlock      = $('.js-awards-block').eq 0
      $thumbsUpEmoji   = $votesBlock.find('[data-emoji=thumbsup]').parent()
      $thumbsDownEmoji = $votesBlock.find('[data-emoji=thumbsdown]').parent()

      awardsHandler.addAward $votesBlock, awardUrl, 'thumbsup', no

      expect($thumbsUpEmoji.hasClass('active')).toBe yes
      expect($thumbsDownEmoji.hasClass('active')).toBe no

      $thumbsUpEmoji.tooltip()
      $thumbsDownEmoji.tooltip()

      awardsHandler.addAward $votesBlock, awardUrl, 'thumbsdown', yes

      expect($thumbsUpEmoji.hasClass('active')).toBe no
      expect($thumbsDownEmoji.hasClass('active')).toBe yes


  describe '::removeEmoji', ->

    it 'should remove emoji', ->

      awardUrl    = awardsHandler.getAwardUrl()
      $votesBlock = $('.js-awards-block').eq 0

      awardsHandler.addAward $votesBlock, awardUrl, 'fire',  no
      expect($votesBlock.find('[data-emoji=fire]').length).toBe  1

      awardsHandler.removeEmoji $votesBlock.find('[data-emoji=fire]').closest('button')
      expect($votesBlock.find('[data-emoji=fire]').length).toBe  0


  describe 'search', ->

    it 'should filter the emoji', ->

      $('.js-add-award').eq(0).click()

      expect($('[data-emoji=angel]').is(':visible')).toBe yes
      expect($('[data-emoji=anger]').is(':visible')).toBe yes

      $('#emoji_search').val('ali').trigger 'keyup'

      expect($('[data-emoji=angel]').is(':visible')).toBe no
      expect($('[data-emoji=anger]').is(':visible')).toBe no
      expect($('[data-emoji=alien]').is(':visible')).toBe yes


  describe 'emoji menu', ->

    selector = '[data-emoji=sunglasses]'

    openEmojiMenuAndAddEmoji = ->

      $('.js-add-award').eq(0).click()

      $menu  = $ '.emoji-menu'
      $block = $ '.js-awards-block'
      $emoji = $menu.find ".emoji-menu-list-item #{selector}"

      expect($emoji.length).toBe 1
      expect($block.find(selector).length).toBe 0

      $emoji.click()

      expect($menu.hasClass('.is-visible')).toBe no
      expect($block.find(selector).length).toBe 1


    it 'should add selected emoji to awards block', ->

      openEmojiMenuAndAddEmoji()


    it 'should remove already selected emoji', ->

      openEmojiMenuAndAddEmoji()
      $('.js-add-award').eq(0).click()

      $block = $ '.js-awards-block'
      $emoji = $('.emoji-menu').find ".emoji-menu-list-item #{selector}"

      $emoji.click()
      expect($block.find(selector).length).toBe 0
