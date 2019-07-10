import { getTimeDiff, graphDataValidatorForValues } from '~/monitoring/utils';
import { timeWindows } from '~/monitoring/constants';
import { graphDataPrometheusQuery, graphDataPrometheusQueryRange } from './mock_data';

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
