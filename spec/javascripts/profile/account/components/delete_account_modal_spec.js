import Vue from 'vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import deleteAccountModal from '~/profile/account/components/delete_account_modal.vue';

describe('DeleteAccountModal component', () => {
  const actionUrl = `${gl.TEST_HOST}/delete/user`;
  const username = 'hasnoname';
  let Component;
  let vm;

  beforeEach(() => {
    Component = Vue.extend(deleteAccountModal);
  });

  afterEach(() => {
    vm.$destroy();
  });

  const findElements = () => {
    const confirmation = vm.confirmWithPassword ? 'password' : 'username';
    return {
      form: vm.$refs.form,
      input: vm.$el.querySelector(`[name="${confirmation}"]`),
      submitButton: vm.$el.querySelector('.btn-danger'),
    };
  };

  describe('with password confirmation', () => {
    beforeEach(done => {
      vm = mountComponent(Component, {
        actionUrl,
        confirmWithPassword: true,
        username,
      });

      vm.isOpen = true;

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('does not accept empty password', done => {
      const { form, input, submitButton } = findElements();
      spyOn(form, 'submit');
      input.value = '';
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredPassword).toBe(input.value);
          expect(submitButton).toHaveAttr('disabled', 'disabled');
          submitButton.click();

          expect(form.submit).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('submits form with password', done => {
      const { form, input, submitButton } = findElements();
      spyOn(form, 'submit');
      input.value = 'anything';
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredPassword).toBe(input.value);
          expect(submitButton).not.toHaveAttr('disabled', 'disabled');
          submitButton.click();

          expect(form.submit).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with username confirmation', () => {
    beforeEach(done => {
      vm = mountComponent(Component, {
        actionUrl,
        confirmWithPassword: false,
        username,
      });

      vm.isOpen = true;

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('does not accept wrong username', done => {
      const { form, input, submitButton } = findElements();
      spyOn(form, 'submit');
      input.value = 'this is wrong';
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredUsername).toBe(input.value);
          expect(submitButton).toHaveAttr('disabled', 'disabled');
          submitButton.click();

          expect(form.submit).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('submits form with correct username', done => {
      const { form, input, submitButton } = findElements();
      spyOn(form, 'submit');
      input.value = username;
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredUsername).toBe(input.value);
          expect(submitButton).not.toHaveAttr('disabled', 'disabled');
          submitButton.click();

          expect(form.submit).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
