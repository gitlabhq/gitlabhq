import Vue from 'vue';

import axios from '~/lib/utils/axios_utils';
import deleteMilestoneModal from '~/pages/milestones/shared/components/delete_milestone_modal.vue';
import eventHub from '~/pages/milestones/shared/event_hub';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('delete_milestone_modal.vue', () => {
  const Component = Vue.extend(deleteMilestoneModal);
  const props = {
    issueCount: 1,
    mergeRequestCount: 2,
    milestoneId: 3,
    milestoneTitle: 'my milestone title',
    milestoneUrl: `${gl.TEST_HOST}/delete_milestone_modal.vue/milestone`,
  };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('onSubmit', () => {
    beforeEach(() => {
      vm = mountComponent(Component, props);
      spyOn(eventHub, '$emit');
    });

    it('deletes milestone and redirects to overview page', (done) => {
      const responseURL = `${gl.TEST_HOST}/delete_milestone_modal.vue/milestoneOverview`;
      spyOn(axios, 'delete').and.callFake((url) => {
        expect(url).toBe(props.milestoneUrl);
        expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestStarted', props.milestoneUrl);
        eventHub.$emit.calls.reset();
        return Promise.resolve({
          request: {
            responseURL,
          },
        });
      });
      const redirectSpy = spyOnDependency(deleteMilestoneModal, 'redirectTo');

      vm.onSubmit()
      .then(() => {
        expect(redirectSpy).toHaveBeenCalledWith(responseURL);
        expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestFinished', { milestoneUrl: props.milestoneUrl, successful: true });
      })
      .then(done)
      .catch(done.fail);
    });

    it('displays error if deleting milestone failed', (done) => {
      const dummyError = new Error('deleting milestone failed');
      dummyError.response = { status: 418 };
      spyOn(axios, 'delete').and.callFake((url) => {
        expect(url).toBe(props.milestoneUrl);
        expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestStarted', props.milestoneUrl);
        eventHub.$emit.calls.reset();
        return Promise.reject(dummyError);
      });
      const redirectSpy = spyOnDependency(deleteMilestoneModal, 'redirectTo');

      vm.onSubmit()
        .catch((error) => {
          expect(error).toBe(dummyError);
          expect(redirectSpy).not.toHaveBeenCalled();
          expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestFinished', { milestoneUrl: props.milestoneUrl, successful: false });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('text', () => {
    it('contains the issue and milestone count', () => {
      vm = mountComponent(Component, props);
      const value = vm.text;

      expect(value).toContain('remove it from 1 issue and 2 merge requests');
    });

    it('contains neither issue nor milestone count', () => {
      vm = mountComponent(Component, { ...props,
        issueCount: 0,
        mergeRequestCount: 0,
      });

      const value = vm.text;

      expect(value).toContain('is not currently used');
    });
  });
});
