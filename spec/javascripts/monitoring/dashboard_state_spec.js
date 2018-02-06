import Vue from 'vue';
import EmptyState from '~/monitoring/components/empty_state.vue';
import { statePaths } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(EmptyState);

  return new Component({
    propsData,
  }).$mount();
};

function getTextFromNode(component, selector) {
  return component.$el.querySelector(selector).firstChild.nodeValue.trim();
}

describe('EmptyState', () => {
  describe('Computed props', () => {
    it('currentState', () => {
      const component = createComponent({
        selectedState: 'gettingStarted',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
        emptyGettingStartedSvgPath: 'foo',
        emptyLoadingSvgPath: 'foo',
        emptyUnableToConnectSvgPath: 'foo',
      });

      expect(component.currentState).toBe(component.states.gettingStarted);
    });

    it('buttonPath returns settings path for the state "gettingStarted"', () => {
      const component = createComponent({
        selectedState: 'gettingStarted',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
        emptyGettingStartedSvgPath: 'foo',
        emptyLoadingSvgPath: 'foo',
        emptyUnableToConnectSvgPath: 'foo',
      });

      expect(component.buttonPath).toEqual(statePaths.settingsPath);
      expect(component.buttonPath).not.toEqual(statePaths.documentationPath);
    });

    it('buttonPath returns documentation path for any of the other states', () => {
      const component = createComponent({
        selectedState: 'loading',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
        emptyGettingStartedSvgPath: 'foo',
        emptyLoadingSvgPath: 'foo',
        emptyUnableToConnectSvgPath: 'foo',
      });

      expect(component.buttonPath).toEqual(statePaths.documentationPath);
      expect(component.buttonPath).not.toEqual(statePaths.settingsPath);
    });

    it('showButtonDescription returns a description with a link for the unableToConnect state', () => {
      const component = createComponent({
        selectedState: 'unableToConnect',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
        emptyGettingStartedSvgPath: 'foo',
        emptyLoadingSvgPath: 'foo',
        emptyUnableToConnectSvgPath: 'foo',
      });

      expect(component.showButtonDescription).toEqual(true);
    });

    it('showButtonDescription returns the description without a link for any other state', () => {
      const component = createComponent({
        selectedState: 'loading',
        settingsPath: statePaths.settingsPath,
        documentationPath: statePaths.documentationPath,
        emptyGettingStartedSvgPath: 'foo',
        emptyLoadingSvgPath: 'foo',
        emptyUnableToConnectSvgPath: 'foo',
      });

      expect(component.showButtonDescription).toEqual(false);
    });
  });

  it('should show the gettingStarted state', () => {
    const component = createComponent({
      selectedState: 'gettingStarted',
      settingsPath: statePaths.settingsPath,
      documentationPath: statePaths.documentationPath,
      emptyGettingStartedSvgPath: 'foo',
      emptyLoadingSvgPath: 'foo',
      emptyUnableToConnectSvgPath: 'foo',
    });

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
      emptyGettingStartedSvgPath: 'foo',
      emptyLoadingSvgPath: 'foo',
      emptyUnableToConnectSvgPath: 'foo',
    });

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
      emptyGettingStartedSvgPath: 'foo',
      emptyLoadingSvgPath: 'foo',
      emptyUnableToConnectSvgPath: 'foo',
    });

    expect(component.$el.querySelector('svg')).toBeDefined();
    expect(getTextFromNode(component, '.state-title')).toEqual(component.states.unableToConnect.title);
    expect(component.$el.querySelector('.state-description a')).toBeDefined();
    expect(getTextFromNode(component, '.btn-success')).toEqual(component.states.unableToConnect.buttonText);
  });
});
