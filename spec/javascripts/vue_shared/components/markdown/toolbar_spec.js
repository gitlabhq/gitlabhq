import Vue from 'vue';
import toolbar from '~/vue_shared/components/markdown/toolbar.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('toolbar', () => {
  let vm;
  beforeEach(() => {
    const Toolbar = Vue.extend(toolbar);
    vm = mountComponent(Toolbar, {
      markdownDocsPath: '',
    });
  });

  describe('canAttachFile', () => {
    it('should render uploading-container by default', () => {
      expect(vm.$el.querySelector('.uploading-container')).toBeDefined();
    });

    it('should not render uploading-container when canAttachFile is false', (done) => {
      vm.canAttachFile = false;

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.uploading-container')).toBeNull();
        done();
      });
    });
  });
});
