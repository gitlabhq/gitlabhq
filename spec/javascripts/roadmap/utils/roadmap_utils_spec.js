import {
  getTimeframeForQuartersView,
  getTimeframeForMonthsView,
  getTimeframeForWeeksView,
  getEpicsPathForPreset,
} from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee//roadmap/constants';

describe('getTimeframeForQuartersView', () => {
  let timeframe;

  beforeEach(() => {
    timeframe = getTimeframeForQuartersView(new Date(2018, 0, 1));
  });

  it('returns timeframe with total of 6 quarters', () => {
    expect(timeframe.length).toBe(6);
  });

  it('each timeframe item has `quarterSequence`, `year` and `range` present', () => {
    const timeframeItem = timeframe[0];

    expect(timeframeItem.quarterSequence).toEqual(jasmine.any(Number));
    expect(timeframeItem.year).toEqual(jasmine.any(Number));
    expect(Array.isArray(timeframeItem.range)).toBe(true);
  });

  it('first timeframe item refers to quarter prior to current quarter', () => {
    const timeframeItem = timeframe[0];
    const expectedQuarter = {
      0: { month: 9, date: 1 }, // 1 Oct 2017
      1: { month: 10, date: 1 }, // 1 Nov 2017
      2: { month: 11, date: 31 }, // 31 Dec 2017
    };

    expect(timeframeItem.quarterSequence).toEqual(4);
    expect(timeframeItem.year).toEqual(2017);
    timeframeItem.range.forEach((month, index) => {
      expect(month.getFullYear()).toBe(2017);
      expect(expectedQuarter[index].month).toBe(month.getMonth());
      expect(expectedQuarter[index].date).toBe(month.getDate());
    });
  });

  it('last timeframe item refers to 5th quarter from current quarter', () => {
    const timeframeItem = timeframe[timeframe.length - 1];
    const expectedQuarter = {
      0: { month: 0, date: 1 }, // 1 Jan 2019
      1: { month: 1, date: 1 }, // 1 Feb 2019
      2: { month: 2, date: 31 }, // 31 Mar 2019
    };

    expect(timeframeItem.quarterSequence).toEqual(1);
    expect(timeframeItem.year).toEqual(2019);
    timeframeItem.range.forEach((month, index) => {
      expect(month.getFullYear()).toBe(2019);
      expect(expectedQuarter[index].month).toBe(month.getMonth());
      expect(expectedQuarter[index].date).toBe(month.getDate());
    });
  });
});

describe('getTimeframeForMonthsView', () => {
  let timeframe;

  beforeEach(() => {
    timeframe = getTimeframeForMonthsView(new Date(2018, 0, 1));
  });

  it('returns timeframe with total of 7 months', () => {
    expect(timeframe.length).toBe(7);
  });

  it('first timeframe item refers to month prior to current month', () => {
    const timeframeItem = timeframe[0];
    const expectedMonth = {
      year: 2017,
      month: 11,
      date: 1,
    };

    expect(timeframeItem.getFullYear()).toBe(expectedMonth.year);
    expect(timeframeItem.getMonth()).toBe(expectedMonth.month);
    expect(timeframeItem.getDate()).toBe(expectedMonth.date);
  });

  it('last timeframe item refers to 6th month from current month', () => {
    const timeframeItem = timeframe[timeframe.length - 1];
    const expectedMonth = {
      year: 2018,
      month: 5,
      date: 30,
    };

    expect(timeframeItem.getFullYear()).toBe(expectedMonth.year);
    expect(timeframeItem.getMonth()).toBe(expectedMonth.month);
    expect(timeframeItem.getDate()).toBe(expectedMonth.date);
  });
});

describe('getTimeframeForWeeksView', () => {
  let timeframe;

  beforeEach(() => {
    timeframe = getTimeframeForWeeksView(new Date(2018, 0, 1));
  });

  it('returns timeframe with total of 6 weeks', () => {
    expect(timeframe.length).toBe(6);
  });

  it('first timeframe item refers to week prior to current week', () => {
    const timeframeItem = timeframe[0];
    const expectedMonth = {
      year: 2017,
      month: 11,
      date: 24,
    };

    expect(timeframeItem.getFullYear()).toBe(expectedMonth.year);
    expect(timeframeItem.getMonth()).toBe(expectedMonth.month);
    expect(timeframeItem.getDate()).toBe(expectedMonth.date);
  });

  it('last timeframe item refers to 5th week from current month', () => {
    const timeframeItem = timeframe[timeframe.length - 1];
    const expectedMonth = {
      year: 2018,
      month: 0,
      date: 28,
    };

    expect(timeframeItem.getFullYear()).toBe(expectedMonth.year);
    expect(timeframeItem.getMonth()).toBe(expectedMonth.month);
    expect(timeframeItem.getDate()).toBe(expectedMonth.date);
  });
});

describe('getEpicsPathForPreset', () => {
  const basePath = '/groups/gitlab-org/-/epics.json';
  const filterQueryString = 'scope=all&utf8=✓&state=opened&label_name[]=Bug';

  it('returns epics path string based on provided basePath and timeframe for Quarters', () => {
    const timeframeQuarters = getTimeframeForQuartersView(new Date(2018, 0, 1));
    const epicsPath = getEpicsPathForPreset({
      basePath,
      timeframe: timeframeQuarters,
      presetType: PRESET_TYPES.QUARTERS,
    });

    expect(epicsPath).toBe(`${basePath}?start_date=2017-10-1&end_date=2019-3-31`);
  });

  it('returns epics path string based on provided basePath and timeframe for Months', () => {
    const timeframeMonths = getTimeframeForMonthsView(new Date(2018, 0, 1));
    const epicsPath = getEpicsPathForPreset({
      basePath,
      timeframe: timeframeMonths,
      presetType: PRESET_TYPES.MONTHS,
    });

    expect(epicsPath).toBe(`${basePath}?start_date=2017-12-1&end_date=2018-6-30`);
  });

  it('returns epics path string based on provided basePath and timeframe for Weeks', () => {
    const timeframeWeeks = getTimeframeForWeeksView(new Date(2018, 0, 1));
    const epicsPath = getEpicsPathForPreset({
      basePath,
      timeframe: timeframeWeeks,
      presetType: PRESET_TYPES.WEEKS,
    });

    expect(epicsPath).toBe(`${basePath}?start_date=2017-12-24&end_date=2018-2-3`);
  });

  it('returns epics path string while preserving filterQueryString', () => {
    const timeframeMonths = getTimeframeForMonthsView(new Date(2018, 0, 1));
    const epicsPath = getEpicsPathForPreset({
      basePath,
      filterQueryString,
      timeframe: timeframeMonths,
      presetType: PRESET_TYPES.MONTHS,
    });

    expect(epicsPath).toBe(
      `${basePath}?start_date=2017-12-1&end_date=2018-6-30&scope=all&utf8=✓&state=opened&label_name[]=Bug`,
    );
  });
});
