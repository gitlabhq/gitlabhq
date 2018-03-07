import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import PrometheusMetrics from 'ee/prometheus_metrics/prometheus_metrics';
import PANEL_STATE from '~/prometheus_metrics/constants';
import metrics from './mock_data';

describe('PrometheusMetrics EE', () => {
  const FIXTURE = 'services/prometheus/prometheus_service.html.raw';
  const customMetricsEndpoint = 'http://test.host/frontend-fixtures/services-project/prometheus/metrics';
  let mock;
  preloadFixtures(FIXTURE);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(customMetricsEndpoint).reply(200, {
      metrics,
    });
    loadFixtures(FIXTURE);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('Custom Metrics EE', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should initialize wrapper element refs on the class object', () => {
      expect(prometheusMetrics.$wrapperCustomMetrics).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsPanel).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsCount).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsLoading).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsList).not.toBeNull();
      expect(prometheusMetrics.$newCustomMetricButton).not.toBeNull();
      expect(prometheusMetrics.$flashCustomMetricsContainer).not.toBeNull();
    });

    it('should contain api endpoints', () => {
      expect(prometheusMetrics.activeCustomMetricsEndpoint).toEqual(customMetricsEndpoint);
    });

    it('should show loading state when called with `loading`', () => {
      prometheusMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.LOADING);

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBeTruthy();
    });

    it('should show metrics list when called with `list`', () => {
      prometheusMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.LIST);

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toEqual(false);
    });

    it('should show empty state when called with `empty`', () => {
      prometheusMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBeTruthy();
    });

    it('should show monitored metrics list', () => {
      prometheusMetrics.customMetrics = metrics;
      prometheusMetrics.populateCustomMetrics();

      const $metricsListLi = prometheusMetrics.$monitoredCustomMetricsList.find('li');

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toEqual(false);

      expect($metricsListLi.length).toEqual(metrics.length);
    });
  });
});
