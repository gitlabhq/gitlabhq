import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

import updateUsername from '~/profile/account/components/update_username.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

fdescribe('UpdateUsername component', () => {
  const rootUrl = gl.TEST_HOST;
  const actionUrl = `${gl.TEST_HOST}/update/username`;
  const username = 'hasnoname';
  const modalSelector = '#modal-username-change-confirmation';
  let Component;
  let vm;
  let axiosMock;

  beforeEach(done => {
    axiosMock = new MockAdapter(axios);
    Component = Vue.extend(updateUsername);
    vm = mountComponent(Component, {
      actionUrl,
      rootUrl,
      initialUsername: username,
    });

    vm.isOpen = true;

    Vue.nextTick()
      .then(done)
      .catch(done.fail);
  });

  afterEach(() => {
    vm.$destroy();
    axiosMock.restore();
  });

  const findElements = () => ({
    input: vm.$el.querySelector('#modal-username-change-input'),
    openModalBtn: vm.$el.querySelector(`[data-target="${modalSelector}"]`),
    modal: vm.$el.querySelector(modalSelector),
    confirmModalBtn: vm.$el.querySelector(`${modalSelector} .btn-warning`),
  });

  it('has a disabled button if the username was not changed', done => {
    const { input, openModalBtn } = findElements();
    input.dispatchEvent(new Event('input'));

    Vue.nextTick()
      .then(() => {
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(input.value);
        expect(openModalBtn).toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('has an enabled button which if the username was changed', done => {
    const { input, openModalBtn } = findElements();
    input.value = 'anything';
    input.dispatchEvent(new Event('input'));

    Vue.nextTick()
      .then(() => {
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(input.value);
        expect(openModalBtn).not.toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('confirmation modal contains proper header and body', done => {
    const newUsername = 'new username';

    const header = vm.$el.querySelector(`${modalSelector} .modal-title`);
    const body = vm.$el.querySelector(`${modalSelector} .modal-body`);

    vm.newUsername = newUsername;

    Vue.nextTick()
      .then(() => {
        expect(header.textContent).toContain('Change username?');
        expect(body.textContent).toContain(
          `You are going to change the username ${username} to ${newUsername}`,
        );
      })
      .then(done)
      .catch(done.fail);
  });

  it('sets the username after a successful update', done => {
    axiosMock.onPut(actionUrl).replyOnce(() => [200, { message: 'Username changed' }]);

    const newUsername = 'anything';

    const { input, confirmModalBtn } = findElements();
    input.value = newUsername;
    input.dispatchEvent(new Event('input'));

    Vue.nextTick()
      .then(() => {
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(newUsername);
        confirmModalBtn.click();
      })
      .then(Vue.nextTick) // first tick to handle the click event properly
      .then(Vue.nextTick) // second tick to propagate the click username change after success
      .then(() => {
        expect(vm.username).toBe(newUsername);
        expect(vm.newUsername).toBe(newUsername);
      })
      .then(done)
      .catch(done.fail);
  });

  it('does not set the username after a successful update', done => {
    axiosMock.onPut(actionUrl).replyOnce(() => [400, { message: 'Invalid username' }]);

    const newUsername = 'anything.git';

    const { input, confirmModalBtn } = findElements();
    input.value = newUsername;
    input.dispatchEvent(new Event('input'));

    Vue.nextTick()
      .then(() => {
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(newUsername);
        confirmModalBtn.click();
      })
      .then(Vue.nextTick) // first tick to handle the click event properly
      .then(Vue.nextTick) // second tick to propagate the click username change after success
      .then(() => {
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(newUsername);
      })
      .then(done)
      .catch(done.fail);
  });
});
