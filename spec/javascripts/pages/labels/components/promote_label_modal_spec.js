import Vue from 'vue';
import promoteLabelModal from '~/pages/projects/labels/components/promote_label_modal.vue';
import eventHub from '~/pages/projects/labels/event_hub';
import axios from '~/lib/utils/axios_utils';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('Promote label modal', () => {
  let vm;
  const Component = Vue.extend(promoteLabelModal);
  const labelMockData = {
    labelTitle: 'Documentation',
    labelColor: '#5cb85c',
    labelTextColor: '#ffffff',
    url: `${gl.TEST_HOST}/dummy/promote/labels`,
  };

  describe('Modal title and description', () => {
    beforeEach(() => {
      vm = mountComponent(Component, labelMockData);
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('contains the proper description', () => {
      expect(vm.text).toContain('Promoting this label will make it available for all projects inside the group');
    });

    it('contains a label span with the color', () => {
      const labelFromTitle = vm.$el.querySelector('.modal-header .label.color-label');

      expect(labelFromTitle.style.backgroundColor).not.toBe(null);
      expect(labelFromTitle.textContent).toContain(vm.labelTitle);
    });
  });

  describe('When requesting a label promotion', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...labelMockData,
      });
      spyOn(eventHub, '$emit');
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('redirects when a label is promoted', (done) => {
      const responseURL = `${gl.TEST_HOST}/dummy/endpoint`;
      spyOn(axios, 'post').and.callFake((url) => {
        expect(url).toBe(labelMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestStarted', labelMockData.url);
        return Promise.resolve({
          request: {
            responseURL,
          },
        });
      });

      vm.onSubmit()
        .then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestFinished', { labelUrl: labelMockData.url, successful: true });
        })
        .then(done)
        .catch(done.fail);
    });

    it('displays an error if promoting a label failed', (done) => {
      const dummyError = new Error('promoting label failed');
      dummyError.response = { status: 500 };
      spyOn(axios, 'post').and.callFake((url) => {
        expect(url).toBe(labelMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestStarted', labelMockData.url);
        return Promise.reject(dummyError);
      });

      vm.onSubmit()
        .catch((error) => {
          expect(error).toBe(dummyError);
          expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestFinished', { labelUrl: labelMockData.url, successful: false });
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
