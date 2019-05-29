import mutations from '~/monitoring/stores/mutations';
import * as types from '~/monitoring/stores/mutation_types';
import state from '~/monitoring/stores/state';
import { metricsGroupsAPIResponse, deploymentData } from '../mock_data';

describe('Monitoring mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe(types.RECEIVE_METRICS_DATA_SUCCESS, () => {
    beforeEach(() => {
      stateCopy.groups = [];
      const groups = metricsGroupsAPIResponse.data;

      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, groups);
    });

    it('normalizes values', () => {
      const expectedTimestamp = '2017-05-25T08:22:34.925Z';
      const expectedValue = 0.0010794445585559514;
      const [timestamp, value] = stateCopy.groups[0].metrics[0].queries[0].result[0].values[0];

      expect(timestamp).toEqual(expectedTimestamp);
      expect(value).toEqual(expectedValue);
    });

    it('contains two groups that contains, one of which has two queries sorted by priority', () => {
      expect(stateCopy.groups).toBeDefined();
      expect(stateCopy.groups.length).toEqual(2);
      expect(stateCopy.groups[0].metrics.length).toEqual(2);
    });

    it('assigns queries a metric id', () => {
      expect(stateCopy.groups[1].metrics[0].queries[0].metricId).toEqual('100');
    });

    it('removes the data if all the values from a query are not defined', () => {
      expect(stateCopy.groups[1].metrics[0].queries[0].result.length).toEqual(0);
    });

    it('assigns metric id of null if metric has no id', () => {
      stateCopy.groups = [];
      const groups = metricsGroupsAPIResponse.data;
      const noId = groups.map(group => ({
        ...group,
        ...{
          metrics: group.metrics.map(metric => {
            const { id, ...metricWithoutId } = metric;

            return metricWithoutId;
          }),
        },
      }));

      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, noId);

      stateCopy.groups.forEach(group => {
        group.metrics.forEach(metric => {
          expect(metric.queries.every(query => query.metricId === null)).toBe(true);
        });
      });
    });
  });

  describe(types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS, () => {
    it('stores the deployment data', () => {
      stateCopy.deploymentData = [];
      mutations[types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS](stateCopy, deploymentData);

      expect(stateCopy.deploymentData).toBeDefined();
      expect(stateCopy.deploymentData.length).toEqual(3);
      expect(typeof stateCopy.deploymentData[0]).toEqual('object');
    });
  });

  describe('SET_ENDPOINTS', () => {
    it('should set all the endpoints', () => {
      mutations[types.SET_ENDPOINTS](stateCopy, {
        metricsEndpoint: 'additional_metrics.json',
        environmentsEndpoint: 'environments.json',
        deploymentsEndpoint: 'deployments.json',
      });

      expect(stateCopy.metricsEndpoint).toEqual('additional_metrics.json');
      expect(stateCopy.environmentsEndpoint).toEqual('environments.json');
      expect(stateCopy.deploymentsEndpoint).toEqual('deployments.json');
    });
  });
});
