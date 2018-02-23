import Vue from 'vue';
import maintainerEditComponent from '~/vue_merge_request_widget/components/mr_widget_maintainer_edit.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetAuthor', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(maintainerEditComponent);

    vm = mountComponent(Component, {
      maintainerEditAllowed: true,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the message when maintainers are allowed to edit', () => {
    expect(vm.$el.textContent.trim()).toEqual('Allows edits from maintainers');
  });
});
