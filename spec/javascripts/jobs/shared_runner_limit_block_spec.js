import Vue from 'vue';
import component from 'ee/jobs/components/shared_runner_limit_block.vue';
import mountComponent from '../helpers/vue_mount_component_helper';
import { trimText } from '../helpers/vue_component_helper';

describe('Shared Runner Limit Block', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('quota information', () => {
    it('renders provided quota limit and used quota', () => {
      vm = mountComponent(Component, {
        quotaUsed: 1000,
        quotaLimit: 4000,
        runnersPath: 'root/project/runners',
      });

      expect(vm.$el.textContent).toContain('You have used all your shared Runners pipeline minutes.');
      expect(vm.$el.textContent).toContain('1000 of 4000');
    });
  });

  describe('with runnersPath', () => {
    it('renders runner link', () => {
      vm = mountComponent(Component, {
        quotaUsed: 1000,
        quotaLimit: 4000,
        runnersPath: 'root/project/runners',
      });

      expect(trimText(vm.$el.textContent)).toContain('For more information, go to the Runners page.');
    });

  });

  describe('without runnersPath', () => {
    it('does not renbder runner link', () => {
      vm = mountComponent(Component, {
        quotaUsed: 1000,
        quotaLimit: 4000,
      });

      expect(trimText(vm.$el.textContent)).not.toContain('For more information, go to the Runners page.');
    });
  });
});
