import Vue from 'vue';
import archivedComponent from '~/vue_merge_request_widget/components/states/mr_widget_archived.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetArchived', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(archivedComponent);
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a ci status failed icon', () => {
    expect(vm.$el.querySelector('.ci-status-icon')).not.toBeNull();
  });

  it('renders a disabled button', () => {
    expect(vm.$el.querySelector('button').getAttribute('disabled')).toEqual('disabled');
    expect(vm.$el.querySelector('button').textContent.trim()).toEqual('Merge');
  });

  it('renders information', () => {
    expect(
      vm.$el.querySelector('.bold').textContent.trim(),
    ).toEqual('This project is archived, write access has been disabled');
  });
});
