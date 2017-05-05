import Vue from 'vue';
import eventHub from '~/issuable/related_issues/event_hub';
import addIssuableForm from '~/issuable/related_issues/components/add_issuable_form.vue';

const issuable1 = {
  reference: 'foo/bar#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

const issuable2 = {
  reference: 'foo/bar#124',
  title: 'some other thing',
  path: '/foo/bar/issues/124',
  state: 'opened',
};

describe('AddIssuableForm', () => {
  let AddIssuableForm;
  let vm;

  beforeEach(() => {
    AddIssuableForm = Vue.extend(addIssuableForm);
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with data', () => {
    const inputValue = 'foo #123';
    const addButtonLabel = 'Add issuable';

    beforeEach(() => {
      vm = new AddIssuableForm({
        propsData: {
          inputValue,
          addButtonLabel,
          pendingIssuables: [
            issuable1,
            issuable2,
          ],
        },
      }).$mount();
    });

    it('should put button label in place', () => {
      expect(vm.$refs.addButton.textContent.trim()).toEqual(addButtonLabel);
    });

    it('should put input value in place', () => {
      expect(vm.$refs.input.value).toEqual(inputValue);
    });

    it('should render pending issuables items', () => {
      expect(vm.$el.querySelectorAll('.js-add-issuable-form-token-list-item').length).toEqual(2);
    });
  });

  describe('methods', () => {
    let addIssuableFormInputSpy;
    let addIssuableFormBlurSpy;
    let addIssuableFormSubmitSpy;
    let addIssuableFormCancelSpy;

    beforeEach(() => {
      addIssuableFormInputSpy = jasmine.createSpy('spy');
      addIssuableFormBlurSpy = jasmine.createSpy('spy');
      addIssuableFormSubmitSpy = jasmine.createSpy('spy');
      addIssuableFormCancelSpy = jasmine.createSpy('spy');
      eventHub.$on('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$on('addIssuableFormBlur', addIssuableFormBlurSpy);
      eventHub.$on('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$on('addIssuableFormCancel', addIssuableFormCancelSpy);

      const el = document.createElement('div');
      // We need to append to body to get focus tests working
      document.body.appendChild(el);

      vm = new AddIssuableForm({
        propsData: {
          inputValue: '',
          addButtonLabel: 'Add issuable',
          pendingIssuables: [
            issuable1,
          ],
        },
      }).$mount(el);
      spyOn(vm, 'onInputWrapperClick').and.callThrough();
    });

    afterEach(() => {
      eventHub.$off('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$off('addIssuableFormBlur', addIssuableFormBlurSpy);
      eventHub.$off('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$off('addIssuableFormCancel', addIssuableFormCancelSpy);
    });

    it('when clicking somewhere on the input wrapper should focus the input', () => {
      expect(vm.onInputWrapperClick).not.toHaveBeenCalled();

      vm.$refs.issuableFormWrapper.click();

      Vue.nextTick(() => {
        expect(vm.$refs.issuableFormWrapper.classList.contains('focus')).toEqual(true);
        expect(vm.onInputWrapperClick).toHaveBeenCalled();
        expect(document.activeElement).toEqual(vm.$refs.input);
      });
    });

    it('when filling in the input', () => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onInput();

      expect(addIssuableFormInputSpy).toHaveBeenCalledWith(newInputValue, newInputValue.length);
    });

    it('when blurring the input', () => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onBlur();

      Vue.nextTick(() => {
        expect(vm.$refs.issuableFormWrapper.classList.contains('focus')).toEqual(false);
        expect(addIssuableFormBlurSpy).toHaveBeenCalledWith(newInputValue);
      });
    });

    it('when submitting pending issues', () => {
      expect(addIssuableFormSubmitSpy).not.toHaveBeenCalled();

      vm.onFormSubmit();

      expect(addIssuableFormSubmitSpy).toHaveBeenCalled();
    });

    it('when canceling form to collapse', () => {
      expect(addIssuableFormCancelSpy).not.toHaveBeenCalled();

      vm.onFormCancel();

      expect(addIssuableFormCancelSpy).toHaveBeenCalled();
    });
  });
});
