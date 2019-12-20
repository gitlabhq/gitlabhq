import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import store from '~/ide/stores';
import router from '~/ide/ide_router';
import repoCommitSection from '~/ide/components/repo_commit_section.vue';
import { file, resetStore } from '../helpers';

describe('RepoCommitSection', () => {
  let vm;

  function createComponent() {
    const Component = Vue.extend(repoCommitSection);

    store.state.noChangesStateSvgPath = 'svg';
    store.state.committedStateSvgPath = 'commitsvg';

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentProjectId = 'abcproject';
    vm.$store.state.currentBranchId = 'master';
    vm.$store.state.projects.abcproject = {
      web_url: '',
      branches: {
        master: {
          workingReference: '1',
        },
      },
    };

    const files = [file('file1'), file('file2')].map(f =>
      Object.assign(f, {
        type: 'blob',
      }),
    );

    vm.$store.state.rightPanelCollapsed = false;
    vm.$store.state.currentBranch = 'master';
    vm.$store.state.changedFiles = [...files];
    vm.$store.state.changedFiles.forEach(f =>
      Object.assign(f, {
        changed: true,
        content: 'changedFile testing',
      }),
    );

    vm.$store.state.stagedFiles = [{ ...files[0] }, { ...files[1] }];
    vm.$store.state.stagedFiles.forEach(f =>
      Object.assign(f, {
        changed: true,
        content: 'testing',
      }),
    );

    vm.$store.state.changedFiles.forEach(f => {
      vm.$store.state.entries[f.path] = f;
    });

    return vm;
  }

  beforeEach(done => {
    spyOn(router, 'push');

    vm = createComponent();

    spyOn(vm, 'openPendingTab').and.callThrough();

    vm.$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('empty Stage', () => {
    it('renders no changes text', () => {
      resetStore(vm.$store);
      const Component = Vue.extend(repoCommitSection);

      store.state.noChangesStateSvgPath = 'nochangessvg';
      store.state.committedStateSvgPath = 'svg';

      vm.$destroy();
      vm = createComponentWithStore(Component, store).$mount();

      expect(vm.$el.querySelector('.js-empty-state').textContent.trim()).toContain('No changes');
      expect(vm.$el.querySelector('.js-empty-state img').getAttribute('src')).toBe('nochangessvg');
    });
  });

  it('renders a commit section', () => {
    const changedFileElements = [...vm.$el.querySelectorAll('.multi-file-commit-list > li')];
    const allFiles = vm.$store.state.changedFiles.concat(vm.$store.state.stagedFiles);

    expect(changedFileElements.length).toEqual(4);

    changedFileElements.forEach((changedFile, i) => {
      expect(changedFile.textContent.trim()).toContain(allFiles[i].path);
    });
  });

  describe('mounted', () => {
    it('opens last opened file', () => {
      expect(store.state.openFiles.length).toBe(1);
      expect(store.state.openFiles[0].pending).toBe(true);
    });

    it('calls openPendingTab', () => {
      expect(vm.openPendingTab).toHaveBeenCalledWith({
        file: vm.lastOpenedFile,
        keyPrefix: 'unstaged',
      });
    });
  });
});
