import Vue from 'vue';
import changedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('Changed file icon', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(changedFileIcon);

    vm = createComponent(component, {
      file: {
        tempFile: false,
        changed: true,
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('changedIcon', () => {
    it('equals file-modified when not a temp file and has changes', () => {
      expect(vm.changedIcon).toBe('file-modified');
    });

    it('equals file-addition when a temp file', () => {
      vm.file.tempFile = true;

      expect(vm.changedIcon).toBe('file-addition');
    });
  });

  describe('changedIconClass', () => {
    it('includes file-modified when not a temp file', () => {
      expect(vm.changedIconClass).toContain('file-modified');
    });

    it('includes file-addition when a temp file', () => {
      vm.file.tempFile = true;

      expect(vm.changedIconClass).toContain('file-addition');
    });
  });
});
