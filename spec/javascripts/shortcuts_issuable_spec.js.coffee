#= require shortcuts_issuable

describe 'ShortcutsIssuable', ->
  fixture.preload('issuable.html')

  beforeEach ->
    fixture.load('issuable.html')
    @shortcut = new ShortcutsIssuable()

  describe '#replyWithSelectedText', ->
    # Stub window.getSelection to return the provided String.
    stubSelection = (text) ->
      window.getSelection = -> text

    beforeEach ->
      @selector = 'form.js-main-target-form textarea#note_note'

    describe 'with empty selection', ->
      it 'does nothing', ->
        stubSelection('')
        @shortcut.replyWithSelectedText()
        expect($(@selector).val()).toBe('')

    describe 'with any selection', ->
      beforeEach ->
        stubSelection('Selected text.')

      it 'leaves existing input intact', ->
        $(@selector).val('This text was already here.')
        expect($(@selector).val()).toBe('This text was already here.')

        @shortcut.replyWithSelectedText()
        expect($(@selector).val()).
          toBe("This text was already here.\n> Selected text.\n\n")

      it 'triggers `input`', ->
        triggered = false
        $(@selector).on 'input', -> triggered = true
        @shortcut.replyWithSelectedText()

        expect(triggered).toBe(true)

      it 'triggers `focus`', ->
        focused = false
        $(@selector).on 'focus', -> focused = true
        @shortcut.replyWithSelectedText()

        expect(focused).toBe(true)

    describe 'with a one-line selection', ->
      it 'quotes the selection', ->
        stubSelection('This text has been selected.')

        @shortcut.replyWithSelectedText()

        expect($(@selector).val()).
          toBe("> This text has been selected.\n\n")

    describe 'with a multi-line selection', ->
      it 'quotes the selected lines as a group', ->
        stubSelection(
          """
          Selected line one.

          Selected line two.
          Selected line three.

          """
        )

        @shortcut.replyWithSelectedText()

        expect($(@selector).val()).
          toBe(
            """
            > Selected line one.
            > Selected line two.
            > Selected line three.


            """
          )
