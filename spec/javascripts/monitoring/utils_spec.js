import { getTimeDiff } from '~/monitoring/utils';
import { timeWindows } from '~/monitoring/constants';

describe('getTimeDiff', () => {
  it('defaults to an 8 hour (28800s) difference', () => {
    const params = getTimeDiff();

    expect(params.end - params.start).toEqual(28800);
  });

  it('accepts time window as an argument', () => {
    const params = getTimeDiff(timeWindows.thirtyMinutes);

    expect(params.end - params.start).not.toEqual(28800);
  });

  it('returns a value for every defined time window', () => {
    const nonDefaultWindows = Object.keys(timeWindows).filter(window => window !== 'eightHours');

    nonDefaultWindows.forEach(window => {
      const params = getTimeDiff(timeWindows[window]);
      const diff = params.end - params.start;

      // Ensure we're not returning the default, 28800 (the # of seconds in 8 hrs)
      expect(diff).not.toEqual(28800);
      expect(typeof diff).toEqual('number');
    });
  });
});
