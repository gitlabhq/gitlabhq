import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import axios from '~/lib/utils/axios_utils';
import store from '~/badges/store';
import createEmptyBadge from '~/badges/empty_badge';
import BadgeForm from '~/badges/components/badge_form.vue';
import { DUMMY_IMAGE_URL, TEST_HOST } from '../../test_constants';

// avoid preview background process
BadgeForm.methods.debouncedPreview = () => {};

describe('BadgeForm component', () => {
  const Component = Vue.extend(BadgeForm);
  let axiosMock;
  let vm;

  beforeEach(() => {
    setFixtures(`
      <div id="dummy-element"></div>
    `);

    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$destroy();
    axiosMock.restore();
  });

  describe('methods', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, {
        el: '#dummy-element',
        store,
        props: {
          isEditing: false,
        },
      });
    });

    describe('onCancel', () => {
      it('calls stopEditing', () => {
        spyOn(vm, 'stopEditing');

        vm.onCancel();

        expect(vm.stopEditing).toHaveBeenCalled();
      });
    });
  });

  const sharedSubmitTests = submitAction => {
    const nameSelector = '#badge-name';
    const imageUrlSelector = '#badge-image-url';
    const findImageUrlElement = () => vm.$el.querySelector(imageUrlSelector);
    const linkUrlSelector = '#badge-link-url';
    const findLinkUrlElement = () => vm.$el.querySelector(linkUrlSelector);
    const setValue = (inputElementSelector, value) => {
      const inputElement = vm.$el.querySelector(inputElementSelector);
      inputElement.value = value;
      inputElement.dispatchEvent(new Event('input'));
    };
    const submitForm = () => {
      const submitButton = vm.$el.querySelector('button[type="submit"]');
      submitButton.click();
    };
    const expectInvalidInput = inputElementSelector => {
      const inputElement = vm.$el.querySelector(inputElementSelector);

      expect(inputElement).toBeMatchedBy(':invalid');
      const feedbackElement = vm.$el.querySelector(`${inputElementSelector} + .invalid-feedback`);

      expect(feedbackElement).toBeVisible();
    };

    beforeEach(() => {
      spyOn(vm, submitAction).and.returnValue(Promise.resolve());
      store.replaceState({
        ...store.state,
        badgeInAddForm: createEmptyBadge(),
        badgeInEditForm: createEmptyBadge(),
        isSaving: false,
      });

      setValue(nameSelector, 'TestBadge');
      setValue(linkUrlSelector, `${TEST_HOST}/link/url`);
      setValue(imageUrlSelector, `${window.location.origin}${DUMMY_IMAGE_URL}`);
    });

    it('returns immediately if imageUrl is empty', () => {
      setValue(imageUrlSelector, '');

      submitForm();

      expectInvalidInput(imageUrlSelector);

      expect(vm[submitAction]).not.toHaveBeenCalled();
    });

    it('returns immediately if imageUrl is malformed', () => {
      setValue(imageUrlSelector, 'not-a-url');

      submitForm();

      expectInvalidInput(imageUrlSelector);

      expect(vm[submitAction]).not.toHaveBeenCalled();
    });

    it('returns immediately if linkUrl is empty', () => {
      setValue(linkUrlSelector, '');

      submitForm();

      expectInvalidInput(linkUrlSelector);

      expect(vm[submitAction]).not.toHaveBeenCalled();
    });

    it('returns immediately if linkUrl is malformed', () => {
      setValue(linkUrlSelector, 'not-a-url');

      submitForm();

      expectInvalidInput(linkUrlSelector);

      expect(vm[submitAction]).not.toHaveBeenCalled();
    });

    it(`calls ${submitAction}`, () => {
      submitForm();

      expect(findImageUrlElement()).toBeMatchedBy(':valid');
      expect(findLinkUrlElement()).toBeMatchedBy(':valid');
      expect(vm[submitAction]).toHaveBeenCalled();
    });
  };

  describe('if isEditing is false', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, {
        el: '#dummy-element',
        store,
        props: {
          isEditing: false,
        },
      });
    });

    it('renders one button', () => {
      expect(vm.$el.querySelector('.row-content-block')).toBeNull();
      const buttons = vm.$el.querySelectorAll('.form-group:last-of-type button');

      expect(buttons.length).toBe(1);
      const buttonAddElement = buttons[0];

      expect(buttonAddElement).toBeVisible();
      expect(buttonAddElement).toHaveText('Add badge');
    });

    sharedSubmitTests('addBadge');
  });

  describe('if isEditing is true', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, {
        el: '#dummy-element',
        store,
        props: {
          isEditing: true,
        },
      });
    });

    it('renders two buttons', () => {
      const buttons = vm.$el.querySelectorAll('.row-content-block button');

      expect(buttons.length).toBe(2);
      const buttonSaveElement = buttons[0];

      expect(buttonSaveElement).toBeVisible();
      expect(buttonSaveElement).toHaveText('Save changes');
      const buttonCancelElement = buttons[1];

      expect(buttonCancelElement).toBeVisible();
      expect(buttonCancelElement).toHaveText('Cancel');
    });

    sharedSubmitTests('saveBadge');
  });
});
