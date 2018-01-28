import { parseSeconds, abbreviateTime, stringifyTime } from '~/lib/utils/pretty_time';

function assertTimeUnits(obj, minutes, hours, days, weeks) {
  expect(obj.minutes).toBe(minutes);
  expect(obj.hours).toBe(hours);
  expect(obj.days).toBe(days);
  expect(obj.weeks).toBe(weeks);
}

describe('prettyTime methods', () => {
  describe('parseSeconds', () => {
    it('should correctly parse a negative value', () => {
      const zeroSeconds = parseSeconds(-1000);

      assertTimeUnits(zeroSeconds, 16, 0, 0, 0);
    });

    it('should correctly parse a zero value', () => {
      const zeroSeconds = parseSeconds(0);

      assertTimeUnits(zeroSeconds, 0, 0, 0, 0);
    });

    it('should correctly parse a small non-zero second values', () => {
      const subOneMinute = parseSeconds(10);
      const aboveOneMinute = parseSeconds(100);
      const manyMinutes = parseSeconds(1000);

      assertTimeUnits(subOneMinute, 0, 0, 0, 0);
      assertTimeUnits(aboveOneMinute, 1, 0, 0, 0);
      assertTimeUnits(manyMinutes, 16, 0, 0, 0);
    });

    it('should correctly parse large second values', () => {
      const aboveOneHour = parseSeconds(4800);
      const aboveOneDay = parseSeconds(110000);
      const aboveOneWeek = parseSeconds(25000000);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 3, 173);
    });

    it('should correctly accept a custom param for hoursPerDay', () => {
      const config = { hoursPerDay: 24 };

      const aboveOneHour = parseSeconds(4800, config);
      const aboveOneDay = parseSeconds(110000, config);
      const aboveOneWeek = parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 1, 0);
      assertTimeUnits(aboveOneWeek, 26, 8, 4, 57);
    });

    it('should correctly accept a custom param for daysPerWeek', () => {
      const config = { daysPerWeek: 7 };

      const aboveOneHour = parseSeconds(4800, config);
      const aboveOneDay = parseSeconds(110000, config);
      const aboveOneWeek = parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 0, 124);
    });

    it('should correctly accept custom params for daysPerWeek and hoursPerDay', () => {
      const config = { daysPerWeek: 55, hoursPerDay: 14 };

      const aboveOneHour = parseSeconds(4800, config);
      const aboveOneDay = parseSeconds(110000, config);
      const aboveOneWeek = parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 2, 2, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 1, 9);
    });
  });

  describe('stringifyTime', () => {
    it('should stringify values with all non-zero units', () => {
      const timeObject = {
        weeks: 1,
        days: 4,
        hours: 7,
        minutes: 20,
      };

      const timeString = stringifyTime(timeObject);

      expect(timeString).toBe('1w 4d 7h 20m');
    });

    it('should stringify values with some non-zero units', () => {
      const timeObject = {
        weeks: 0,
        days: 4,
        hours: 0,
        minutes: 20,
      };

      const timeString = stringifyTime(timeObject);

      expect(timeString).toBe('4d 20m');
    });

    it('should stringify values with no non-zero units', () => {
      const timeObject = {
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
      };

      const timeString = stringifyTime(timeObject);

      expect(timeString).toBe('0m');
    });
  });

  describe('abbreviateTime', () => {
    it('should abbreviate stringified times for weeks', () => {
      const fullTimeString = '1w 3d 4h 5m';
      expect(abbreviateTime(fullTimeString)).toBe('1w');
    });

    it('should abbreviate stringified times for non-weeks', () => {
      const fullTimeString = '0w 3d 4h 5m';
      expect(abbreviateTime(fullTimeString)).toBe('3d');
    });
  });
});
