#= require extensions/array

describe 'Array extensions', ->
  describe 'first', ->
    it 'returns the first item', ->
      arr = [0, 1, 2, 3, 4, 5]
      expect(arr.first()).toBe(0)

  describe 'last', ->
    it 'returns the last item', ->
      arr = [0, 1, 2, 3, 4, 5]
      expect(arr.last()).toBe(5)
