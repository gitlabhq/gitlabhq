import Vue from 'vue';
import MonitoringState from '~/monitoring/components/monitoring_state.vue';
import { statePaths } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringState);

  return new Component({
    propsData,
  });
};

function getTextFromNode(component, selector) {
  return component.$el.querySelector(selector).firstChild.nodeValue.trim();
}

describe('MonitoringState', () => {
  describe('Computed props', () => {
    it('getCurrentState', () => {
      const component = createComponent({
        selectedState: 'gettingStarted',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
      });

      expect(component.getCurrentState).toBe(component.states.gettingStarted);
    });

    it('getButtonPath returns settings path for the state "gettingStarted"', () => {
      const component = createComponent({
        selectedState: 'gettingStarted',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
      });

      expect(component.getButtonPath).toEqual(statePaths.settingsPath);
      expect(component.getButtonPath).not.toEqual(statePaths.documentationPath);
    });

    it('getButtonPath returns documentation path for any of the other states', () => {
      const component = createComponent({
        selectedState: 'loading',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
      });

      expect(component.getButtonPath).toEqual(statePaths.documentationPath);
      expect(component.getButtonPath).not.toEqual(statePaths.settingsPath);
    });

    it('getDescription returns a description with a link for the unableToConnect state', () => {
      const component = createComponent({
        selectedState: 'unableToConnect',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
      });

      expect(component.getDescriptionText.indexOf('<a')).not.toEqual(-1);
      expect(component.getDescriptionText.indexOf(component.getCurrentState.description))
            .not.toEqual(-1);
    });

    it('getDescription returns the description without a link for any other state', () => {
      const component = createComponent({
        selectedState: 'loading',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
      });

      expect(component.getDescriptionText.indexOf('<a')).toEqual(-1);
      expect(component.getDescriptionText).toEqual(component.getCurrentState.description);
    });
  });

  it('should show the gettingStarted state', () => {
    const component = createComponent({
      selectedState: 'gettingStarted',
      settingsPath: statePaths.settingsPath,
      documentationPath: statePaths.documentationPath,
    });

    component.$mount();
    expect(component.$el.querySelector('svg')).toBeDefined();
    expect(getTextFromNode(component, '.state-title')).toEqual(component.states.gettingStarted.title);
    expect(getTextFromNode(component, '.state-description')).toEqual(component.states.gettingStarted.description);
    expect(getTextFromNode(component, '.btn-success')).toEqual(component.states.gettingStarted.buttonText);
  });

  it('should show the loading state', () => {
    const component = createComponent({
      selectedState: 'loading',
      settingsPath: statePaths.settingsPath,
      documentationPath: statePaths.documentationPath,
    });

    component.$mount();
    expect(component.$el.querySelector('svg')).toBeDefined();
    expect(getTextFromNode(component, '.state-title')).toEqual(component.states.loading.title);
    expect(getTextFromNode(component, '.state-description')).toEqual(component.states.loading.description);
    expect(getTextFromNode(component, '.btn-success')).toEqual(component.states.loading.buttonText);
  });

  it('should show the unableToConnect state', () => {
    const component = createComponent({
      selectedState: 'unableToConnect',
      settingsPath: statePaths.settingsPath,
      documentationPath: statePaths.documentationPath,
    });

    component.$mount();
    expect(component.$el.querySelector('svg')).toBeDefined();
    expect(getTextFromNode(component, '.state-title')).toEqual(component.states.unableToConnect.title);
    expect(component.$el.querySelector('.state-description a')).toBeDefined();
    expect(getTextFromNode(component, '.btn-success')).toEqual(component.states.unableToConnect.buttonText);
  });
});
