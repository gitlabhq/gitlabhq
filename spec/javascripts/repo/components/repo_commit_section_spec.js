import Vue from 'vue';
import * as urlUtils from '~/lib/utils/url_utility';
import store from '~/ide/stores';
import service from '~/ide/services';
import repoCommitSection from '~/ide/components/repo_commit_section.vue';
import getSetTimeoutPromise from '../../helpers/set_timeout_promise_helper';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
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

    vm.$store.state.rightPanelCollapsed = false;
    vm.$store.state.currentBranch = 'master';
    vm.$store.state.openFiles = [file('file1'), file('file2')];
    vm.$store.state.openFiles.forEach(f => Object.assign(f, {
      changed: true,
      content: 'testing',
    }));

    return vm.$mount();
  }

  beforeEach((done) => {
    vm = createComponent();

    spyOn(service, 'getTreeData').and.returnValue(Promise.resolve({
      headers: {
        'page-title': 'test',
      },
      json: () => Promise.resolve({
        last_commit_path: 'last_commit_path',
        parent_tree_url: 'parent_tree_url',
        path: '/',
        trees: [{ name: 'tree' }],
        blobs: [{ name: 'blob' }],
        submodules: [{ name: 'submodule' }],
      }),
    }));

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

      // Vue.nextTick();

      expect(vm.$el.querySelector('.js-empty-state').textContent.trim()).toContain('No changes');
      expect(vm.$el.querySelector('.js-empty-state img').getAttribute('src')).toBe('nochangessvg');
    });
  });

  it('renders a commit section', () => {
    const changedFileElements = [...vm.$el.querySelectorAll('.multi-file-commit-list li')];
    const submitCommit = vm.$el.querySelector('form .btn');

    expect(vm.$el.querySelector('.multi-file-commit-form')).not.toBeNull();
    expect(changedFileElements.length).toEqual(2);

    changedFileElements.forEach((changedFile, i) => {
      expect(changedFile.textContent.trim()).toEqual(vm.$store.getters.changedFiles[i].path);
    });

    expect(submitCommit.disabled).toBeTruthy();
    expect(submitCommit.querySelector('.fa-spinner.fa-spin')).toBeNull();
  });

  describe('when submitting', () => {
    let changedFiles;

    beforeEach(() => {
      vm.commitMessage = 'testing';
      changedFiles = JSON.parse(JSON.stringify(vm.$store.getters.changedFiles));

      spyOn(service, 'commit').and.returnValue(Promise.resolve({
        short_id: '1',
        stats: {},
      }));
    });

    it('allows you to submit', () => {
      expect(vm.$el.querySelector('form .btn').disabled).toBeTruthy();
    });

    it('submits commit', (done) => {
      vm.makeCommit();

      // Wait for the branch check to finish
      getSetTimeoutPromise()
        .then(() => Vue.nextTick())
        .then(() => {
          const args = service.commit.calls.allArgs()[0];
          const { commit_message, actions, branch: payloadBranch } = args[1];

          expect(commit_message).toBe('testing');
          expect(actions.length).toEqual(2);
          expect(payloadBranch).toEqual('master');
          expect(actions[0].action).toEqual('update');
          expect(actions[1].action).toEqual('update');
          expect(actions[0].content).toEqual(changedFiles[0].content);
          expect(actions[1].content).toEqual(changedFiles[1].content);
          expect(actions[0].file_path).toEqual(changedFiles[0].path);
          expect(actions[1].file_path).toEqual(changedFiles[1].path);

          expect(vm.$el.querySelector('.js-empty-state').textContent.trim()).toContain('All changes are committed');
          expect(vm.$el.querySelector('.js-empty-state img').getAttribute('src')).toBe('commitsvg');
        })
        .then(done)
        .catch(done.fail);
    });

    it('redirects to MR creation page if start new MR checkbox checked', (done) => {
      spyOn(urlUtils, 'visitUrl');
      vm.startNewMR = true;

      vm.makeCommit();

      getSetTimeoutPromise()
        .then(() => Vue.nextTick())
        .then(() => {
          expect(urlUtils.visitUrl).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
