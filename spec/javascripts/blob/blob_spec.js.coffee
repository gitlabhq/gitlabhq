#= require blob/blob

describe 'BlobView', ->
  fixture.preload('blob.html')

  clickLine = (number, eventData = {}) ->
    if $.isEmptyObject(eventData)
      $("#L#{number}").mousedown().click()
    else
      e = $.Event 'mousedown', eventData
      $("#L#{number}").trigger(e).click()

  beforeEach ->
    fixture.load('blob.html')
    @class = new BlobView()
    @spies = {
      __setLocationHash__: spyOn(@class, '__setLocationHash__').and.callFake ->
    }

  describe 'behavior', ->
    it 'highlights one line given in the URL hash', ->
      new BlobView('#L13')
      expect($('#LC13')).toHaveClass('hll')

    it 'highlights a range of lines given in the URL hash', ->
      new BlobView('#L5-25')
      expect($('.hll').length).toBe(21)
      expect($("#LC#{line}")).toHaveClass('hll') for line in [5..25]

    it 'scrolls to the first highlighted line on initial load', ->
      spy = spyOn($, 'scrollTo')
      new BlobView('#L5-25')
      expect(spy).toHaveBeenCalledWith('#L5', jasmine.anything())

    it 'discards click events', ->
      spy = spyOnEvent('a[data-line-number]', 'click')
      clickLine(13)
      expect(spy).toHaveBeenPrevented()

    it 'handles garbage input from the hash', ->
      func = -> new BlobView('#tree-content-holder')
      expect(func).not.toThrow()

  describe '#clickHandler', ->
    it 'discards the mousedown event', ->
      spy = spyOnEvent('a[data-line-number]', 'mousedown')
      clickLine(13)
      expect(spy).toHaveBeenPrevented()

    describe 'without shiftKey', ->
      it 'highlights one line when clicked', ->
        clickLine(13)
        expect($('#LC13')).toHaveClass('hll')

      it 'unhighlights previously highlighted lines', ->
        clickLine(13)
        clickLine(20)

        expect($('#LC13')).not.toHaveClass('hll')
        expect($('#LC20')).toHaveClass('hll')

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
          expect($('#LC13')).toHaveClass('hll')
          expect($('.hll').length).toBe(1)

        it 'sets the hash', ->
          spy = spyOn(@class, 'setHash')
          clickLine(13, shiftKey: true)
          expect(spy).toHaveBeenCalledWith(13)

      describe 'with existing single-line highlight', ->
        it 'uses existing line as last line when target is lesser', ->
          clickLine(20)
          clickLine(15, shiftKey: true)
          expect($('.hll').length).toBe(6)
          expect($("#LC#{line}")).toHaveClass('hll') for line in [15..20]

        it 'uses existing line as first line when target is greater', ->
          clickLine(5)
          clickLine(10, shiftKey: true)
          expect($('.hll').length).toBe(6)
          expect($("#LC#{line}")).toHaveClass('hll') for line in [5..10]

      describe 'with existing multi-line highlight', ->
        beforeEach ->
          clickLine(10, shiftKey: true)
          clickLine(13, shiftKey: true)

        it 'uses target as first line when it is less than existing first line', ->
          clickLine(5, shiftKey: true)
          expect($('.hll').length).toBe(6)
          expect($("#LC#{line}")).toHaveClass('hll') for line in [5..10]

        it 'uses target as last line when it is greater than existing first line', ->
          clickLine(15, shiftKey: true)
          expect($('.hll').length).toBe(6)
          expect($("#LC#{line}")).toHaveClass('hll') for line in [10..15]

  describe '#hashToRange', ->
    beforeEach ->
      @subject = @class.hashToRange

    it 'extracts a single line number from the hash', ->
      expect(@subject('#L5')).toEqual([5, NaN])

    it 'extracts a range of line numbers from the hash', ->
      expect(@subject('#L5-15')).toEqual([5, 15])

    it 'returns [NaN, NaN] when the hash is not a line number', ->
      expect(@subject('#foo')).toEqual([NaN, NaN])

  describe '#highlightLine', ->
    beforeEach ->
      @subject = @class.highlightLine

    it 'highlights the specified line', ->
      @subject(13)
      expect($('#LC13')).toHaveClass('hll')

    it 'accepts a String-based number', ->
      @subject('13')
      expect($('#LC13')).toHaveClass('hll')

    it 'returns undefined when given NaN', ->
      expect(@subject(NaN)).toBe(undefined)
      expect(@subject('foo')).toBe(undefined)

  describe '#highlightRange', ->
    beforeEach ->
      @subject = @class.highlightRange

    it 'returns undefined when first line is NaN', ->
      expect(@subject([NaN, 15])).toBe(undefined)
      expect(@subject(['foo', 15])).toBe(undefined)

    it 'returns undefined when given an invalid first line', ->
      expect(@subject(['foo', 15])).toBe(undefined)
      expect(@subject([NaN, NaN])).toBe(undefined)
      expect(@subject('foo')).toBe(undefined)

  describe '#setHash', ->
    beforeEach ->
      @subject = @class.setHash

    it 'returns undefined when given an invalid first line', ->
      expect(@subject('foo', 15)).toBe(undefined)

    it 'sets the location hash for a single line', ->
      @subject(5)
      expect(@spies.__setLocationHash__).toHaveBeenCalledWith('#L5')

    it 'sets the location hash for a range', ->
      @subject(5, 15)
      expect(@spies.__setLocationHash__).toHaveBeenCalledWith('#L5-15')
