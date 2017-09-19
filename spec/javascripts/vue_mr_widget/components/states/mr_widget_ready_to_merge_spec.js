import Vue from 'vue';
import readyToMergeComponent from '~/vue_merge_request_widget/components/states/mr_widget_ready_to_merge';
import eventHub from '~/vue_merge_request_widget/event_hub';
import * as simplePoll from '~/lib/utils/simple_poll';

const commitMessage = 'This is the commit message';
const commitMessageWithDescription = 'This is the commit message description';
const createComponent = (customConfig = {}) => {
  const Component = Vue.extend(readyToMergeComponent);
  const mr = {
    isPipelineActive: false,
    pipeline: null,
    isPipelineFailed: false,
    isPipelinePassing: false,
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

describe('MRWidgetReadyToMerge', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  describe('props', () => {
    it('should have props', () => {
      const { mr, service } = readyToMergeComponent.props;

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

    describe('mergeButtonClass', () => {
      const defaultClass = 'btn btn-small btn-success accept-merge-request';
      const failedClass = `${defaultClass} btn-danger`;
      const inActionClass = `${defaultClass} btn-info`;

      it('should return default class', () => {
        vm.mr.pipeline = true;
        expect(vm.mergeButtonClass).toEqual(defaultClass);
      });

      it('should return failed class when MR has CI but also has an unknown status', () => {
        vm.mr.hasCI = true;
        expect(vm.mergeButtonClass).toEqual(failedClass);
      });

      it('should return default class when MR has no pipeline', () => {
        expect(vm.mergeButtonClass).toEqual(defaultClass);
      });

      it('should return in action class when pipeline is active', () => {
        vm.mr.pipeline = {};
        vm.mr.isPipelineActive = true;
        expect(vm.mergeButtonClass).toEqual(inActionClass);
      });

      it('should return failed class when pipeline is failed', () => {
        vm.mr.pipeline = {};
        vm.mr.isPipelineFailed = true;
        expect(vm.mergeButtonClass).toEqual(failedClass);
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
        expect(vm.isMergeButtonDisabled).toBeFalsy();
      });

      it('should return true when there is no commit message', () => {
        vm.commitMessage = '';
        expect(vm.isMergeButtonDisabled).toBeTruthy();
      });

      it('should return true if merge is not allowed', () => {
        vm.mr.onlyAllowMergeIfPipelineSucceeds = true;
        vm.mr.isPipelineFailed = true;
        expect(vm.isMergeButtonDisabled).toBeTruthy();
      });

      it('should return true when there vm instance is making request', () => {
        vm.isMakingRequest = true;
        expect(vm.isMergeButtonDisabled).toBeTruthy();
      });
    });

    describe('Remove source branch checkbox', () => {
      describe('when user can merge but cannot delete branch', () => {
        it('isRemoveSourceBranchButtonDisabled should be true', () => {
          expect(vm.isRemoveSourceBranchButtonDisabled).toBe(true);
        });

        it('should be disabled in the rendered output', () => {
          const checkboxElement = vm.$el.querySelector('#remove-source-branch-input');
          expect(checkboxElement.getAttribute('disabled')).toBe('disabled');
        });
      });

      describe('when user can merge and can delete branch', () => {
        beforeEach(() => {
          this.customVm = createComponent({
            mr: { canRemoveSourceBranch: true },
          });
        });

        it('isRemoveSourceBranchButtonDisabled should be false', () => {
          expect(this.customVm.isRemoveSourceBranchButtonDisabled).toBe(false);
        });

        it('should be enabled in rendered output', () => {
          const checkboxElement = this.customVm.$el.querySelector('#remove-source-branch-input');
          expect(checkboxElement.getAttribute('disabled')).toBeNull();
        });
      });
    });
  });

  describe('methods', () => {
    describe('isMergeAllowed', () => {
      it('should return true when no pipeline and not required to succeed', () => {
        vm.mr.onlyAllowMergeIfPipelineSucceeds = false;
        vm.mr.isPipelinePassing = false;
        expect(vm.isMergeAllowed()).toBeTruthy();
      });

      it('should return true when pipeline failed and not required to succeed', () => {
        vm.mr.onlyAllowMergeIfPipelineSucceeds = false;
        vm.mr.isPipelinePassing = false;
        expect(vm.isMergeAllowed()).toBeTruthy();
      });

      it('should return false when pipeline failed and required to succeed', () => {
        vm.mr.onlyAllowMergeIfPipelineSucceeds = true;
        vm.mr.isPipelinePassing = false;
        expect(vm.isMergeAllowed()).toBeFalsy();
      });

      it('should return true when pipeline succeeded and required to succeed', () => {
        vm.mr.onlyAllowMergeIfPipelineSucceeds = true;
        vm.mr.isPipelinePassing = true;
        expect(vm.isMergeAllowed()).toBeTruthy();
      });
    });

    describe('shouldShowMergeControls', () => {
      it('should return false when an external pipeline is running and required to succeed', () => {
        spyOn(vm, 'isMergeAllowed').and.returnValue(false);
        vm.mr.isPipelineActive = false;
        expect(vm.shouldShowMergeControls()).toBeFalsy();
      });

      it('should return true when the build succeeded or build not required to succeed', () => {
        spyOn(vm, 'isMergeAllowed').and.returnValue(true);
        vm.mr.isPipelineActive = false;
        expect(vm.shouldShowMergeControls()).toBeTruthy();
      });

      it('should return true when showing the MWPS button and a pipeline is running that needs to be successful', () => {
        spyOn(vm, 'isMergeAllowed').and.returnValue(false);
        vm.mr.isPipelineActive = true;
        expect(vm.shouldShowMergeControls()).toBeTruthy();
      });

      it('should return true when showing the MWPS button but not required for the pipeline to succeed', () => {
        spyOn(vm, 'isMergeAllowed').and.returnValue(true);
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
          json() {
            return { status };
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
        spyOn(simplePoll, 'default');
        vm.initiateMergePolling();
        expect(simplePoll.default).toHaveBeenCalled();
      });
    });

    describe('handleMergePolling', () => {
      const returnPromise = state => new Promise((resolve) => {
        resolve({
          json() {
            return { state, source_branch_exists: true };
          },
        });
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
        spyOn(simplePoll, 'default');

        vm.initiateRemoveSourceBranchPolling();
        expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [true]);
        expect(simplePoll.default).toHaveBeenCalled();
      });
    });

    describe('handleRemoveBranchPolling', () => {
      const returnPromise = state => new Promise((resolve) => {
        resolve({
          json() {
            return { source_branch_exists: state };
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
});
