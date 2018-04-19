import Vue from 'vue';
import store from '~/ide/stores';
import service from '~/ide/services';
import repoCommitSection from '~/ide/components/repo_commit_section.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import { file, resetStore } from '../helpers';

describe('RepoCommitSection', () => {
  let vm;

  function createComponent() {
    const Component = Vue.extend(repoCommitSection);

    vm = createComponentWithStore(Component, store, {
      noChangesStateSvgPath: 'svg',
      committedStateSvgPath: 'commitsvg',
    });

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

    return vm.$mount();
  }

  beforeEach(done => {
    vm = createComponent();

    spyOn(service, 'getTreeData').and.returnValue(
      Promise.resolve({
        headers: {
          'page-title': 'test',
        },
        json: () =>
          Promise.resolve({
            last_commit_path: 'last_commit_path',
            parent_tree_url: 'parent_tree_url',
            path: '/',
            trees: [{ name: 'tree' }],
            blobs: [{ name: 'blob' }],
            submodules: [{ name: 'submodule' }],
          }),
      }),
    );

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

      vm = createComponentWithStore(Component, store, {
        noChangesStateSvgPath: 'nochangessvg',
        committedStateSvgPath: 'svg',
      }).$mount();

      expect(
        vm.$el.querySelector('.js-empty-state').textContent.trim(),
      ).toContain('No changes');
      expect(
        vm.$el.querySelector('.js-empty-state img').getAttribute('src'),
      ).toBe('nochangessvg');
    });
  });

  it('renders a commit section', () => {
    const changedFileElements = [
      ...vm.$el.querySelectorAll('.multi-file-commit-list li'),
    ];
    const submitCommit = vm.$el.querySelector('form .btn');
    const allFiles = vm.$store.state.changedFiles.concat(
      vm.$store.state.stagedFiles,
    );

    expect(vm.$el.querySelector('.multi-file-commit-form')).not.toBeNull();
    expect(changedFileElements.length).toEqual(4);

    changedFileElements.forEach((changedFile, i) => {
      expect(changedFile.textContent.trim()).toContain(allFiles[i].path);
    });

    expect(submitCommit.disabled).toBeTruthy();
    expect(submitCommit.querySelector('.fa-spinner.fa-spin')).toBeNull();
  });

  it('adds changed files into staged files', done => {
    vm.$el.querySelector('.ide-staged-action-btn').click();

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.ide-commit-list-container').textContent,
      ).toContain('No changes');

      done();
    });
  });

  it('stages a single file', done => {
    vm.$el.querySelector('.multi-file-discard-btn .btn').click();

    Vue.nextTick(() => {
      expect(
        vm.$el
          .querySelector('.ide-commit-list-container')
          .querySelectorAll('li').length,
      ).toBe(1);

      done();
    });
  });

  it('discards a single file', done => {
    vm.$el.querySelectorAll('.multi-file-discard-btn .btn')[1].click();

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.ide-commit-list-container').textContent,
      ).not.toContain('file1');
      expect(
        vm.$el
          .querySelector('.ide-commit-list-container')
          .querySelectorAll('li').length,
      ).toBe(1);

      done();
    });
  });

  it('removes all staged files', done => {
    vm.$el.querySelectorAll('.ide-staged-action-btn')[1].click();

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelectorAll('.ide-commit-list-container')[1].textContent,
      ).toContain('No changes');

      done();
    });
  });

  it('unstages a single file', done => {
    vm.$el
      .querySelectorAll('.multi-file-discard-btn')[2]
      .querySelector('.btn')
      .click();

    Vue.nextTick(() => {
      expect(
        vm.$el
          .querySelectorAll('.ide-commit-list-container')[1]
          .querySelectorAll('li').length,
      ).toBe(1);

      done();
    });
  });

  it('updates commitMessage in store on input', done => {
    const textarea = vm.$el.querySelector('textarea');

    textarea.value = 'testing commit message';

    textarea.dispatchEvent(new Event('input'));

    getSetTimeoutPromise()
      .then(() => {
        expect(vm.$store.state.commit.commitMessage).toBe(
          'testing commit message',
        );
      })
      .then(done)
      .catch(done.fail);
  });

  describe('discard draft button', () => {
    it('hidden when commitMessage is empty', () => {
      expect(
        vm.$el.querySelector('.multi-file-commit-form .btn-secondary'),
      ).toBeNull();
    });

    it('resets commitMessage when clicking discard button', done => {
      vm.$store.state.commit.commitMessage = 'testing commit message';

      getSetTimeoutPromise()
        .then(() => {
          vm.$el.querySelector('.multi-file-commit-form .btn-secondary').click();
        })
        .then(Vue.nextTick)
        .then(() => {
          expect(vm.$store.state.commit.commitMessage).not.toBe(
            'testing commit message',
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when submitting', () => {
    beforeEach(() => {
      spyOn(vm, 'commitChanges');
    });

    it('calls commitChanges', done => {
      vm.$store.state.commit.commitMessage = 'testing commit message';

      getSetTimeoutPromise()
        .then(() => {
          vm.$el.querySelector('.multi-file-commit-form .btn-success').click();
        })
        .then(Vue.nextTick)
        .then(() => {
          expect(vm.commitChanges).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
