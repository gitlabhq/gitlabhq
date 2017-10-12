import Vue from 'vue';
import repoCommitSection from '~/repo/components/repo_commit_section.vue';
import RepoStore from '~/repo/stores/repo_store';
import RepoService from '~/repo/services/repo_service';

describe('RepoCommitSection', () => {
  const branch = 'master';
  const projectUrl = 'projectUrl';
  const changedFiles = [{
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
  const openedFiles = changedFiles.concat([{
    id: 2,
    url: `/namespace/${projectUrl}/blob/${branch}/dir/file2.ext`,
    path: 'dir/file2.ext',
    changed: false,
  }]);

  RepoStore.projectUrl = projectUrl;

  function createComponent() {
    // We need to append to body to get form `submit` events working
    // Otherwise we run into, "Form submission canceled because the form is not connected"
    // See https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-submission-algorithm
    const mountPoint = document.createElement('div');
    document.body.appendChild(mountPoint);

    const RepoCommitSection = Vue.extend(repoCommitSection);

    return new RepoCommitSection().$mount(mountPoint);
  }

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

  it('shows commit submit and summary if commitMessage and spinner if submitCommitsLoading', (done) => {
    const projectId = 'projectId';
    const commitMessage = 'commitMessage';
    RepoStore.isCommitable = true;
    RepoStore.currentBranch = branch;
    RepoStore.targetBranch = branch;
    RepoStore.openedFiles = openedFiles;
    RepoStore.projectId = projectId;

    const vm = createComponent();
    const commitMessageEl = vm.$el.querySelector('#commit-message');
    const submitCommit = vm.$refs.submitCommit;

    vm.commitMessage = commitMessage;

    vm.$nextTick(() => {
      expect(commitMessageEl.value).toBe(commitMessage);
      expect(submitCommit.disabled).toBeFalsy();

      spyOn(vm, 'tryCommit').and.callThrough();
      spyOn(vm, 'reloadPage');
      spyOn(RepoStore, 'setBranchHash').and.returnValue(Promise.resolve());
      spyOn(RepoService, 'commitFiles').and.returnValue(Promise.resolve());

      vm.$once('tryCommit:complete', () => {
        vm.$nextTick(() => {
          expect(vm.tryCommit).toHaveBeenCalled();
          expect(vm.reloadPage).toHaveBeenCalled();
          expect(submitCommit.querySelector('.fa-spinner.fa-spin')).toBeTruthy();

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

          done();
        });
      });

      submitCommit.click();
    });
  });

  it('renders a new branch dialog when submitted if branchChanged', (done) => {
    RepoStore.commitMessage = 'commit';
    RepoStore.projectId = 'projectId';
    RepoStore.isCommitable = true;
    RepoStore.branchChanged = true;
    RepoStore.submitCommitsLoading = false;
    RepoStore.currentBranch = branch;
    RepoStore.targetBranch = branch;
    RepoStore.openedFiles = openedFiles;

    const vm = createComponent();

    spyOn(RepoStore, 'setBranchHash').and.returnValue(Promise.resolve());

    vm.$once('showBranchChangeDialog:enabled', () => {
      vm.$nextTick(() => {
        const popupDialog = vm.$el.querySelector('.popup-dialog');
        const modalFooter = popupDialog.querySelector('.modal-footer');

        expect(popupDialog.querySelector('.modal-title').textContent).toMatch('Branch has changed');
        expect(popupDialog.querySelector('.modal-body').textContent)
          .toMatch('This branch has changed since your started editing. Would you like to create a new branch?');
        expect(modalFooter.querySelector('.close-button').textContent).toMatch('Cancel');
        expect(modalFooter.querySelector('.primary-button').textContent).toMatch('Create New Branch');

        done();
      });
    });
    vm.$refs.submitCommit.click();
  });

  describe('methods', () => {
    describe('resetCommitState', () => {
      it('should reset store vars and scroll to top', () => {
        const vm = {
          submitCommitsLoading: true,
          changedFiles: new Array(10),
          openedFiles: [{ changed: true }, { changed: false }],
          commitMessage: 'commitMessage',
          editMode: true,
        };

        repoCommitSection.methods.resetCommitState.call(vm);

        expect(vm.submitCommitsLoading).toEqual(false);
        expect(vm.changedFiles).toEqual([]);
        expect(vm.openedFiles).toEqual([{ changed: false }, { changed: false }]);
        expect(vm.commitMessage).toEqual('');
        expect(vm.editMode).toEqual(false);
      });
    });
  });
});
