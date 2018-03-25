import Vue from 'vue';
import changedFileIcon from '~/ide/components/changed_file_icon.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('IDE changed file icon', () => {
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

    it('equals git-merge when not a temp file and has no changes', () => {
      vm.file.changed = false;

      expect(vm.changedIcon).toBe('git-merge');
    });

    it('equals file-addition when a temp file', () => {
      vm.file.tempFile = true;

      expect(vm.changedIcon).toBe('file-addition');
    });
  });

  describe('changedIconClass', () => {
    it('includes multi-file-modified when not a temp file', () => {
      expect(vm.changedIconClass).toContain('multi-file-modified');
    });

    it('includes multi-git-merge when a mr changed file', () => {
      vm.file.changed = false;

      expect(vm.changedIconClass).toContain('multi-git-merge');
    });

    it('includes multi-file-addition when a temp file', () => {
      vm.file.tempFile = true;

      expect(vm.changedIconClass).toContain('multi-file-addition');
    });
  });
});
