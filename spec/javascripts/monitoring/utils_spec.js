import {
  getTimeDiff,
  getTimeWindow,
  graphDataValidatorForValues,
  isDateTimePickerInputValid,
  truncateZerosInDateTime,
  stringToISODate,
  ISODateToString,
  isValidDate,
  graphDataValidatorForAnomalyValues,
} from '~/monitoring/utils';
import { timeWindows, timeWindowsKeyNames } from '~/monitoring/constants';
import {
  graphDataPrometheusQuery,
  graphDataPrometheusQueryRange,
  anomalyMockGraphData,
} from './mock_data';

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
      expected: null,
    },
    {
      args: [
        {
          start: '',
          end: '',
        },
      ],
      expected: null,
    },
    {
      args: [
        {
          start: null,
          end: null,
        },
      ],
      expected: null,
    },
    {
      args: [{}],
      expected: null,
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

describe('stringToISODate', () => {
  ['', 'null', undefined, 'abc'].forEach(input => {
    it(`throws error for invalid input like ${input}`, done => {
      try {
        stringToISODate(input);
      } catch (e) {
        expect(e).toBeDefined();
        done();
      }
    });
  });
  [
    {
      input: '2019-09-09 01:01:01',
      output: '2019-09-09T01:01:01Z',
    },
    {
      input: '2019-09-09 00:00:00',
      output: '2019-09-09T00:00:00Z',
    },
    {
      input: '2019-09-09 23:59:59',
      output: '2019-09-09T23:59:59Z',
    },
    {
      input: '2019-09-09',
      output: '2019-09-09T00:00:00Z',
    },
  ].forEach(({ input, output }) => {
    it(`returns ${output} from ${input}`, () => {
      expect(stringToISODate(input)).toBe(output);
    });
  });
});

describe('ISODateToString', () => {
  [
    {
      input: new Date('2019-09-09T00:00:00.000Z'),
      output: '2019-09-09 00:00:00',
    },
    {
      input: new Date('2019-09-09T07:00:00.000Z'),
      output: '2019-09-09 07:00:00',
    },
  ].forEach(({ input, output }) => {
    it(`ISODateToString return ${output} for ${input}`, () => {
      expect(ISODateToString(input)).toBe(output);
    });
  });
});

describe('truncateZerosInDateTime', () => {
  [
    {
      input: '',
      output: '',
    },
    {
      input: '2019-10-10',
      output: '2019-10-10',
    },
    {
      input: '2019-10-10 00:00:01',
      output: '2019-10-10 00:00:01',
    },
    {
      input: '2019-10-10 00:00:00',
      output: '2019-10-10',
    },
  ].forEach(({ input, output }) => {
    it(`truncateZerosInDateTime return ${output} for ${input}`, () => {
      expect(truncateZerosInDateTime(input)).toBe(output);
    });
  });
});

describe('isValidDate', () => {
  [
    {
      input: '2019-09-09T00:00:00.000Z',
      output: true,
    },
    {
      input: '2019-09-09T000:00.000Z',
      output: false,
    },
    {
      input: 'a2019-09-09T000:00.000Z',
      output: false,
    },
    {
      input: '2019-09-09T',
      output: false,
    },
    {
      input: '2019-09-09',
      output: true,
    },
    {
      input: '2019-9-9',
      output: true,
    },
    {
      input: '2019-9-',
      output: true,
    },
    {
      input: '2019--',
      output: false,
    },
    {
      input: '2019',
      output: true,
    },
    {
      input: '',
      output: false,
    },
    {
      input: null,
      output: false,
    },
  ].forEach(({ input, output }) => {
    it(`isValidDate return ${output} for ${input}`, () => {
      expect(isValidDate(input)).toBe(output);
    });
  });
});

describe('isDateTimePickerInputValid', () => {
  [
    {
      input: null,
      output: false,
    },
    {
      input: '',
      output: false,
    },
    {
      input: 'xxxx-xx-xx',
      output: false,
    },
    {
      input: '9999-99-19',
      output: false,
    },
    {
      input: '2019-19-23',
      output: false,
    },
    {
      input: '2019-09-23',
      output: true,
    },
    {
      input: '2019-09-23 x',
      output: false,
    },
    {
      input: '2019-09-29 0:0:0',
      output: false,
    },
    {
      input: '2019-09-29 00:00:00',
      output: true,
    },
    {
      input: '2019-09-29 24:24:24',
      output: false,
    },
    {
      input: '2019-09-29 23:24:24',
      output: true,
    },
    {
      input: '2019-09-29 23:24:24 ',
      output: false,
    },
  ].forEach(({ input, output }) => {
    it(`returns ${output} for ${input}`, () => {
      expect(isDateTimePickerInputValid(input)).toBe(output);
    });
  });
});

describe('graphDataValidatorForAnomalyValues', () => {
  let oneMetric;
  let threeMetrics;
  let fourMetrics;
  beforeEach(() => {
    oneMetric = graphDataPrometheusQuery;
    threeMetrics = anomalyMockGraphData;

    const metrics = [...threeMetrics.metrics];
    metrics.push(threeMetrics.metrics[0]);
    fourMetrics = {
      ...anomalyMockGraphData,
      metrics,
    };
  });
  /*
   * Anomaly charts can accept results for exactly 3 metrics,
   */
  it('validates passes with the right query format', () => {
    expect(graphDataValidatorForAnomalyValues(threeMetrics)).toBe(true);
  });

  it('validation fails for wrong format, 1 metric', () => {
    expect(graphDataValidatorForAnomalyValues(oneMetric)).toBe(false);
  });

  it('validation fails for wrong format, more than 3 metrics', () => {
    expect(graphDataValidatorForAnomalyValues(fourMetrics)).toBe(false);
  });
});
