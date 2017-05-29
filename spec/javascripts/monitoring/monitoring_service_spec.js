import Vue from 'vue';
import MonitoringService from '~/monitoring/services/monitoring_service';
import { MonitorMockInterceptor } from './mock_data';

describe('Monitoring Service', () => {
  beforeEach(() => {
    Vue.http.interceptors.push(MonitorMockInterceptor);
    this.service = new MonitoringService('/root/hello-prometheus/environments/30/additional_metrics.json');
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, MonitorMockInterceptor);
  });

  it('gets the data', (done) => {
    this.service.get().then((resp) => {
      expect(resp).toBeDefined();
      done();
    }).catch(() => {});
  });
});
