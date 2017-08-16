import Vue from 'vue';
import repoCommitSection from '~/repo/components/repo_commit_section.vue';
import RepoStore from '~/repo/stores/repo_store';
import Api from '~/api';

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

  function createComponent(el) {
    const RepoCommitSection = Vue.extend(repoCommitSection);

    return new RepoCommitSection().$mount(el);
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

    // We need to append to body to get form `submit` events working
    // Otherwise we run into, "Form submission canceled because the form is not connected"
    // See https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-submission-algorithm
    const el = document.createElement('div');
    document.body.appendChild(el);

    const vm = createComponent(el);
    const commitMessageEl = vm.$el.querySelector('#commit-message');
    const submitCommit = vm.$refs.submitCommit;

    vm.commitMessage = commitMessage;

    Vue.nextTick(() => {
      expect(commitMessageEl.value).toBe(commitMessage);
      expect(submitCommit.disabled).toBeFalsy();

      spyOn(vm, 'makeCommit').and.callThrough();
      spyOn(Api, 'commitMultiple');

      submitCommit.click();

      Vue.nextTick(() => {
        expect(vm.makeCommit).toHaveBeenCalled();
        expect(submitCommit.querySelector('.fa-spinner.fa-spin')).toBeTruthy();

        const args = Api.commitMultiple.calls.allArgs()[0];
        const { commit_message, actions, branch: payloadBranch } = args[1];

        expect(args[0]).toBe(projectId);
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
  });

  describe('methods', () => {
    describe('resetCommitState', () => {
      it('should reset store vars and scroll to top', () => {
        const vm = {
          submitCommitsLoading: true,
          changedFiles: new Array(10),
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
