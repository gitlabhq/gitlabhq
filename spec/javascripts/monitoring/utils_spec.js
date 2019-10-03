import { getTimeDiff, getTimeWindow, graphDataValidatorForValues } from '~/monitoring/utils';
import { timeWindows, timeWindowsKeyNames } from '~/monitoring/constants';
import { graphDataPrometheusQuery, graphDataPrometheusQueryRange } from './mock_data';

describe('getTimeDiff', () => {
  function secondsBetween({ start, end }) {
    return (new Date(end) - new Date(start)) / 1000;
  }

  function minutesBetween(timeRange) {
    return secondsBetween(timeRange) / 60;
  }

  function hoursBetween(timeRange) {
    return minutesBetween(timeRange) / 60;
  }

  it('defaults to an 8 hour (28800s) difference', () => {
    const params = getTimeDiff();

    expect(hoursBetween(params)).toEqual(8);
  });

  it('accepts time window as an argument', () => {
    const params = getTimeDiff('thirtyMinutes');

    expect(minutesBetween(params)).toEqual(30);
  });

  it('returns a value for every defined time window', () => {
    const nonDefaultWindows = Object.keys(timeWindows).filter(window => window !== 'eightHours');

    nonDefaultWindows.forEach(timeWindow => {
      const params = getTimeDiff(timeWindow);

      // Ensure we're not returning the default
      expect(hoursBetween(params)).not.toEqual(8);
    });
  });
});

describe('getTimeWindow', () => {
  [
    {
      args: [
        {
          start: '2019-10-01T18:27:47.000Z',
          end: '2019-10-01T21:27:47.000Z',
        },
      ],
      expected: timeWindowsKeyNames.threeHours,
    },
    {
      args: [
        {
          start: '2019-10-01T28:27:47.000Z',
          end: '2019-10-01T21:27:47.000Z',
        },
      ],
      expected: timeWindowsKeyNames.eightHours,
    },
    {
      args: [
        {
          start: '',
          end: '',
        },
      ],
      expected: timeWindowsKeyNames.eightHours,
    },
    {
      args: [
        {
          start: null,
          end: null,
        },
      ],
      expected: timeWindowsKeyNames.eightHours,
    },
    {
      args: [{}],
      expected: timeWindowsKeyNames.eightHours,
    },
  ].forEach(({ args, expected }) => {
    it(`returns "${expected}" with args=${JSON.stringify(args)}`, () => {
      expect(getTimeWindow(...args)).toEqual(expected);
    });
  });
});

describe('graphDataValidatorForValues', () => {
  /*
   * When dealing with a metric using the query format, e.g.
   * query: 'max(go_memstats_alloc_bytes{job="prometheus"}) by (job) /1024/1024'
   * the validator will look for the `value` key instead of `values`
   */
  it('validates data with the query format', () => {
    const validGraphData = graphDataValidatorForValues(true, graphDataPrometheusQuery);

    expect(validGraphData).toBe(true);
  });

  /*
   * When dealing with a metric using the query?range format, e.g.
   * query_range: 'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job)  /1024/1024/1024',
   * the validator will look for the `values` key instead of `value`
   */
  it('validates data with the query_range format', () => {
    const validGraphData = graphDataValidatorForValues(false, graphDataPrometheusQueryRange);

    expect(validGraphData).toBe(true);
  });
});
