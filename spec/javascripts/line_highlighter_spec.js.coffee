#= require line_highlighter

describe 'LineHighlighter', ->
  fixture.preload('line_highlighter.html')

  clickLine = (number, eventData = {}) ->
    if $.isEmptyObject(eventData)
      $("#L#{number}").mousedown().click()
    else
      e = $.Event 'mousedown', eventData
      $("#L#{number}").trigger(e).click()

  beforeEach ->
    fixture.load('line_highlighter.html')
    @class = new LineHighlighter()
    @css   = @class.highlightClass
    @spies = {
      __setLocationHash__: spyOn(@class, '__setLocationHash__').and.callFake ->
    }

  describe 'behavior', ->
    it 'highlights one line given in the URL hash', ->
      new LineHighlighter('#L13')
      expect($('#LC13')).toHaveClass(@css)

    it 'highlights a range of lines given in the URL hash', ->
      new LineHighlighter('#L5-25')
      expect($(".#{@css}").length).toBe(21)
      expect($("#LC#{line}")).toHaveClass(@css) for line in [5..25]

    it 'scrolls to the first highlighted line on initial load', ->
      spy = spyOn($, 'scrollTo')
      new LineHighlighter('#L5-25')
      expect(spy).toHaveBeenCalledWith('#L5', jasmine.anything())

    it 'discards click events', ->
      spy = spyOnEvent('a[data-line-number]', 'click')
      clickLine(13)
      expect(spy).toHaveBeenPrevented()

    it 'handles garbage input from the hash', ->
      func = -> new LineHighlighter('#blob-content-holder')
      expect(func).not.toThrow()

  describe '#clickHandler', ->
    it 'discards the mousedown event', ->
      spy = spyOnEvent('a[data-line-number]', 'mousedown')
      clickLine(13)
      expect(spy).toHaveBeenPrevented()

    it 'handles clicking on a child icon element', ->
      spy = spyOn(@class, 'setHash').and.callThrough()

      $('#L13 i').mousedown().click()

      expect(spy).toHaveBeenCalledWith(13)
      expect($('#LC13')).toHaveClass(@css)

    describe 'without shiftKey', ->
      it 'highlights one line when clicked', ->
        clickLine(13)
        expect($('#LC13')).toHaveClass(@css)

      it 'unhighlights previously highlighted lines', ->
        clickLine(13)
        clickLine(20)

        expect($('#LC13')).not.toHaveClass(@css)
        expect($('#LC20')).toHaveClass(@css)

      it 'sets the hash', ->
        spy = spyOn(@class, 'setHash').and.callThrough()
        clickLine(13)
        expect(spy).toHaveBeenCalledWith(13)

    describe 'with shiftKey', ->
      it 'sets the hash', ->
        spy = spyOn(@class, 'setHash').and.callThrough()
        clickLine(13)
        clickLine(20, shiftKey: true)
        expect(spy).toHaveBeenCalledWith(13)
        expect(spy).toHaveBeenCalledWith(13, 20)

      describe 'without existing highlight', ->
        it 'highlights the clicked line', ->
          clickLine(13, shiftKey: true)
          expect($('#LC13')).toHaveClass(@css)
          expect($(".#{@css}").length).toBe(1)

        it 'sets the hash', ->
          spy = spyOn(@class, 'setHash')
          clickLine(13, shiftKey: true)
          expect(spy).toHaveBeenCalledWith(13)

      describe 'with existing single-line highlight', ->
        it 'uses existing line as last line when target is lesser', ->
          clickLine(20)
          clickLine(15, shiftKey: true)
          expect($(".#{@css}").length).toBe(6)
          expect($("#LC#{line}")).toHaveClass(@css) for line in [15..20]

        it 'uses existing line as first line when target is greater', ->
          clickLine(5)
          clickLine(10, shiftKey: true)
          expect($(".#{@css}").length).toBe(6)
          expect($("#LC#{line}")).toHaveClass(@css) for line in [5..10]

      describe 'with existing multi-line highlight', ->
        beforeEach ->
          clickLine(10, shiftKey: true)
          clickLine(13, shiftKey: true)

        it 'uses target as first line when it is less than existing first line', ->
          clickLine(5, shiftKey: true)
          expect($(".#{@css}").length).toBe(6)
          expect($("#LC#{line}")).toHaveClass(@css) for line in [5..10]

        it 'uses target as last line when it is greater than existing first line', ->
          clickLine(15, shiftKey: true)
          expect($(".#{@css}").length).toBe(6)
          expect($("#LC#{line}")).toHaveClass(@css) for line in [10..15]

  describe '#hashToRange', ->
    beforeEach ->
      @subject = @class.hashToRange

    it 'extracts a single line number from the hash', ->
      expect(@subject('#L5')).toEqual([5, null])

    it 'extracts a range of line numbers from the hash', ->
      expect(@subject('#L5-15')).toEqual([5, 15])

    it 'returns [null, null] when the hash is not a line number', ->
      expect(@subject('#foo')).toEqual([null, null])

  describe '#highlightLine', ->
    beforeEach ->
      @subject = @class.highlightLine

    it 'highlights the specified line', ->
      @subject(13)
      expect($('#LC13')).toHaveClass(@css)

    it 'accepts a String-based number', ->
      @subject('13')
      expect($('#LC13')).toHaveClass(@css)

  describe '#setHash', ->
    beforeEach ->
      @subject = @class.setHash

    it 'sets the location hash for a single line', ->
      @subject(5)
      expect(@spies.__setLocationHash__).toHaveBeenCalledWith('#L5')

    it 'sets the location hash for a range', ->
      @subject(5, 15)
      expect(@spies.__setLocationHash__).toHaveBeenCalledWith('#L5-15')
