import axios from '~/lib/utils/axios_utils';
import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';

import * as urlUtility from '~/lib/utils/url_utility';
import deleteTagModal from '~/pages/projects/tags/shared/components/delete_tag_modal.vue';
import eventHub from '~/pages/projects/tags/shared/event_hub';

import mountComponent from '../../../../../helpers/vue_mount_component_helper';

describe('delete_tag_modal.vue', () => {
  const Component = Vue.extend(deleteTagModal);
  const props = {
    tagName: 'samstag',
    url: `${gl.TEST_HOST}/delete_tag_modal.vue/tag`,
    redirectUrl: `${gl.TEST_HOST}/delete_tag_modal.vue/redirect`,
  };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('canSubmit', () => {
      beforeEach(() => {
        vm = mountComponent(Component, props);
      });

      it('returns true if confirmation input has correct value', () => {
        const confirmationInput = vm.$refs.confirmation;
        spyOn(confirmationInput, 'hasCorrectValue').and.returnValue(true);

        expect(vm.canSubmit()).toBe(true);
      });

      it('returns false if confirmation input has correct value', () => {
        const confirmationInput = vm.$refs.confirmation;
        spyOn(confirmationInput, 'hasCorrectValue').and.returnValue(false);

        expect(vm.canSubmit()).toBe(false);
      });
    });

    describe('onSubmit', () => {
      let axiosMock;

      beforeEach(() => {
        spyOn(eventHub, '$emit');
        axiosMock = new MockAdapter(axios);
        vm = mountComponent(Component, props);
      });

      afterEach(() => {
        axiosMock.restore();
      });

      it('deletes tag and redirects to overview page', (done) => {
        axiosMock.onDelete(props.ur).replyOnce(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('deleteTagModal.requestStarted', props.ur);
          eventHub.$emit.calls.reset();
          return [204];
        });
        const redirectSpy = spyOn(urlUtility, 'redirectTo');

        vm.onSubmit()
          .then(() => {
            expect(eventHub.$emit).toHaveBeenCalledWith('deleteTagModal.requestFinished', { url: props.url, successful: true });
            expect(redirectSpy).toHaveBeenCalledWith(props.redirectUrl);
          })
          .then(done)
          .catch(done.fail);
      });

      it('displays error if deleting tag failed', (done) => {
        const dummyError = { message: 'deleting milestone failed' };
        axiosMock.onDelete(props.ur).replyOnce(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('deleteTagModal.requestStarted', props.ur);
          eventHub.$emit.calls.reset();
          return [418, dummyError];
        });
        const redirectSpy = spyOn(urlUtility, 'redirectTo');

        vm.onSubmit()
          .catch((error) => {
            expect(error.response.data).toEqual(dummyError);
            expect(eventHub.$emit).toHaveBeenCalledWith('deleteTagModal.requestFinished', { url: props.url, successful: false });
            expect(redirectSpy).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
