import * as datetimeUtility from '~/lib/utils/datetime_utility';

(() => {
  describe('Date time utils', () => {
    describe('timeFor', () => {
      it('returns `past due` when in past', () => {
        const date = new Date();
        date.setFullYear(date.getFullYear() - 1);

        expect(
          gl.utils.timeFor(date),
        ).toBe('Past due');
      });

      it('returns remaining time when in the future', () => {
        const date = new Date();
        date.setFullYear(date.getFullYear() + 1);

        // Add a day to prevent a transient error. If date is even 1 second
        // short of a full year, timeFor will return '11 months remaining'
        date.setDate(date.getDate() + 1);

        expect(
          gl.utils.timeFor(date),
        ).toBe('1 year remaining');
      });
    });

    describe('get day name', () => {
      it('should return Sunday', () => {
        const day = gl.utils.getDayName(new Date('07/17/2016'));
        expect(day).toBe('Sunday');
      });

      it('should return Monday', () => {
        const day = gl.utils.getDayName(new Date('07/18/2016'));
        expect(day).toBe('Monday');
      });

      it('should return Tuesday', () => {
        const day = gl.utils.getDayName(new Date('07/19/2016'));
        expect(day).toBe('Tuesday');
      });

      it('should return Wednesday', () => {
        const day = gl.utils.getDayName(new Date('07/20/2016'));
        expect(day).toBe('Wednesday');
      });

      it('should return Thursday', () => {
        const day = gl.utils.getDayName(new Date('07/21/2016'));
        expect(day).toBe('Thursday');
      });

      it('should return Friday', () => {
        const day = gl.utils.getDayName(new Date('07/22/2016'));
        expect(day).toBe('Friday');
      });

      it('should return Saturday', () => {
        const day = gl.utils.getDayName(new Date('07/23/2016'));
        expect(day).toBe('Saturday');
      });
    });

    describe('get day difference', () => {
      it('should return 7', () => {
        const firstDay = new Date('07/01/2016');
        const secondDay = new Date('07/08/2016');
        const difference = gl.utils.getDayDifference(firstDay, secondDay);
        expect(difference).toBe(7);
      });

      it('should return 31', () => {
        const firstDay = new Date('07/01/2016');
        const secondDay = new Date('08/01/2016');
        const difference = gl.utils.getDayDifference(firstDay, secondDay);
        expect(difference).toBe(31);
      });

      it('should return 365', () => {
        const firstDay = new Date('07/02/2015');
        const secondDay = new Date('07/01/2016');
        const difference = gl.utils.getDayDifference(firstDay, secondDay);
        expect(difference).toBe(365);
      });
    });
  });

  describe('timeIntervalInWords', () => {
    it('should return string with number of minutes and seconds', () => {
      expect(datetimeUtility.timeIntervalInWords(9.54)).toEqual('9 seconds');
      expect(datetimeUtility.timeIntervalInWords(1)).toEqual('1 second');
      expect(datetimeUtility.timeIntervalInWords(200)).toEqual('3 minutes 20 seconds');
      expect(datetimeUtility.timeIntervalInWords(6008)).toEqual('100 minutes 8 seconds');
    });
  });

  describe('dateInWords', () => {
    const date = new Date('07/01/2016');

    it('should return date in words', () => {
      expect(datetimeUtility.dateInWords(date)).toEqual('July 1, 2016');
    });

    it('should return abbreviated month name', () => {
      expect(datetimeUtility.dateInWords(date, true)).toEqual('Jul 1, 2016');
    });
  });
})();
