import Vue from 'vue';
import deleteLabelModal from '~/pages/labels/components/delete_label_modal.vue';
import eventHub from '~/pages/labels/event_hub';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('Delete label modal component', () => {
  let vm;
  let Component;
  const labelMockData = {
    labelTitle: 'Test',
    openMergeRequestCount: 1,
    openIssuesCount: 2,
    url: `${gl.TEST_HOST}/dummy/endpoint`,
  };

  beforeEach(() => {
    Component = Vue.extend(deleteLabelModal);
  });

  describe('Computed props', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...labelMockData,
      });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('modalTitle', () => {
      expect(vm.modalTitle).toEqual(`Delete label ‘${labelMockData.labelTitle}’?`);
    });

    it('modalDescription', () => {
      expect(vm.modalDescription).toContain(labelMockData.labelTitle);
      expect(vm.modalDescription).toContain(labelMockData.openMergeRequestCount);
      expect(vm.modalDescription).toContain(labelMockData.openIssuesCount);
    });
  });

  describe('When requesting a label delete', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...labelMockData,
      });
      spyOn(eventHub, '$emit');
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should redirect when a label is deleted', (done) => {
      const responseURL = `${gl.TEST_HOST}/dummy/endpoint`;
      spyOn(axios, 'delete').and.callFake((url) => {
        expect(url).toBe(labelMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith('deleteLabelModal.requestStarted', labelMockData.url);
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
          expect(eventHub.$emit).toHaveBeenCalledWith('deleteLabelModal.requestFinished', { labelUrl: labelMockData.url, successful: true });
        })
        .then(done)
        .catch(done.fail);
    });

    it('displays an error if deleting a label failed', (done) => {
      const dummyError = new Error('deleting label failed');
      dummyError.response = { status: 500 };
      spyOn(axios, 'delete').and.callFake((url) => {
        expect(url).toBe(labelMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith('deleteLabelModal.requestStarted', labelMockData.url);
        return Promise.reject(dummyError);
      });
      const redirectSpy = spyOn(urlUtility, 'redirectTo');

      vm.onSubmit()
        .catch((error) => {
          expect(error).toBe(dummyError);
          expect(redirectSpy).not.toHaveBeenCalled();
          expect(eventHub.$emit).toHaveBeenCalledWith('deleteLabelModal.requestFinished', { labelUrl: labelMockData.url, successful: false });
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
