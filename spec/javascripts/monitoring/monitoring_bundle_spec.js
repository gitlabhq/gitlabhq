import Vue from 'vue';
import MonitoringStore from '~/monitoring/stores/monitoring_store';
import '~/monitoring/monitoring_bundle';
import { MonitorMockInterceptor } from './mock_data';

describe('Monitoring Bundle', () => {
  const fixtureName = 'environments/metrics/metrics.html.raw';
  preloadFixtures(fixtureName);
  beforeEach(() => {
    loadFixtures(fixtureName);
    Vue.http.interceptors.push(MonitorMockInterceptor);
  });

  afterEach(() => {
    MonitoringStore.singleton = null;
    Vue.http.interceptors = _.without(Vue.http.interceptors, MonitorMockInterceptor);
  });

  it('does something as expected', () => {
    const domContentLoadedEvent = document.createEvent('Event');
    domContentLoadedEvent.initEvent('DOMContentLoaded', true, true);
    window.document.dispatchEvent(domContentLoadedEvent);

    // Test against the machine
  });
});
