import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import toolbar from '~/vue_shared/components/markdown/toolbar.vue';

describe('toolbar', () => {
  let vm;
  const Toolbar = Vue.extend(toolbar);
  const props = {
    markdownDocsPath: '',
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('user can attach file', () => {
    beforeEach(() => {
      vm = mountComponent(Toolbar, props);
    });

    it('should render uploading-container', () => {
      expect(vm.$el.querySelector('.uploading-container')).not.toBeNull();
    });
  });

  describe('user cannot attach file', () => {
    beforeEach(() => {
      vm = mountComponent(
        Toolbar,
        Object.assign({}, props, {
          canAttachFile: false,
        }),
      );
    });

    it('should not render uploading-container', () => {
      expect(vm.$el.querySelector('.uploading-container')).toBeNull();
    });
  });
});
