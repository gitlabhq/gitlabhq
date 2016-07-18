#= require lib/utils/datetime_utility

describe 'Date time utils', ->
  describe 'get day name', ->
    it 'should return Sunday', ->
      day = gl.utils.getDayName(new Date('07/17/2016'))
      expect(day).toBe('Sunday')

    it 'should return Monday', ->
      day = gl.utils.getDayName(new Date('07/18/2016'))
      expect(day).toBe('Monday')

    it 'should return Tuesday', ->
      day = gl.utils.getDayName(new Date('07/19/2016'))
      expect(day).toBe('Tuesday')

    it 'should return Wednesday', ->
      day = gl.utils.getDayName(new Date('07/20/2016'))
      expect(day).toBe('Wednesday')

    it 'should return Thursday', ->
      day = gl.utils.getDayName(new Date('07/21/2016'))
      expect(day).toBe('Thursday')

    it 'should return Friday', ->
      day = gl.utils.getDayName(new Date('07/22/2016'))
      expect(day).toBe('Friday')

    it 'should return Saturday', ->
      day = gl.utils.getDayName(new Date('07/23/2016'))
      expect(day).toBe('Saturday')
