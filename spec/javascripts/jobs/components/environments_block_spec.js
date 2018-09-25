import Vue from 'vue';
import component from '~/jobs/components/environments_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Environments block', () => {
  const Component = Vue.extend(component);
  let vm;
  const icon = {
    group: 'success',
    icon: 'status_success',
    label: 'passed',
    text: 'passed',
    tooltip: 'passed',
  };
  const deployment = {
    path: 'deployment',
    name: 'deployment name',
  };
  const environment = {
    path: '/environment',
    name: 'environment',
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('with latest deployment', () => {
    it('renders info for most recent deployment', () => {
      vm = mountComponent(Component, {
        deploymentStatus: {
          status: 'latest',
          icon,
          deployment,
          environment,
        },
      });

      expect(vm.$el.textContent.trim()).toEqual(
        'This job is the most recent deployment to environment.',
      );
    });
  });

  describe('with out of date deployment', () => {
    describe('with last deployment', () => {
      it('renders info for out date and most recent', () => {
        vm = mountComponent(Component, {
          deploymentStatus: {
            status: 'out_of_date',
            icon,
            deployment,
            environment: Object.assign({}, environment, {
              last_deployment: { name: 'deployment', path: 'last_deployment' },
            }),
          },
        });

        expect(vm.$el.textContent.trim()).toEqual(
          'This job is an out-of-date deployment to environment. View the most recent deployment deployment.',
        );
      });
    });

    describe('without last deployment', () => {
      it('renders info about out of date deployment', () => {
        vm = mountComponent(Component, {
          deploymentStatus: {
            status: 'out_of_date',
            icon,
            deployment: null,
            environment,
          },
        });

        expect(vm.$el.textContent.trim()).toEqual(
          'This job is an out-of-date deployment to environment.',
        );
      });
    });
  });

  describe('with failed deployment', () => {
    it('renders info about failed deployment', () => {
      vm = mountComponent(Component, {
        deploymentStatus: {
          status: 'failed',
          icon,
          deployment: null,
          environment,
        },
      });

      expect(vm.$el.textContent.trim()).toEqual(
        'The deployment of this job to environment did not succeed.',
      );
    });
  });

  describe('creating deployment', () => {
    describe('with last deployment', () => {
      it('renders info about creating deployment and overriding lastest deployment', () => {
        vm = mountComponent(Component, {
          deploymentStatus: {
            status: 'creating',
            icon,
            deployment,
            environment: Object.assign({}, environment, {
              last_deployment: { name: 'deployment', path: 'last_deployment' },
            }),
          },
        });

        expect(vm.$el.textContent.trim()).toEqual(
          'This job is creating a deployment to environment and will overwrite the last deployment.',
        );
      });
    });

    describe('without last deployment', () => {
      it('renders info about failed deployment', () => {
        vm = mountComponent(Component, {
          deploymentStatus: {
            status: 'creating',
            icon,
            deployment: null,
            environment,
          },
        });

        expect(vm.$el.textContent.trim()).toEqual(
          'This job is creating a deployment to environment.',
        );
      });
    });
  });
});
