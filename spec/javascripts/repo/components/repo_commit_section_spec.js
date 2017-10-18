import Vue from 'vue';
import repoCommitSection from '~/repo/components/repo_commit_section.vue';
import RepoStore from '~/repo/stores/repo_store';
import RepoService from '~/repo/services/repo_service';
import getSetTimeoutPromise from '../../helpers/set_timeout_promise_helper';

describe('RepoCommitSection', () => {
  const branch = 'master';
  const projectUrl = 'projectUrl';
  let changedFiles;
  let openedFiles;

  RepoStore.projectUrl = projectUrl;

  function createComponent(el) {
    const RepoCommitSection = Vue.extend(repoCommitSection);

    return new RepoCommitSection().$mount(el);
  }

  beforeEach(() => {
    // Create a copy for each test because these can get modified directly
    changedFiles = [{
      id: 0,
      changed: true,
      url: `/namespace/${projectUrl}/blob/${branch}/dir/file0.ext`,
      path: 'dir/file0.ext',
      newContent: 'a',
    }, {
      id: 1,
      changed: true,
      url: `/namespace/${projectUrl}/blob/${branch}/dir/file1.ext`,
      path: 'dir/file1.ext',
      newContent: 'b',
    }];
    openedFiles = changedFiles.concat([{
      id: 2,
      url: `/namespace/${projectUrl}/blob/${branch}/dir/file2.ext`,
      path: 'dir/file2.ext',
      changed: false,
    }]);
  });

  it('renders a commit section', () => {
    RepoStore.isCommitable = true;
    RepoStore.currentBranch = branch;
    RepoStore.targetBranch = branch;
    RepoStore.openedFiles = openedFiles;

    const vm = createComponent();
    const changedFileElements = [...vm.$el.querySelectorAll('.changed-files > li')];
    const commitMessage = vm.$el.querySelector('#commit-message');
    const submitCommit = vm.$refs.submitCommit;
    const targetBranch = vm.$el.querySelector('.target-branch');

    expect(vm.$el.querySelector(':scope > form')).toBeTruthy();
    expect(vm.$el.querySelector('.staged-files').textContent.trim()).toEqual('Staged files (2)');
    expect(changedFileElements.length).toEqual(2);

    changedFileElements.forEach((changedFile, i) => {
      expect(changedFile.textContent.trim()).toEqual(changedFiles[i].path);
    });

    expect(commitMessage.tagName).toEqual('TEXTAREA');
    expect(commitMessage.name).toEqual('commit-message');
    expect(submitCommit.type).toEqual('submit');
    expect(submitCommit.disabled).toBeTruthy();
    expect(submitCommit.querySelector('.fa-spinner.fa-spin')).toBeFalsy();
    expect(vm.$el.querySelector('.commit-summary').textContent.trim()).toEqual('Commit 2 files');
    expect(targetBranch.querySelector(':scope > label').textContent.trim()).toEqual('Target branch');
    expect(targetBranch.querySelector('.help-block').textContent.trim()).toEqual(branch);
  });

  it('does not render if not isCommitable', () => {
    RepoStore.isCommitable = false;
    RepoStore.openedFiles = [{
      id: 0,
      changed: true,
    }];

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });

  it('does not render if no changedFiles', () => {
    RepoStore.isCommitable = true;
    RepoStore.openedFiles = [];

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });

  describe('when submitting', () => {
    let el;
    let vm;
    const projectId = 'projectId';
    const commitMessage = 'commitMessage';

    beforeEach((done) => {
      RepoStore.isCommitable = true;
      RepoStore.currentBranch = branch;
      RepoStore.targetBranch = branch;
      RepoStore.openedFiles = openedFiles;
      RepoStore.projectId = projectId;

      // We need to append to body to get form `submit` events working
      // Otherwise we run into, "Form submission canceled because the form is not connected"
      // See https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-submission-algorithm
      el = document.createElement('div');
      document.body.appendChild(el);

      vm = createComponent(el);
      vm.commitMessage = commitMessage;

      spyOn(vm, 'tryCommit').and.callThrough();
      spyOn(vm, 'redirectToNewMr').and.stub();
      spyOn(vm, 'redirectToBranch').and.stub();
      spyOn(RepoService, 'commitFiles').and.returnValue(Promise.resolve());
      spyOn(RepoService, 'getBranch').and.returnValue(Promise.resolve({
        commit: {
          id: 1,
          short_id: 1,
        },
      }));

      // Wait for the vm data to be in place
      Vue.nextTick(() => {
        done();
      });
    });

    afterEach(() => {
      vm.$destroy();
      el.remove();
    });

    it('shows commit message', () => {
      const commitMessageEl = vm.$el.querySelector('#commit-message');
      expect(commitMessageEl.value).toBe(commitMessage);
    });

    it('allows you to submit', () => {
      const submitCommit = vm.$refs.submitCommit;
      expect(submitCommit.disabled).toBeFalsy();
    });

    it('shows commit submit and summary if commitMessage and spinner if submitCommitsLoading', (done) => {
      const submitCommit = vm.$refs.submitCommit;
      submitCommit.click();

      // Wait for the branch check to finish
      getSetTimeoutPromise()
        .then(() => Vue.nextTick())
        .then(() => {
          expect(vm.tryCommit).toHaveBeenCalled();
          expect(submitCommit.querySelector('.js-commit-loading-icon')).toBeTruthy();
          expect(vm.redirectToBranch).toHaveBeenCalled();

          const args = RepoService.commitFiles.calls.allArgs()[0];
          const { commit_message, actions, branch: payloadBranch } = args[0];

          expect(commit_message).toBe(commitMessage);
          expect(actions.length).toEqual(2);
          expect(payloadBranch).toEqual(branch);
          expect(actions[0].action).toEqual('update');
          expect(actions[1].action).toEqual('update');
          expect(actions[0].content).toEqual(openedFiles[0].newContent);
          expect(actions[1].content).toEqual(openedFiles[1].newContent);
          expect(actions[0].file_path).toEqual(openedFiles[0].path);
          expect(actions[1].file_path).toEqual(openedFiles[1].path);
        })
        .then(done)
        .catch(done.fail);
    });

    it('redirects to MR creation page if start new MR checkbox checked', (done) => {
      vm.startNewMR = true;

      Vue.nextTick()
        .then(() => {
          const submitCommit = vm.$refs.submitCommit;
          submitCommit.click();
        })
        // Wait for the branch check to finish
        .then(() => getSetTimeoutPromise())
        .then(() => {
          expect(vm.redirectToNewMr).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('methods', () => {
    describe('resetCommitState', () => {
      it('should reset store vars and scroll to top', () => {
        const vm = {
          submitCommitsLoading: true,
          changedFiles: new Array(10),
          openedFiles: new Array(3),
          commitMessage: 'commitMessage',
          editMode: true,
        };

        repoCommitSection.methods.resetCommitState.call(vm);

        expect(vm.submitCommitsLoading).toEqual(false);
        expect(vm.changedFiles).toEqual([]);
        expect(vm.commitMessage).toEqual('');
        expect(vm.editMode).toEqual(false);
      });
    });
  });
});
