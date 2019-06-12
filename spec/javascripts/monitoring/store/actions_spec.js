import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import store from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import {
  fetchDashboard,
  receiveMetricsDashboardSuccess,
  receiveMetricsDashboardFailure,
  fetchDeploymentsData,
  fetchEnvironmentsData,
  fetchPrometheusMetrics,
  fetchPrometheusMetric,
  requestMetricsData,
  setEndpoints,
  setGettingStartedEmptyState,
} from '~/monitoring/stores/actions';
import storeState from '~/monitoring/stores/state';
import testAction from 'spec/helpers/vuex_action_helper';
import { resetStore } from '../helpers';
import {
  deploymentData,
  environmentData,
  metricsDashboardResponse,
  metricsGroupsAPIResponse,
} from '../mock_data';

describe('Monitoring store actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    resetStore(store);
    mock.restore();
  });

  describe('requestMetricsData', () => {
    it('sets emptyState to loading', () => {
      const commit = jasmine.createSpy();
      const { state } = store;

      requestMetricsData({ state, commit });

      expect(commit).toHaveBeenCalledWith(types.REQUEST_METRICS_DATA);
    });
  });

  describe('fetchDeploymentsData', () => {
    it('commits RECEIVE_DEPLOYMENTS_DATA_SUCCESS on error', done => {
      const dispatch = jasmine.createSpy();
      const { state } = store;
      state.deploymentEndpoint = '/success';

      mock.onGet(state.deploymentEndpoint).reply(200, {
        deployments: deploymentData,
      });

      fetchDeploymentsData({ state, dispatch })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveDeploymentsDataSuccess', deploymentData);
          done();
        })
        .catch(done.fail);
    });

    it('commits RECEIVE_DEPLOYMENTS_DATA_FAILURE on error', done => {
      const dispatch = jasmine.createSpy();
      const { state } = store;
      state.deploymentEndpoint = '/error';

      mock.onGet(state.deploymentEndpoint).reply(500);

      fetchDeploymentsData({ state, dispatch })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveDeploymentsDataFailure');
          done();
        })
        .catch(done.fail);
    });
  });

  describe('fetchEnvironmentsData', () => {
    it('commits RECEIVE_ENVIRONMENTS_DATA_SUCCESS on error', done => {
      const dispatch = jasmine.createSpy();
      const { state } = store;
      state.environmentsEndpoint = '/success';

      mock.onGet(state.environmentsEndpoint).reply(200, {
        environments: environmentData,
      });

      fetchEnvironmentsData({ state, dispatch })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveEnvironmentsDataSuccess', environmentData);
          done();
        })
        .catch(done.fail);
    });

    it('commits RECEIVE_ENVIRONMENTS_DATA_FAILURE on error', done => {
      const dispatch = jasmine.createSpy();
      const { state } = store;
      state.environmentsEndpoint = '/error';

      mock.onGet(state.environmentsEndpoint).reply(500);

      fetchEnvironmentsData({ state, dispatch })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveEnvironmentsDataFailure');
          done();
        })
        .catch(done.fail);
    });
  });

  describe('Set endpoints', () => {
    let mockedState;

    beforeEach(() => {
      mockedState = storeState();
    });

    it('should commit SET_ENDPOINTS mutation', done => {
      testAction(
        setEndpoints,
        {
          metricsEndpoint: 'additional_metrics.json',
          deploymentsEndpoint: 'deployments.json',
          environmentsEndpoint: 'deployments.json',
        },
        mockedState,
        [
          {
            type: types.SET_ENDPOINTS,
            payload: {
              metricsEndpoint: 'additional_metrics.json',
              deploymentsEndpoint: 'deployments.json',
              environmentsEndpoint: 'deployments.json',
            },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('Set empty states', () => {
    let mockedState;

    beforeEach(() => {
      mockedState = storeState();
    });

    it('should commit SET_METRICS_ENDPOINT mutation', done => {
      testAction(
        setGettingStartedEmptyState,
        null,
        mockedState,
        [{ type: types.SET_GETTING_STARTED_EMPTY_STATE }],
        [],
        done,
      );
    });
  });

  describe('fetchDashboard', () => {
    let dispatch;
    let state;
    const response = metricsDashboardResponse;

    beforeEach(() => {
      dispatch = jasmine.createSpy();
      state = storeState();
      state.dashboardEndpoint = '/dashboard';
    });

    it('dispatches receive and success actions', done => {
      const params = {};
      mock.onGet(state.dashboardEndpoint).reply(200, response);

      fetchDashboard({ state, dispatch }, params)
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('requestMetricsDashboard');
          expect(dispatch).toHaveBeenCalledWith('receiveMetricsDashboardSuccess', {
            response,
            params,
          });
          done();
        })
        .catch(done.fail);
    });

    it('dispatches failure action', done => {
      const params = {};
      mock.onGet(state.dashboardEndpoint).reply(500);

      fetchDashboard({ state, dispatch }, params)
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith(
            'receiveMetricsDashboardFailure',
            new Error('Request failed with status code 500'),
          );
          done();
        })
        .catch(done.fail);
    });
  });

  describe('receiveMetricsDashboardSuccess', () => {
    let commit;
    let dispatch;

    beforeEach(() => {
      commit = jasmine.createSpy();
      dispatch = jasmine.createSpy();
    });

    it('stores groups ', () => {
      const params = {};
      const response = metricsDashboardResponse;

      receiveMetricsDashboardSuccess({ commit, dispatch }, { response, params });

      expect(commit).toHaveBeenCalledWith(
        types.RECEIVE_METRICS_DATA_SUCCESS,
        metricsDashboardResponse.dashboard.panel_groups,
      );

      expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetrics', params);
    });
  });

  describe('receiveMetricsDashboardFailure', () => {
    let commit;

    beforeEach(() => {
      commit = jasmine.createSpy();
    });

    it('commits failure action', () => {
      receiveMetricsDashboardFailure({ commit });

      expect(commit).toHaveBeenCalledWith(types.RECEIVE_METRICS_DATA_FAILURE, undefined);
    });

    it('commits failure action with error', () => {
      receiveMetricsDashboardFailure({ commit }, 'uh-oh');

      expect(commit).toHaveBeenCalledWith(types.RECEIVE_METRICS_DATA_FAILURE, 'uh-oh');
    });
  });

  describe('fetchPrometheusMetrics', () => {
    let commit;
    let dispatch;

    beforeEach(() => {
      commit = jasmine.createSpy();
      dispatch = jasmine.createSpy();
    });

    it('commits empty state when state.groups is empty', done => {
      const state = storeState();
      const params = {};

      fetchPrometheusMetrics({ state, commit, dispatch }, params)
        .then(() => {
          expect(commit).toHaveBeenCalledWith(types.SET_NO_DATA_EMPTY_STATE);
          expect(dispatch).not.toHaveBeenCalled();
          done();
        })
        .catch(done.fail);
    });

    it('dispatches fetchPrometheusMetric for each panel query', done => {
      const params = {};
      const state = storeState();
      state.groups = metricsDashboardResponse.dashboard.panel_groups;

      const metric = state.groups[0].panels[0].metrics[0];

      fetchPrometheusMetrics({ state, commit, dispatch }, params)
        .then(() => {
          expect(dispatch.calls.count()).toEqual(3);
          expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', { metric, params });
          done();
        })
        .catch(done.fail);

      done();
    });
  });

  describe('fetchPrometheusMetric', () => {
    it('commits prometheus query result', done => {
      const commit = jasmine.createSpy();
      const params = {
        start: '1557216349.469',
        end: '1557218149.469',
      };
      const metric = metricsDashboardResponse.dashboard.panel_groups[0].panels[0].metrics[0];
      const state = storeState();

      const data = metricsGroupsAPIResponse.data[0].metrics[0].queries[0];
      const response = { data };
      mock.onGet('http://test').reply(200, response);

      fetchPrometheusMetric({ state, commit }, { metric, params });

      setTimeout(() => {
        expect(commit).toHaveBeenCalledWith(types.SET_QUERY_RESULT, {
          metricId: metric.metric_id,
          result: data.result,
        });
        done();
      });
    });
  });
});
