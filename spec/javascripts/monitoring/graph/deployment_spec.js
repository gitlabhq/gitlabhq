import Vue from 'vue';
import GraphDeployment from '~/monitoring/components/graph/deployment.vue';
import { deploymentData } from '../mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(GraphDeployment);

  return new Component({
    propsData,
  }).$mount();
};

describe('MonitoringDeployment', () => {
  describe('Methods', () => {
    it('should contain a hidden gradient', () => {
      const component = createComponent({
        showDeployInfo: true,
        deploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(component.$el.querySelector('#shadow-gradient')).not.toBeNull();
    });

    it('transformDeploymentGroup translates an available deployment', () => {
      const component = createComponent({
        showDeployInfo: false,
        deploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(
        component.transformDeploymentGroup({ xPos: 16 }),
      ).toContain('translate(11, 20)');
    });

    describe('Computed props', () => {
      it('calculatedHeight', () => {
        const component = createComponent({
          showDeployInfo: true,
          deploymentData,
          graphHeight: 300,
          graphWidth: 440,
          graphHeightOffset: 120,
        });

        expect(component.calculatedHeight).toEqual(180);
      });
    });
  });
});
