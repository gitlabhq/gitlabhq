import Vue from 'vue';
import store from '~/ide/stores';
import listCollapsed from '~/ide/components/commit_sidebar/list_collapsed.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file } from '../../helpers';
import { removeWhitespace } from '../../../helpers/vue_component_helper';

describe('Multi-file editor commit sidebar list collapsed', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(listCollapsed);

    vm = createComponentWithStore(Component, store, {
      files: [
        {
          ...file('file1'),
          tempFile: true,
        },
        file('file2'),
      ],
      icon: 'staged',
      title: 'Staged',
    });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders added & modified files count', () => {
    expect(removeWhitespace(vm.$el.textContent).trim()).toBe('1 1');
  });

  describe('addedFilesLength', () => {
    it('returns an length of temp files', () => {
      expect(vm.addedFilesLength).toBe(1);
    });
  });

  describe('modifiedFilesLength', () => {
    it('returns an length of modified files', () => {
      expect(vm.modifiedFilesLength).toBe(1);
    });
  });

  describe('addedFilesIconClass', () => {
    it('includes multi-file-addition when addedFiles is not empty', () => {
      expect(vm.addedFilesIconClass).toContain('multi-file-addition');
    });

    it('excludes multi-file-addition when addedFiles is empty', () => {
      vm.files = [];

      expect(vm.addedFilesIconClass).not.toContain('multi-file-addition');
    });
  });

  describe('modifiedFilesClass', () => {
    it('includes multi-file-modified when addedFiles is not empty', () => {
      expect(vm.modifiedFilesClass).toContain('multi-file-modified');
    });

    it('excludes multi-file-modified when addedFiles is empty', () => {
      vm.files = [];

      expect(vm.modifiedFilesClass).not.toContain('multi-file-modified');
    });
  });
});
