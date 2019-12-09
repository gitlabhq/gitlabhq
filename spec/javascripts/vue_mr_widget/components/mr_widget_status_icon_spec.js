import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import mrStatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

describe('MR widget status icon component', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(mrStatusIcon);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('while loading', () => {
    it('renders loading icon', () => {
      vm = mountComponent(Component, { status: 'loading' });

      expect(vm.$el.querySelector('.mr-widget-icon span').classList).toContain('gl-spinner');
    });
  });

  describe('with status icon', () => {
    it('renders ci status icon', () => {
      vm = mountComponent(Component, { status: 'failed' });

      expect(vm.$el.querySelector('.js-ci-status-icon-failed')).not.toBeNull();
    });
  });

  describe('with disabled button', () => {
    it('renders a disabled button', () => {
      vm = mountComponent(Component, { status: 'failed', showDisabledButton: true });

      expect(vm.$el.querySelector('.js-disabled-merge-button').textContent.trim()).toEqual('Merge');
    });
  });

  describe('without disabled button', () => {
    it('does not render a disabled button', () => {
      vm = mountComponent(Component, { status: 'failed' });

      expect(vm.$el.querySelector('.js-disabled-merge-button')).toBeNull();
    });
  });
});
