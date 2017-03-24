import Vue from 'vue';
import deploymentComponent from '~/vue_merge_request_widget/components/mr_widget_deployment';
import { statusClassToSvgMap } from '~/vue_shared/pipeline_svg_icons';

const deploymentMockData = [
  {
    id: 15,
    name: 'review/diplo',
    url: '/root/acets-review-apps/environments/15',
    stop_url: '/root/acets-review-apps/environments/15/stop',
    external_url: 'http://diplo.',
    external_url_formatted: 'diplo.',
    deployed_at: '2017-03-22T22:44:42.258Z',
    deployed_at_formatted: 'Mar 22, 2017 10:44pm',
  },
];
const createComponent = () => {
  const Component = Vue.extend(deploymentComponent);
  const mr = {
    deployments: deploymentMockData,
  };

  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetDeployment', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = deploymentComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(deploymentComponent.components['pipeline-status-icon']).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('svg', () => {
      it('should have the proper SVG icon', () => {
        const vm = createComponent(deploymentMockData);
        expect(vm.svg).toEqual(statusClassToSvgMap.icon_status_success);
      });
    });
  });

  describe('methods', () => {
    const vm = createComponent();
    const deployment = deploymentMockData[0];

    describe('formatDate', () => {
      it('should work', () => {
        expect(vm.formatDate(deployment.deployed_at)).toEqual('1 day ago');
      });
    });

    describe('hasExternalUrls', () => {
      it('should return true', () => {
        expect(vm.hasExternalUrls(deployment)).toBeTruthy();
      });

      it('should return false when there is not enough information', () => {
        expect(vm.hasExternalUrls()).toBeFalsy();
        expect(vm.hasExternalUrls({ external_url: 'Diplo' })).toBeFalsy();
        expect(vm.hasExternalUrls({ external_url_formatted: 'Diplo' })).toBeFalsy();
      });
    });

    describe('hasDeploymentTime', () => {
      it('should return true', () => {
        expect(vm.hasDeploymentTime(deployment)).toBeTruthy();
      });

      it('should return false when there is not enough information', () => {
        expect(vm.hasDeploymentTime()).toBeFalsy();
        expect(vm.hasDeploymentTime({ deployed_at: 'Diplo' })).toBeFalsy();
        expect(vm.hasDeploymentTime({ deployed_at_formatted: 'Diplo' })).toBeFalsy();
      });
    });

    describe('hasDeploymentMeta', () => {
      it('should return true', () => {
        expect(vm.hasDeploymentMeta(deployment)).toBeTruthy();
      });

      it('should return false when there is not enough information', () => {
        expect(vm.hasDeploymentMeta()).toBeFalsy();
        expect(vm.hasDeploymentMeta({ url: 'Diplo' })).toBeFalsy();
        expect(vm.hasDeploymentMeta({ name: 'Diplo' })).toBeFalsy();
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;
    const [deployment] = deploymentMockData;

    beforeEach(() => {
      vm = createComponent(deploymentMockData);
      el = vm.$el;
    });

    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-widget-heading')).toBeTruthy();
      expect(el.querySelector('.icon-link')).toBeDefined();
      expect(el.querySelector('.deploy-meta').getAttribute('href')).toEqual(deployment.url);
      expect(el.querySelector('.deploy-meta').innerText).toContain(deployment.name);
      expect(el.querySelector('.deploy-url').getAttribute('href')).toEqual(deployment.external_url);
      expect(el.querySelector('.deploy-url').innerText).toContain(deployment.external_url_formatted);
      expect(el.querySelector('.deploy-time').innerText).toContain(vm.formatDate(deployment.deployed_at));
      expect(el.querySelector('button')).toBeDefined();
    });

    it('should list multiple deployments', (done) => {
      vm.mr.deployments.push(deployment);
      vm.mr.deployments.push(deployment);

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.ci_widget').length).toEqual(3);
        done();
      });
    });

    it('should not have some elements when there is not enough data', (done) => {
      vm.mr.deployments = [{}];

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.deploy-meta').length).toEqual(0);
        expect(el.querySelectorAll('.deploy-url').length).toEqual(0);
        expect(el.querySelectorAll('.deploy-time').length).toEqual(0);
        expect(el.querySelectorAll('.button').length).toEqual(0);
        done();
      });
    });
  });
});
