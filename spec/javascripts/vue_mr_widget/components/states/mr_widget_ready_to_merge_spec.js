import Vue from 'vue';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

const commitMessage = 'This is the commit message';
const commitMessageWithDescription = 'This is the commit message description';
const createComponent = (customConfig = {}) => {
  const Component = Vue.extend(ReadyToMerge);
  const mr = {
    isPipelineActive: false,
    pipeline: null,
    isPipelineFailed: false,
    isPipelinePassing: false,
    isMergeAllowed: true,
    onlyAllowMergeIfPipelineSucceeds: false,
    hasCI: false,
    ciStatus: null,
    sha: '12345678',
    commitMessage,
    commitMessageWithDescription,
    shouldRemoveSourceBranch: true,
    canRemoveSourceBranch: false,
  };

  Object.assign(mr, customConfig.mr);

  const service = {
    merge() {},
    poll() {},
  };

  return new Component({
    el: document.createElement('div'),
    propsData: { mr, service },
  });
};

describe('ReadyToMerge', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('props', () => {
    it('should have props', () => {
      const { mr, service } = ReadyToMerge.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();

      expect(service.type instanceof Object).toBeTruthy();
      expect(service.required).toBeTruthy();
    });
  });

  describe('data', () => {
    it('should have default data', () => {
      expect(vm.mergeWhenBuildSucceeds).toBeFalsy();
      expect(vm.useCommitMessageWithDescription).toBeFalsy();
      expect(vm.setToMergeWhenPipelineSucceeds).toBeFalsy();
      expect(vm.showCommitMessageEditor).toBeFalsy();
      expect(vm.isMakingRequest).toBeFalsy();
      expect(vm.isMergingImmediately).toBeFalsy();
      expect(vm.commitMessage).toBe(vm.mr.commitMessage);
      expect(vm.successSvg).toBeDefined();
      expect(vm.warningSvg).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('shouldShowMergeWhenPipelineSucceedsText', () => {
      it('should return true with active pipeline', () => {
        vm.mr.isPipelineActive = true;
        expect(vm.shouldShowMergeWhenPipelineSucceedsText).toBeTruthy();
      });

      it('should return false with inactive pipeline', () => {
        vm.mr.isPipelineActive = false;
        expect(vm.shouldShowMergeWhenPipelineSucceedsText).toBeFalsy();
      });
    });

    describe('commitMessageLinkTitle', () => {
      const withDesc = 'Include description in commit message';
      const withoutDesc = "Don't include description in commit message";

      it('should return message with description', () => {
        expect(vm.commitMessageLinkTitle).toEqual(withDesc);
      });

      it('should return message without description', () => {
        vm.useCommitMessageWithDescription = true;
        expect(vm.commitMessageLinkTitle).toEqual(withoutDesc);
      });
    });

    describe('status', () => {
      it('defaults to success', () => {
        vm.mr.pipeline = true;
        expect(vm.status).toEqual('success');
      });

      it('returns failed when MR has CI but also has an unknown status', () => {
        vm.mr.hasCI = true;
        expect(vm.status).toEqual('failed');
      });

      it('returns default when MR has no pipeline', () => {
        expect(vm.status).toEqual('success');
      });

      it('returns pending when pipeline is active', () => {
        vm.mr.pipeline = {};
        vm.mr.isPipelineActive = true;
        expect(vm.status).toEqual('pending');
      });

      it('returns failed when pipeline is failed', () => {
        vm.mr.pipeline = {};
        vm.mr.isPipelineFailed = true;
        expect(vm.status).toEqual('failed');
      });
    });

    describe('mergeButtonClass', () => {
      const defaultClass = 'btn btn-sm btn-success accept-merge-request';
      const failedClass = `${defaultClass} btn-danger`;
      const inActionClass = `${defaultClass} btn-info`;

      it('defaults to success class', () => {
        expect(vm.mergeButtonClass).toEqual(defaultClass);
      });

      it('returns success class for success status', () => {
        vm.mr.pipeline = true;
        expect(vm.mergeButtonClass).toEqual(defaultClass);
      });

      it('returns info class for pending status', () => {
        vm.mr.pipeline = {};
        vm.mr.isPipelineActive = true;
        expect(vm.mergeButtonClass).toEqual(inActionClass);
      });

      it('returns failed class for failed status', () => {
        vm.mr.hasCI = true;
        expect(vm.mergeButtonClass).toEqual(failedClass);
      });
    });

    describe('status icon', () => {
      it('defaults to tick icon', () => {
        expect(vm.iconClass).toEqual('success');
      });

      it('shows tick for success status', () => {
        vm.mr.pipeline = true;
        expect(vm.iconClass).toEqual('success');
      });

      it('shows tick for pending status', () => {
        vm.mr.pipeline = {};
        vm.mr.isPipelineActive = true;
        expect(vm.iconClass).toEqual('success');
      });

      it('shows warning icon for failed status', () => {
        vm.mr.hasCI = true;
        expect(vm.iconClass).toEqual('warning');
      });

      it('shows warning icon for merge not allowed', () => {
        vm.mr.hasCI = true;
        expect(vm.iconClass).toEqual('warning');
      });
    });

    describe('mergeButtonText', () => {
      it('should return Merge', () => {
        expect(vm.mergeButtonText).toEqual('Merge');
      });

      it('should return Merge in progress', () => {
        vm.isMergingImmediately = true;
        expect(vm.mergeButtonText).toEqual('Merge in progress');
      });

      it('should return Merge when pipeline succeeds', () => {
        vm.isMergingImmediately = false;
        vm.mr.isPipelineActive = true;
        expect(vm.mergeButtonText).toEqual('Merge when pipeline succeeds');
      });
    });

    describe('shouldShowMergeOptionsDropdown', () => {
      it('should return false with initial data', () => {
        expect(vm.shouldShowMergeOptionsDropdown).toBeFalsy();
      });

      it('should return true when pipeline active', () => {
        vm.mr.isPipelineActive = true;
        expect(vm.shouldShowMergeOptionsDropdown).toBeTruthy();
      });

      it('should return false when pipeline active but only merge when pipeline succeeds set in project options', () => {
        vm.mr.isPipelineActive = true;
        vm.mr.onlyAllowMergeIfPipelineSucceeds = true;
        expect(vm.shouldShowMergeOptionsDropdown).toBeFalsy();
      });
    });

    describe('isMergeButtonDisabled', () => {
      it('should return false with initial data', () => {
        vm.mr.isMergeAllowed = true;
        expect(vm.isMergeButtonDisabled).toBeFalsy();
      });

      it('should return true when there is no commit message', () => {
        vm.mr.isMergeAllowed = true;
        vm.commitMessage = '';
        expect(vm.isMergeButtonDisabled).toBeTruthy();
      });

      it('should return true if merge is not allowed', () => {
        vm.mr.isMergeAllowed = false;
        vm.mr.onlyAllowMergeIfPipelineSucceeds = true;
        expect(vm.isMergeButtonDisabled).toBeTruthy();
      });

      it('should return true when the vm instance is making request', () => {
        vm.mr.isMergeAllowed = true;
        vm.isMakingRequest = true;
        expect(vm.isMergeButtonDisabled).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('shouldShowMergeControls', () => {
      it('should return false when an external pipeline is running and required to succeed', () => {
        vm.mr.isMergeAllowed = false;
        vm.mr.isPipelineActive = false;
        expect(vm.shouldShowMergeControls()).toBeFalsy();
      });

      it('should return true when the build succeeded or build not required to succeed', () => {
        vm.mr.isMergeAllowed = true;
        vm.mr.isPipelineActive = false;
        expect(vm.shouldShowMergeControls()).toBeTruthy();
      });

      it('should return true when showing the MWPS button and a pipeline is running that needs to be successful', () => {
        vm.mr.isMergeAllowed = false;
        vm.mr.isPipelineActive = true;
        expect(vm.shouldShowMergeControls()).toBeTruthy();
      });

      it('should return true when showing the MWPS button but not required for the pipeline to succeed', () => {
        vm.mr.isMergeAllowed = true;
        vm.mr.isPipelineActive = true;
        expect(vm.shouldShowMergeControls()).toBeTruthy();
      });
    });

    describe('updateCommitMessage', () => {
      it('should revert flag and change commitMessage', () => {
        expect(vm.useCommitMessageWithDescription).toBeFalsy();
        expect(vm.commitMessage).toEqual(commitMessage);
        vm.updateCommitMessage();
        expect(vm.useCommitMessageWithDescription).toBeTruthy();
        expect(vm.commitMessage).toEqual(commitMessageWithDescription);
        vm.updateCommitMessage();
        expect(vm.useCommitMessageWithDescription).toBeFalsy();
        expect(vm.commitMessage).toEqual(commitMessage);
      });
    });

    describe('toggleCommitMessageEditor', () => {
      it('should toggle showCommitMessageEditor flag', () => {
        expect(vm.showCommitMessageEditor).toBeFalsy();
        vm.toggleCommitMessageEditor();
        expect(vm.showCommitMessageEditor).toBeTruthy();
      });
    });

    describe('handleMergeButtonClick', () => {
      const returnPromise = status => new Promise((resolve) => {
        resolve({
          data: {
            status,
          },
        });
      });

      it('should handle merge when pipeline succeeds', (done) => {
        spyOn(eventHub, '$emit');
        spyOn(vm.service, 'merge').and.returnValue(returnPromise('merge_when_pipeline_succeeds'));
        vm.removeSourceBranch = false;
        vm.handleMergeButtonClick(true);

        setTimeout(() => {
          expect(vm.setToMergeWhenPipelineSucceeds).toBeTruthy();
          expect(vm.isMakingRequest).toBeTruthy();
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');

          const params = vm.service.merge.calls.argsFor(0)[0];
          expect(params.sha).toEqual(vm.mr.sha);
          expect(params.commit_message).toEqual(vm.mr.commitMessage);
          expect(params.should_remove_source_branch).toBeFalsy();
          expect(params.merge_when_pipeline_succeeds).toBeTruthy();
          done();
        }, 333);
      });

      it('should handle merge failed', (done) => {
        spyOn(eventHub, '$emit');
        spyOn(vm.service, 'merge').and.returnValue(returnPromise('failed'));
        vm.handleMergeButtonClick(false, true);

        setTimeout(() => {
          expect(vm.setToMergeWhenPipelineSucceeds).toBeFalsy();
          expect(vm.isMakingRequest).toBeTruthy();
          expect(eventHub.$emit).toHaveBeenCalledWith('FailedToMerge', undefined);

          const params = vm.service.merge.calls.argsFor(0)[0];
          expect(params.should_remove_source_branch).toBeTruthy();
          expect(params.merge_when_pipeline_succeeds).toBeFalsy();
          done();
        }, 333);
      });

      it('should handle merge action accepted case', (done) => {
        spyOn(vm.service, 'merge').and.returnValue(returnPromise('success'));
        spyOn(vm, 'initiateMergePolling');
        vm.handleMergeButtonClick();

        setTimeout(() => {
          expect(vm.setToMergeWhenPipelineSucceeds).toBeFalsy();
          expect(vm.isMakingRequest).toBeTruthy();
          expect(vm.initiateMergePolling).toHaveBeenCalled();

          const params = vm.service.merge.calls.argsFor(0)[0];
          expect(params.should_remove_source_branch).toBeTruthy();
          expect(params.merge_when_pipeline_succeeds).toBeFalsy();
          done();
        }, 333);
      });
    });

    describe('initiateMergePolling', () => {
      it('should call simplePoll', () => {
        const simplePoll = spyOnDependency(ReadyToMerge, 'simplePoll');
        vm.initiateMergePolling();
        expect(simplePoll).toHaveBeenCalled();
      });
    });

    describe('handleMergePolling', () => {
      const returnPromise = state => new Promise((resolve) => {
        resolve({
          data: {
            state,
            source_branch_exists: true,
          },
        });
      });

      beforeEach(() => {
        loadFixtures('merge_requests/merge_request_of_current_user.html.raw');
      });

      it('should call start and stop polling when MR merged', (done) => {
        spyOn(eventHub, '$emit');
        spyOn(vm.service, 'poll').and.returnValue(returnPromise('merged'));
        spyOn(vm, 'initiateRemoveSourceBranchPolling');

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        vm.handleMergePolling(() => { cpc = true; }, () => { spc = true; });
        setTimeout(() => {
          expect(vm.service.poll).toHaveBeenCalled();
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          expect(eventHub.$emit).toHaveBeenCalledWith('FetchActionsContent');
          expect(vm.initiateRemoveSourceBranchPolling).toHaveBeenCalled();
          expect(cpc).toBeFalsy();
          expect(spc).toBeTruthy();

          done();
        }, 333);
      });

      it('updates status box', (done) => {
        spyOn(vm.service, 'poll').and.returnValue(returnPromise('merged'));
        spyOn(vm, 'initiateRemoveSourceBranchPolling');

        vm.handleMergePolling(() => {}, () => {});

        setTimeout(() => {
          const statusBox = document.querySelector('.status-box');
          expect(statusBox.classList.contains('status-box-mr-merged')).toBeTruthy();
          expect(statusBox.textContent).toContain('Merged');

          done();
        });
      });

      it('hides close button', (done) => {
        spyOn(vm.service, 'poll').and.returnValue(returnPromise('merged'));
        spyOn(vm, 'initiateRemoveSourceBranchPolling');

        vm.handleMergePolling(() => {}, () => {});

        setTimeout(() => {
          expect(document.querySelector('.btn-close').classList.contains('hidden')).toBeTruthy();

          done();
        });
      });

      it('updates merge request count badge', (done) => {
        spyOn(vm.service, 'poll').and.returnValue(returnPromise('merged'));
        spyOn(vm, 'initiateRemoveSourceBranchPolling');

        vm.handleMergePolling(() => {}, () => {});

        setTimeout(() => {
          expect(document.querySelector('.js-merge-counter').textContent).toBe('0');

          done();
        });
      });

      it('should continue polling until MR is merged', (done) => {
        spyOn(vm.service, 'poll').and.returnValue(returnPromise('some_other_state'));
        spyOn(vm, 'initiateRemoveSourceBranchPolling');

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        vm.handleMergePolling(() => { cpc = true; }, () => { spc = true; });
        setTimeout(() => {
          expect(cpc).toBeTruthy();
          expect(spc).toBeFalsy();

          done();
        }, 333);
      });
    });

    describe('initiateRemoveSourceBranchPolling', () => {
      it('should emit event and call simplePoll', () => {
        spyOn(eventHub, '$emit');
        const simplePoll = spyOnDependency(ReadyToMerge, 'simplePoll');

        vm.initiateRemoveSourceBranchPolling();
        expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [true]);
        expect(simplePoll).toHaveBeenCalled();
      });
    });

    describe('handleRemoveBranchPolling', () => {
      const returnPromise = state => new Promise((resolve) => {
        resolve({
          data: {
            source_branch_exists: state,
          },
        });
      });

      it('should call start and stop polling when MR merged', (done) => {
        spyOn(eventHub, '$emit');
        spyOn(vm.service, 'poll').and.returnValue(returnPromise(false));

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        vm.handleRemoveBranchPolling(() => { cpc = true; }, () => { spc = true; });
        setTimeout(() => {
          expect(vm.service.poll).toHaveBeenCalled();

          const args = eventHub.$emit.calls.argsFor(0);
          expect(args[0]).toEqual('MRWidgetUpdateRequested');
          expect(args[1]).toBeDefined();
          args[1]();
          expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [false]);

          expect(cpc).toBeFalsy();
          expect(spc).toBeTruthy();

          done();
        }, 333);
      });

      it('should continue polling until MR is merged', (done) => {
        spyOn(vm.service, 'poll').and.returnValue(returnPromise(true));

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        vm.handleRemoveBranchPolling(() => { cpc = true; }, () => { spc = true; });
        setTimeout(() => {
          expect(cpc).toBeTruthy();
          expect(spc).toBeFalsy();

          done();
        }, 333);
      });
    });
  });

  describe('Remove source branch checkbox', () => {
    describe('when user can merge but cannot delete branch', () => {
      it('should be disabled in the rendered output', () => {
        const checkboxElement = vm.$el.querySelector('#remove-source-branch-input');
        expect(checkboxElement).toBeNull();
      });
    });

    describe('when user can merge and can delete branch', () => {
      let customVm;

      beforeEach(() => {
        customVm = createComponent({
          mr: { canRemoveSourceBranch: true },
        });
      });

      it('isRemoveSourceBranchButtonDisabled should be false', () => {
        expect(customVm.isRemoveSourceBranchButtonDisabled).toBe(false);
      });

      it('should be enabled in rendered output', () => {
        const checkboxElement = customVm.$el.querySelector('#remove-source-branch-input');
        expect(checkboxElement).not.toBeNull();
      });
    });
  });

  describe('Merge controls', () => {
    describe('when allowed to merge', () => {
      beforeEach(() => {
        vm = createComponent({
          mr: { isMergeAllowed: true, canRemoveSourceBranch: true },
        });
      });

      it('shows remove source branch checkbox', () => {
        expect(vm.$el.querySelector('.js-remove-source-branch-checkbox')).not.toBeNull();
      });

      it('shows modify commit message button', () => {
        expect(vm.$el.querySelector('.js-modify-commit-message-button')).toBeDefined();
      });

      it('does not show message about needing to resolve items', () => {
        expect(vm.$el.querySelector('.js-resolve-mr-widget-items-message')).toBeNull();
      });
    });

    describe('when not allowed to merge', () => {
      beforeEach(() => {
        vm = createComponent({
          mr: { isMergeAllowed: false },
        });
      });

      it('does not show remove source branch checkbox', () => {
        expect(vm.$el.querySelector('.js-remove-source-branch-checkbox')).toBeNull();
      });

      it('does not show  modify commit message button', () => {
        expect(vm.$el.querySelector('.js-modify-commit-message-button')).toBeNull();
      });

      it('shows message to resolve all items before being allowed to merge', () => {
        expect(vm.$el.querySelector('.js-resolve-mr-widget-items-message')).toBeDefined();
      });
    });
  });

  describe('Commit message area', () => {
    it('when using merge commits, should show "Modify commit message" button', () => {
      const customVm = createComponent({
        mr: { ffOnlyEnabled: false },
      });

      expect(customVm.$el.querySelector('.js-fast-forward-message')).toBeNull();
      expect(customVm.$el.querySelector('.js-modify-commit-message-button')).toBeDefined();
    });

    it('when fast-forward merge is enabled, only show fast-forward message', () => {
      const customVm = createComponent({
        mr: { ffOnlyEnabled: true },
      });

      expect(customVm.$el.querySelector('.js-fast-forward-message')).toBeDefined();
      expect(customVm.$el.querySelector('.js-modify-commit-message-button')).toBeNull();
    });
  });
});
