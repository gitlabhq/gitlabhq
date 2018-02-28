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
  const reducedDeploymentData = [deploymentData[0]];
  reducedDeploymentData[0].ref = reducedDeploymentData[0].ref.name;
  reducedDeploymentData[0].xPos = 10;
  reducedDeploymentData[0].time = new Date(reducedDeploymentData[0].created_at);
  describe('Methods', () => {
    it('refText shows the ref when a tag is available', () => {
      reducedDeploymentData[0].tag = '1.0';
      const component = createComponent({
        showDeployInfo: false,
        deploymentData: reducedDeploymentData,
        graphWidth: 440,
        graphHeight: 300,
        graphHeightOffset: 120,
      });

      expect(
        component.refText(reducedDeploymentData[0]),
      ).toEqual(reducedDeploymentData[0].ref);
    });

    it('refText shows the sha when no tag is available', () => {
      reducedDeploymentData[0].tag = null;
      const component = createComponent({
        showDeployInfo: false,
        deploymentData: reducedDeploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(
        component.refText(reducedDeploymentData[0]),
      ).toContain('f5bcd1');
    });

    it('nameDeploymentClass creates a class with the prefix deploy-info-', () => {
      const component = createComponent({
        showDeployInfo: false,
        deploymentData: reducedDeploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(
        component.nameDeploymentClass(reducedDeploymentData[0]),
      ).toContain('deploy-info');
    });

    it('transformDeploymentGroup translates an available deployment', () => {
      const component = createComponent({
        showDeployInfo: false,
        deploymentData: reducedDeploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(
        component.transformDeploymentGroup(reducedDeploymentData[0]),
      ).toContain('translate(11, 20)');
    });

    it('hides the deployment flag', () => {
      reducedDeploymentData[0].showDeploymentFlag = false;
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        graphWidth: 440,
        graphHeight: 300,
        graphHeightOffset: 120,
      });

      expect(component.$el.querySelector('.js-deploy-info-box')).toBeNull();
    });

    it('positions the flag to the left when the xPos is too far right', () => {
      reducedDeploymentData[0].showDeploymentFlag = false;
      reducedDeploymentData[0].xPos = 250;
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        graphWidth: 440,
        graphHeight: 300,
        graphHeightOffset: 120,
      });

      expect(
        component.positionFlag(reducedDeploymentData[0]),
      ).toBeLessThan(0);
    });

    it('shows the deployment flag', () => {
      reducedDeploymentData[0].showDeploymentFlag = true;
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(
        component.$el.querySelector('.js-deploy-info-box').style.display,
      ).not.toEqual('display: none;');
    });

    it('shows the refText inside a text element with the deploy-info-text class', () => {
      reducedDeploymentData[0].showDeploymentFlag = true;
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(
        component.$el.querySelector('.deploy-info-text').firstChild.nodeValue.trim(),
      ).toEqual(component.refText(reducedDeploymentData[0]));
    });

    it('should contain a hidden gradient', () => {
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        graphHeight: 300,
        graphWidth: 440,
        graphHeightOffset: 120,
      });

      expect(component.$el.querySelector('#shadow-gradient')).not.toBeNull();
    });

    describe('Computed props', () => {
      it('calculatedHeight', () => {
        const component = createComponent({
          showDeployInfo: true,
          deploymentData: reducedDeploymentData,
          graphHeight: 300,
          graphWidth: 440,
          graphHeightOffset: 120,
        });

        expect(component.calculatedHeight).toEqual(180);
      });
    });
  });
});
