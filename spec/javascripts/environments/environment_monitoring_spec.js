import Vue from 'vue';
import monitoringComp from '~/environments/components/environment_monitoring.vue';

describe('Monitoring Component', () => {
  let MonitoringComponent;
  let component;

  const monitoringUrl = 'https://gitlab.com';

  beforeEach(() => {
    MonitoringComponent = Vue.extend(monitoringComp);

    component = new MonitoringComponent({
      propsData: {
        monitoringUrl,
      },
    }).$mount();
  });

  describe('computed', () => {
    it('title', () => {
      expect(component.title).toEqual('Monitoring');
    });
  });

  it('should render a link to environment monitoring page', () => {
    expect(component.$el.getAttribute('href')).toEqual(monitoringUrl);
    expect(component.$el.querySelector('.fa-area-chart')).toBeDefined();
    expect(component.$el.getAttribute('data-original-title')).toEqual('Monitoring');
    expect(component.$el.getAttribute('aria-label')).toEqual('Monitoring');
  });
});
