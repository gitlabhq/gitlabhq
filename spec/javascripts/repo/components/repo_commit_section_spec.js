import Vue from 'vue';
import store from '~/repo/stores';
import service from '~/repo/services';
import repoCommitSection from '~/repo/components/repo_commit_section.vue';
import getSetTimeoutPromise from '../../helpers/set_timeout_promise_helper';
import { file, resetStore } from '../helpers';

describe('RepoCommitSection', () => {
  let vm;

  function createComponent() {
    const RepoCommitSection = Vue.extend(repoCommitSection);

    const comp = new RepoCommitSection({
      store,
    }).$mount();

    comp.$store.state.currentBranch = 'master';
    comp.$store.state.openFiles = [file(), file()];
    comp.$store.state.openFiles.forEach(f => Object.assign(f, {
      changed: true,
      content: 'testing',
    }));

    return comp.$mount();
  }

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders a commit section', () => {
    const changedFileElements = [...vm.$el.querySelectorAll('.changed-files > li')];
    const submitCommit = vm.$el.querySelector('.btn');
    const targetBranch = vm.$el.querySelector('.target-branch');

    expect(vm.$el.querySelector(':scope > form')).toBeTruthy();
    expect(vm.$el.querySelector('.staged-files').textContent.trim()).toEqual('Staged files (2)');
    expect(changedFileElements.length).toEqual(2);

    changedFileElements.forEach((changedFile, i) => {
      expect(changedFile.textContent.trim()).toEqual(vm.$store.getters.changedFiles[i].path);
    });

    expect(submitCommit.disabled).toBeTruthy();
    expect(submitCommit.querySelector('.fa-spinner.fa-spin')).toBeFalsy();
    expect(vm.$el.querySelector('.commit-summary').textContent.trim()).toEqual('Commit 2 files');
    expect(targetBranch.querySelector(':scope > label').textContent.trim()).toEqual('Target branch');
    expect(targetBranch.querySelector('.help-block').textContent.trim()).toEqual('master');
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
      expect(vm.$el.querySelector('.btn').disabled).toBeTruthy();
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
        })
        .then(done)
        .catch(done.fail);
    });

    it('redirects to MR creation page if start new MR checkbox checked', (done) => {
      spyOn(gl.utils, 'visitUrl');
      vm.startNewMR = true;

      vm.makeCommit();

      getSetTimeoutPromise()
        .then(() => Vue.nextTick())
        .then(() => {
          expect(gl.utils.visitUrl).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
