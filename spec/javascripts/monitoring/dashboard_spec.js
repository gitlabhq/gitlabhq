import Vue from 'vue';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { MonitorMockInterceptor } from './mock_data';

describe('Dashboard', () => {
  const fixtureName = 'environments/metrics/metrics.html.raw';
  let DashboardComponent;
  let component;
  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    DashboardComponent = Vue.extend(Dashboard);
  });

  describe('no metrics are available yet', () => {
    it('shows a getting started empty state when no metrics are present', () => {
      component = new DashboardComponent({
        el: document.querySelector('#prometheus-graphs'),
      });

      component.$mount();
      expect(component.$el.querySelector('#prometheus-graphs')).toBe(null);
      expect(component.state).toEqual('gettingStarted');
    });
  });

  describe('requests information to the server', () => {
    beforeEach(() => {
      document.querySelector('#prometheus-graphs').setAttribute('data-has-metrics', 'true');
      Vue.http.interceptors.push(MonitorMockInterceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, MonitorMockInterceptor);
    });

    it('shows up a loading state', (done) => {
      component = new DashboardComponent({
        el: document.querySelector('#prometheus-graphs'),
      });
      component.$mount();
      Vue.nextTick(() => {
        expect(component.state).toEqual('loading');
        done();
      });
    });
  });
});
