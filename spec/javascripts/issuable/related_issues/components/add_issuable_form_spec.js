import Vue from 'vue';
import eventHub from '~/issuable/related_issues/event_hub';
import addIssuableForm from '~/issuable/related_issues/components/add_issuable_form.vue';

const issuable1 = {
  id: '200',
  reference: 'foo/bar#123',
  displayReference: '#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

const issuable2 = {
  id: '201',
  reference: 'foo/bar#124',
  displayReference: '#124',
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
      // Avoid any NPE errors from `@blur` being called
      // after `vm.$destroy` in tests, https://github.com/vuejs/vue/issues/5829
      document.activeElement.blur();

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
          pendingReferences: [
            issuable1.reference,
            issuable2.reference,
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
    });

    afterEach(() => {
      eventHub.$off('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$off('addIssuableFormBlur', addIssuableFormBlurSpy);
      eventHub.$off('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$off('addIssuableFormCancel', addIssuableFormCancelSpy);
    });

    it('when clicking somewhere on the input wrapper should focus the input', (done) => {
      vm.onInputWrapperClick();

      setTimeout(() => {
        Vue.nextTick(() => {
          expect(vm.$refs.issuableFormWrapper.classList.contains('focus')).toEqual(true);
          expect(document.activeElement).toEqual(vm.$refs.input);

          done();
        });
      });
    });

    it('when filling in the input', () => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onInput();

      expect(addIssuableFormInputSpy).toHaveBeenCalledWith(newInputValue, newInputValue.length);
    });

    it('when blurring the input', (done) => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onBlur();

      setTimeout(() => {
        Vue.nextTick(() => {
          expect(vm.$refs.issuableFormWrapper.classList.contains('focus')).toEqual(false);
          expect(addIssuableFormBlurSpy).toHaveBeenCalledWith(newInputValue);

          done();
        });
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
