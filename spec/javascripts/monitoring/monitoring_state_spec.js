import Vue from 'vue';
import MonitoringState from '~/monitoring/components/monitoring_state.vue';
import gettingStartedSvg from 'empty_states/monitoring/_getting_started.svg';
import loadingSvg from 'empty_states/monitoring/_loading.svg';
import unableToConnectSvg from 'empty_states/monitoring/_unable_to_connect.svg';

describe('MonitoringState component', () => {
  let component;
  let MonitoringStateComponent;

  beforeEach(() => {
    MonitoringStateComponent = Vue.extend(MonitoringState);
  });

  it('should show the getting started state', () => {
    component = new MonitoringStateComponent({
      propsData: {
        gettingStarted: true,
        unableToConnect: false,
        isLoading: false,
      },
    }).$mount();

    expect(component.gettingStarted).toEqual(true);
    expect(component.unableToConnect).toEqual(false);
    expect(component.isLoading).toEqual(false);
    expect(component.displayCorrespondentSvg).toBe(gettingStartedSvg);
    // TODO: Add the expectations for the state-titles
  });

  it('should show the getting started state', () => {
    component = new MonitoringStateComponent({
      propsData: {
        gettingStarted: false,
        unableToConnect: true,
        isLoading: false,
      },
    }).$mount();

    expect(component.gettingStarted).toEqual(false);
    expect(component.unableToConnect).toEqual(true);
    expect(component.isLoading).toEqual(false);
    expect(component.displayCorrespondentSvg).toBe(unableToConnectSvg);
    // TODO: Add the expectations for the state-titles
  });

  it('should show the getting started state', () => {
    component = new MonitoringStateComponent({
      propsData: {
        gettingStarted: false,
        unableToConnect: false,
        isLoading: true,
      },
    }).$mount();

    expect(component.gettingStarted).toEqual(false);
    expect(component.unableToConnect).toEqual(false);
    expect(component.isLoading).toEqual(true);
    expect(component.displayCorrespondentSvg).toBe(loadingSvg);
    // TODO: Add the expectations for the state-titles
  });
});
