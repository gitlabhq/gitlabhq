import Vue from 'vue';
import MonitoringState from '~/monitoring/components/monitoring_deployment.vue';
import { deploymentData } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringState);

  return new Component({
    propsData,
  });
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
        height: 300,
      });

      expect(component.refText(reducedDeploymentData[0]))
      .toEqual(reducedDeploymentData[0].ref);
    });

    it('refText shows the sha when no tag is available', () => {
      reducedDeploymentData[0].tag = null;
      const component = createComponent({
        showDeployInfo: false,
        deploymentData: reducedDeploymentData,
        height: 300,
      });

      expect(component.refText(reducedDeploymentData[0]).indexOf(reducedDeploymentData[0].sha))
      .not.toEqual();
    });

    it('nameDeploymentClass creates a class with the prefix deploy-info-', () => {
      const component = createComponent({
        showDeployInfo: false,
        deploymentData: reducedDeploymentData,
        height: 300,
      });

      expect(component.nameDeploymentClass(reducedDeploymentData[0]).indexOf('deploy-info-'))
      .not.toEqual(-1);
    });

    it('transformDeploymentGroup translates an available deployment', () => {
      const component = createComponent({
        showDeployInfo: false,
        deploymentData: reducedDeploymentData,
        height: 300,
      });

      expect(component.transformDeploymentGroup(reducedDeploymentData[0]).indexOf('11,'))
      .not.toEqual(-1);
    });

    it('hides the deployment flag', () => {
      reducedDeploymentData[0].showDeploymentFlag = false;
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        height: 300,
      });
      component.$mount();

      expect(component.$el.querySelector('.js-deploy-info-box').getAttribute('style'))
      .toEqual('display: none;');
    });

    it('shows the deployment flag', () => {
      reducedDeploymentData[0].showDeploymentFlag = true;
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        height: 300,
      });
      component.$mount();

      expect(component.$el.querySelector('.js-deploy-info-box').getAttribute('style'))
      .not.toEqual('display: none;');
    });

    it('shows the refText inside a text element with the deploy-info-text class', () => {
      reducedDeploymentData[0].showDeploymentFlag = true;
      const component = createComponent({
        showDeployInfo: true,
        deploymentData: reducedDeploymentData,
        height: 300,
      });
      component.$mount();

      expect(component.$el.querySelector('.deploy-info-text').firstChild.nodeValue.trim())
      .toEqual(component.refText(reducedDeploymentData[0]));
    });
  });
});
