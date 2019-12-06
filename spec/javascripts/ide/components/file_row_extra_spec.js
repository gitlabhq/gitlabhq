import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/ide/stores';
import FileRowExtra from '~/ide/components/file_row_extra.vue';
import { file, resetStore } from '../helpers';

describe('IDE extra file row component', () => {
  let Component;
  let vm;
  let unstagedFilesCount = 0;
  let stagedFilesCount = 0;
  let changesCount = 0;

  beforeAll(() => {
    Component = Vue.extend(FileRowExtra);
  });

  beforeEach(() => {
    vm = createComponentWithStore(Component, createStore(), {
      file: {
        ...file('test'),
      },
      dropdownOpen: false,
    });

    spyOnProperty(vm, 'getUnstagedFilesCountForPath').and.returnValue(() => unstagedFilesCount);
    spyOnProperty(vm, 'getStagedFilesCountForPath').and.returnValue(() => stagedFilesCount);
    spyOnProperty(vm, 'getChangesInFolder').and.returnValue(() => changesCount);

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
    resetStore(vm.$store);

    stagedFilesCount = 0;
    unstagedFilesCount = 0;
    changesCount = 0;
  });

  describe('folderChangesTooltip', () => {
    it('returns undefined when changes count is 0', () => {
      expect(vm.folderChangesTooltip).toBe(undefined);
    });

    it('returns unstaged changes text', () => {
      changesCount = 1;
      unstagedFilesCount = 1;

      expect(vm.folderChangesTooltip).toBe('1 unstaged change');
    });

    it('returns staged changes text', () => {
      changesCount = 1;
      stagedFilesCount = 1;

      expect(vm.folderChangesTooltip).toBe('1 staged change');
    });

    it('returns staged and unstaged changes text', () => {
      changesCount = 1;
      stagedFilesCount = 1;
      unstagedFilesCount = 1;

      expect(vm.folderChangesTooltip).toBe('1 unstaged and 1 staged changes');
    });
  });

  describe('show tree changes count', () => {
    it('does not show for blobs', () => {
      vm.file.type = 'blob';

      expect(vm.$el.querySelector('.ide-tree-changes')).toBe(null);
    });

    it('does not show when changes count is 0', () => {
      vm.file.type = 'tree';

      expect(vm.$el.querySelector('.ide-tree-changes')).toBe(null);
    });

    it('does not show when tree is open', done => {
      vm.file.type = 'tree';
      vm.file.opened = true;
      changesCount = 1;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.ide-tree-changes')).toBe(null);

        done();
      });
    });

    it('shows for trees with changes', done => {
      vm.file.type = 'tree';
      vm.file.opened = false;
      changesCount = 1;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.ide-tree-changes')).not.toBe(null);

        done();
      });
    });
  });

  describe('changes file icon', () => {
    it('hides when file is not changed', () => {
      expect(vm.$el.querySelector('.file-changed-icon')).toBe(null);
    });

    it('shows when file is changed', done => {
      vm.file.changed = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);

        done();
      });
    });

    it('shows when file is staged', done => {
      vm.file.staged = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);

        done();
      });
    });

    it('shows when file is a tempFile', done => {
      vm.file.tempFile = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);

        done();
      });
    });

    it('shows when file is renamed', done => {
      vm.file.prevPath = 'original-file';

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);

        done();
      });
    });

    it('hides when file is renamed', done => {
      vm.file.prevPath = 'original-file';
      vm.file.type = 'tree';

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.file-changed-icon')).toBe(null);

        done();
      });
    });
  });

  describe('merge request icon', () => {
    it('hides when not a merge request change', () => {
      expect(vm.$el.querySelector('.ic-git-merge')).toBe(null);
    });

    it('shows when a merge request change', done => {
      vm.file.mrChange = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.ic-git-merge')).not.toBe(null);

        done();
      });
    });
  });
});
