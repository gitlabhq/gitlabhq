import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import PrometheusMetrics from '~/prometheus_metrics/prometheus_metrics';
import PANEL_STATE from '~/prometheus_metrics/constants';
import { metrics, missingVarMetrics } from './mock_data';

describe('PrometheusMetrics', () => {
  const FIXTURE = 'services/prometheus/prometheus_service.html.raw';
  preloadFixtures(FIXTURE);

  beforeEach(() => {
    loadFixtures(FIXTURE);
  });

  describe('constructor', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should initialize wrapper element refs on class object', () => {
      expect(prometheusMetrics.$wrapper).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsPanel).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsCount).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsLoading).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsEmpty).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsList).toBeDefined();
      expect(prometheusMetrics.$missingEnvVarPanel).toBeDefined();
      expect(prometheusMetrics.$panelToggle).toBeDefined();
      expect(prometheusMetrics.$missingEnvVarMetricCount).toBeDefined();
      expect(prometheusMetrics.$missingEnvVarMetricsList).toBeDefined();
    });

    it('should initialize metadata on class object', () => {
      expect(prometheusMetrics.backOffRequestCounter).toEqual(0);
      expect(prometheusMetrics.activeMetricsEndpoint).toContain('/test');
    });
  });

  describe('showMonitoringMetricsPanelState', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should show loading state when called with `loading`', () => {
      prometheusMetrics.showMonitoringMetricsPanelState(PANEL_STATE.LOADING);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeFalsy();
      expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBeTruthy();
    });

    it('should show metrics list when called with `list`', () => {
      prometheusMetrics.showMonitoringMetricsPanelState(PANEL_STATE.LIST);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBeFalsy();
    });

    it('should show empty state when called with `empty`', () => {
      prometheusMetrics.showMonitoringMetricsPanelState(PANEL_STATE.EMPTY);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBeFalsy();
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBeTruthy();
    });
  });

  describe('populateActiveMetrics', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should show monitored metrics list', () => {
      prometheusMetrics.populateActiveMetrics(metrics);

      const $metricsListLi = prometheusMetrics.$monitoredMetricsList.find('li');

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBeFalsy();

      expect(prometheusMetrics.$monitoredMetricsCount.text()).toEqual('3 exporters with 12 metrics were found');
      expect($metricsListLi.length).toEqual(metrics.length);
      expect($metricsListLi.first().find('.badge').text()).toEqual(`${metrics[0].active_metrics}`);
    });

    it('should show missing environment variables list', () => {
      prometheusMetrics.populateActiveMetrics(missingVarMetrics);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$missingEnvVarPanel.hasClass('hidden')).toBeFalsy();

      expect(prometheusMetrics.$missingEnvVarMetricCount.text()).toEqual('2');
      expect(prometheusMetrics.$missingEnvVarPanel.find('li').length).toEqual(2);
      expect(prometheusMetrics.$missingEnvVarPanel.find('.flash-container')).toBeDefined();
    });
  });

  describe('loadActiveMetrics', () => {
    let prometheusMetrics;
    let mock;

    function mockSuccess() {
      mock.onGet(prometheusMetrics.activeMetricsEndpoint).reply(200, {
        data: metrics,
        success: true,
      });
    }

    function mockError() {
      mock.onGet(prometheusMetrics.activeMetricsEndpoint).networkError();
    }

    beforeEach(() => {
      spyOn(axios, 'get').and.callThrough();

      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');

      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should show loader animation while response is being loaded and hide it when request is complete', (done) => {
      mockSuccess();

      prometheusMetrics.loadActiveMetrics();

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeFalsy();
      expect(axios.get).toHaveBeenCalledWith(prometheusMetrics.activeMetricsEndpoint);

      setTimeout(() => {
        expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeTruthy();
        done();
      });
    });

    it('should show empty state if response failed to load', (done) => {
      mockError();

      prometheusMetrics.loadActiveMetrics();

      setTimeout(() => {
        expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBeTruthy();
        expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBeFalsy();
        done();
      });
    });

    it('should populate metrics list once response is loaded', (done) => {
      spyOn(prometheusMetrics, 'populateActiveMetrics');
      mockSuccess();

      prometheusMetrics.loadActiveMetrics();

      setTimeout(() => {
        expect(prometheusMetrics.populateActiveMetrics).toHaveBeenCalledWith(metrics);
        done();
      });
    });
  });
});
