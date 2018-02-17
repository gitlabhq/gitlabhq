import Vue from 'vue';
import promoteMilestoneModal from '~/pages/milestones/shared/components/promote_milestone_modal.vue';
import eventHub from '~/pages/milestones/shared/event_hub';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import mountComponent from '../../../../helpers/vue_mount_component_helper';

describe('Promote milestone modal', () => {
  let vm;
  let Component;
  const milestoneMockData = {
    milestoneTitle: 'v1.0',
    url: `${gl.TEST_HOST}/dummy/endpoint`,
  };

  beforeEach(() => {
    Component = Vue.extend(promoteMilestoneModal);
  });

  describe('Modal title and description', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...milestoneMockData,
      });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should contain the proper description', () => {
      expect(vm.text).toContain('Promoting this milestone will make it available for all projects inside the group.');
      expect(vm.text).toContain('Existing project milestones with the same name will be merged.');
      expect(vm.text).toContain('This action cannot be reversed.');
    });

    it('should contain the correct title', () => {
      expect(vm.title).toEqual('Promote v1.0 to group milestone?');
    });
  });

  describe('When requesting a milestone promotion', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...milestoneMockData,
      });
      spyOn(eventHub, '$emit');
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should redirect when a milestone is promoted', (done) => {
      const responseURL = `${gl.TEST_HOST}/dummy/endpoint`;
      spyOn(axios, 'post').and.callFake((url) => {
        expect(url).toBe(milestoneMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith('promoteMilestoneModal.requestStarted', milestoneMockData.url);
        return Promise.resolve({
          request: {
            responseURL,
          },
        });
      });
      const redirectSpy = spyOn(urlUtility, 'redirectTo');

      vm.onSubmit()
        .then(() => {
          expect(redirectSpy).toHaveBeenCalledWith(responseURL);
        })
        .then(done)
        .catch(done.fail);
    });

    it('displays an error if promoting a milestone failed', (done) => {
      const dummyError = new Error('promoting milestone failed');
      dummyError.response = { status: 500 };
      spyOn(axios, 'post').and.callFake((url) => {
        expect(url).toBe(milestoneMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith('promoteMilestoneModal.requestStarted', milestoneMockData.url);
        return Promise.reject(dummyError);
      });
      const redirectSpy = spyOn(urlUtility, 'redirectTo');

      vm.onSubmit()
        .catch((error) => {
          expect(error).toBe(dummyError);
          expect(redirectSpy).not.toHaveBeenCalled();
          expect(eventHub.$emit).toHaveBeenCalledWith('promoteMilestoneModal.requestFinished', { milestoneUrl: milestoneMockData.url, successful: false });
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
