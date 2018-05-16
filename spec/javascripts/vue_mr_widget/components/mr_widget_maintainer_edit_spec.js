import Vue from 'vue';
import maintainerEditComponent from '~/vue_merge_request_widget/components/mr_widget_maintainer_edit.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('RWidgetMaintainerEdit', () => {
  let Component;
  let vm;

  beforeEach(() => {
    Component = Vue.extend(maintainerEditComponent);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('when a maintainer is allowed to edit', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        maintainerEditAllowed: true,
      });
    });

    it('it renders the message', () => {
      expect(vm.$el.textContent.trim()).toEqual('Allows edits from maintainers');
    });
  });

  describe('when a maintainer is not allowed to edit', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        maintainerEditAllowed: false,
      });
    });

    it('hides the message', () => {
      expect(vm.$el.textContent.trim()).toEqual('');
    });
  });
});
