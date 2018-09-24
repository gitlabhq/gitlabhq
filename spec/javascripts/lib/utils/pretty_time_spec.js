import * as prettyTime from '~/lib/utils/pretty_time';

describe('pretty_time', () => {
  describe('stringifyTime', () => {
    it('should return representation of weeks, hours, and minutes', () => {
      const timeObject = { weeks: 1, days: 2, hours: 1, minutes: 2 };
      expect(prettyTime.stringifyTime(timeObject)).toEqual('1w 2d 1h 2m');
    });

    it('should return condensed representation of time object', () => {
      const timeObject = { weeks: 1, days: 0, hours: 1, minutes: 0 };
      expect(prettyTime.stringifyTime(timeObject)).toEqual('1w 1h');
    });

    it('should return non-condensed representation of time object', () => {
      const timeObject = { weeks: 1, days: 0, hours: 1, minutes: 0 };
      expect(prettyTime.stringifyTime(timeObject, true)).toEqual('1 week 1 hour');
    });

    it('should return 0m if time object contains 0 values', () => {
      const timeObject = { weeks: 0, days: 0, hours: 0, minutes: 0 };
      expect(prettyTime.stringifyTime(timeObject)).toEqual('0m');
    });
  });
});
