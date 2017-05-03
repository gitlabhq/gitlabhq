import Vue from 'vue';
import monitoringComp from '~/environments/components/environment_monitoring.vue';

describe('Monitoring Component', () => {
  let MonitoringComponent;

  beforeEach(() => {
    MonitoringComponent = Vue.extend(monitoringComp);
  });

  it('should render a link to environment monitoring page', () => {
    const monitoringUrl = 'https://gitlab.com';
    const component = new MonitoringComponent({
      propsData: {
        monitoringUrl,
      },
    }).$mount();

    expect(component.$el.getAttribute('href')).toEqual(monitoringUrl);
    expect(component.$el.querySelector('.fa-area-chart')).toBeDefined();
    expect(component.$el.getAttribute('title')).toEqual('Monitoring');
  });
});
