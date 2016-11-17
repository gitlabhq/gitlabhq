//= require lib/utils/pretty_time

(() => {
  const PrettyTime = gl.PrettyTime;

  describe('PrettyTime methods', function() {
    describe('parseSeconds', function() {
      it('should correctly parse a negative value', function() {
        const parser = PrettyTime.parseSeconds;

        const zeroSeconds = parser(-1000);

        expect(zeroSeconds.minutes).toBe(16);
        expect(zeroSeconds.hours).toBe(0);
        expect(zeroSeconds.days).toBe(0);
        expect(zeroSeconds.weeks).toBe(0);
      });

      it('should correctly parse a zero value', function() {
        const parser = PrettyTime.parseSeconds;

        const zeroSeconds = parser(0);

        expect(zeroSeconds.minutes).toBe(0);
        expect(zeroSeconds.hours).toBe(0);
        expect(zeroSeconds.days).toBe(0);
        expect(zeroSeconds.weeks).toBe(0);
      });

      it('should correctly parse a small non-zero second values', function() {
        const parser = PrettyTime.parseSeconds;

        const subOneMinute = parser(10);

        expect(subOneMinute.minutes).toBe(0);
        expect(subOneMinute.hours).toBe(0);
        expect(subOneMinute.days).toBe(0);
        expect(subOneMinute.weeks).toBe(0);

        const aboveOneMinute = parser(100);

        expect(aboveOneMinute.minutes).toBe(1);
        expect(aboveOneMinute.hours).toBe(0);
        expect(aboveOneMinute.days).toBe(0);
        expect(aboveOneMinute.weeks).toBe(0);

        const manyMinutes = parser(1000);

        expect(manyMinutes.minutes).toBe(16);
        expect(manyMinutes.hours).toBe(0);
        expect(manyMinutes.days).toBe(0);
        expect(manyMinutes.weeks).toBe(0);
      });

      it('should correctly parse large second values', function() {
        const parser = PrettyTime.parseSeconds;

        const aboveOneHour = parser(4800);

        expect(aboveOneHour.minutes).toBe(20);
        expect(aboveOneHour.hours).toBe(1);
        expect(aboveOneHour.days).toBe(0);
        expect(aboveOneHour.weeks).toBe(0);

        const aboveOneDay = parser(110000);

        expect(aboveOneDay.minutes).toBe(33);
        expect(aboveOneDay.hours).toBe(6);
        expect(aboveOneDay.days).toBe(3);
        expect(aboveOneDay.weeks).toBe(0);

        const aboveOneWeek = parser(25000000);

        expect(aboveOneWeek.minutes).toBe(26);
        expect(aboveOneWeek.hours).toBe(0);
        expect(aboveOneWeek.days).toBe(3);
        expect(aboveOneWeek.weeks).toBe(173);
      });
    });

    describe('stringifyTime', function() {
      it('should stringify values with all non-zero units', function() {

        const timeObject = {
          weeks: 1,
          days: 4,
          hours: 7,
          minutes: 20
        };

        const timeString = PrettyTime.stringifyTime(timeObject);

        expect(timeString).toBe('1w 4d 7h 20m');
      });

      it('should stringify values with some non-zero units', function() {
        const timeObject = {
          weeks: 0,
          days: 4,
          hours: 0,
          minutes: 20
        };

        const timeString = PrettyTime.stringifyTime(timeObject);

        expect(timeString).toBe('4d 20m');
      });

      it('should stringify values with no non-zero units', function() {
        const timeObject = {
          weeks: 0,
          days: 0,
          hours: 0,
          minutes: 0
        };

        const timeString = PrettyTime.stringifyTime(timeObject);

        expect(timeString).toBe('0m');
      });
    });

    describe('abbreviateTime', function() {
      it('should abbreviate stringified times for weeks', function() {
        const fullTimeString = '1w 3d 4h 5m';
        expect(PrettyTime.abbreviateTime(fullTimeString)).toBe('1w');
      });

      it('should abbreviate stringified times for non-weeks', function() {
        const fullTimeString = '0w 3d 4h 5m';
        expect(PrettyTime.abbreviateTime(fullTimeString)).toBe('3d');
      });
    });
  });
})(window.gl || (window.gl = {}));
