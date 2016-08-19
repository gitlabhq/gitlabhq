#= require lib/utils/datetime_utility

describe 'Date time utils', ->
  describe 'get day name', ->
    it 'returns Sunday', ->
      day = gl.utils.getDayName(new Date('07/17/2016'))
      expect(day).toBe('Sunday')

    it 'returns Monday', ->
      day = gl.utils.getDayName(new Date('07/18/2016'))
      expect(day).toBe('Monday')

    it 'returns Tuesday', ->
      day = gl.utils.getDayName(new Date('07/19/2016'))
      expect(day).toBe('Tuesday')

    it 'returns Wednesday', ->
      day = gl.utils.getDayName(new Date('07/20/2016'))
      expect(day).toBe('Wednesday')

    it 'returns Thursday', ->
      day = gl.utils.getDayName(new Date('07/21/2016'))
      expect(day).toBe('Thursday')

    it 'returns Friday', ->
      day = gl.utils.getDayName(new Date('07/22/2016'))
      expect(day).toBe('Friday')

    it 'returns Saturday', ->
      day = gl.utils.getDayName(new Date('07/23/2016'))
      expect(day).toBe('Saturday')
