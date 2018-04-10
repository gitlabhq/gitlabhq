import * as datetimeUtility from '~/lib/utils/datetime_utility';

describe('Date time utils', () => {
  describe('timeFor', () => {
    it('returns `past due` when in past', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() - 1);

      expect(
        datetimeUtility.timeFor(date),
      ).toBe('Past due');
    });

    it('returns remaining time when in the future', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() + 1);

      // Add a day to prevent a transient error. If date is even 1 second
      // short of a full year, timeFor will return '11 months remaining'
      date.setDate(date.getDate() + 1);

      expect(
        datetimeUtility.timeFor(date),
      ).toBe('1 year remaining');
    });
  });

  describe('get day name', () => {
    it('should return Sunday', () => {
      const day = datetimeUtility.getDayName(new Date('07/17/2016'));
      expect(day).toBe('Sunday');
    });

    it('should return Monday', () => {
      const day = datetimeUtility.getDayName(new Date('07/18/2016'));
      expect(day).toBe('Monday');
    });

    it('should return Tuesday', () => {
      const day = datetimeUtility.getDayName(new Date('07/19/2016'));
      expect(day).toBe('Tuesday');
    });

    it('should return Wednesday', () => {
      const day = datetimeUtility.getDayName(new Date('07/20/2016'));
      expect(day).toBe('Wednesday');
    });

    it('should return Thursday', () => {
      const day = datetimeUtility.getDayName(new Date('07/21/2016'));
      expect(day).toBe('Thursday');
    });

    it('should return Friday', () => {
      const day = datetimeUtility.getDayName(new Date('07/22/2016'));
      expect(day).toBe('Friday');
    });

    it('should return Saturday', () => {
      const day = datetimeUtility.getDayName(new Date('07/23/2016'));
      expect(day).toBe('Saturday');
    });
  });

  describe('get day difference', () => {
    it('should return 7', () => {
      const firstDay = new Date('07/01/2016');
      const secondDay = new Date('07/08/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);
      expect(difference).toBe(7);
    });

    it('should return 31', () => {
      const firstDay = new Date('07/01/2016');
      const secondDay = new Date('08/01/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);
      expect(difference).toBe(31);
    });

    it('should return 365', () => {
      const firstDay = new Date('07/02/2015');
      const secondDay = new Date('07/01/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);
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

  it('should return date in words without year', () => {
    expect(datetimeUtility.dateInWords(date, true, true)).toEqual('Jul 1');
  });
});

describe('monthInWords', () => {
  const date = new Date('2017-01-20');

  it('returns month name from provided date', () => {
    expect(datetimeUtility.monthInWords(date)).toBe('January');
  });

  it('returns abbreviated month name from provided date', () => {
    expect(datetimeUtility.monthInWords(date, true)).toBe('Jan');
  });
});

describe('totalDaysInMonth', () => {
  it('returns number of days in a month for given date', () => {
    // 1st Feb, 2016 (leap year)
    expect(datetimeUtility.totalDaysInMonth(new Date(2016, 1, 1))).toBe(29);

    // 1st Feb, 2017
    expect(datetimeUtility.totalDaysInMonth(new Date(2017, 1, 1))).toBe(28);

    // 1st Jan, 2017
    expect(datetimeUtility.totalDaysInMonth(new Date(2017, 0, 1))).toBe(31);
  });
});

describe('getSundays', () => {
  it('returns array of dates representing all Sundays of the month', () => {
    // December, 2017 (it has 5 Sundays)
    const dateOfSundays = [3, 10, 17, 24, 31];
    const sundays = datetimeUtility.getSundays(new Date(2017, 11, 1));

    expect(sundays.length).toBe(5);
    sundays.forEach((sunday, index) => {
      expect(sunday.getDate()).toBe(dateOfSundays[index]);
    });
  });
});

describe('getTimeframeWindow', () => {
  it('returns array of dates representing a timeframe based on provided length and date', () => {
    const date = new Date(2018, 0, 1);
    const mockTimeframe = [
      new Date(2017, 9, 1),
      new Date(2017, 10, 1),
      new Date(2017, 11, 1),
      new Date(2018, 0, 1),
      new Date(2018, 1, 1),
      new Date(2018, 2, 31),
    ];
    const timeframe = datetimeUtility.getTimeframeWindow(6, date);

    expect(timeframe.length).toBe(6);
    timeframe.forEach((timeframeItem, index) => {
      expect(timeframeItem.getFullYear() === mockTimeframe[index].getFullYear()).toBeTruthy();
      expect(timeframeItem.getMonth() === mockTimeframe[index].getMonth()).toBeTruthy();
      expect(timeframeItem.getDate() === mockTimeframe[index].getDate()).toBeTruthy();
    });
  });
});
