//= require lib/utils/datetime_utility
(() => {
  describe('Date time utils', () => {
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
})();
