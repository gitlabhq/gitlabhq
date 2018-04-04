import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

import updateUsername from '~/profile/account/components/update_username.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

fdescribe('UpdateUsername component', () => {
  const rootUrl = gl.TEST_HOST;
  const actionUrl = `${gl.TEST_HOST}/update/username`;
  const username = 'hasnoname';
  const newUsername = 'new_username';
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
        expect(vm.newUsername).toBe(username);
        expect(openModalBtn).toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('has an enabled button which if the username was changed', done => {
    const { input, openModalBtn } = findElements();
    input.value = newUsername;
    input.dispatchEvent(new Event('input'));

    Vue.nextTick()
      .then(() => {
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(newUsername);
        expect(openModalBtn).not.toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('confirmation modal contains proper header and body', done => {
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

  it('executes API call on confirmation button click', done => {
    axiosMock.onPut(actionUrl).replyOnce(() => [200, { message: 'Username changed' }]);
    const { confirmModalBtn } = findElements();

    vm.newUsername = newUsername;

    spyOn(axios, 'put').and.callThrough();

    Vue.nextTick()
      .then(() => {
        confirmModalBtn.click();
        expect(axios.put).toHaveBeenCalledWith(actionUrl, { user: { username: newUsername } });
      })
      .then(done)
      .catch(done.fail);
  });

  it('sets the username after a successful update', done => {
    axiosMock.onPut(actionUrl).replyOnce(() => [200, { message: 'Username changed' }]);
    const { input, openModalBtn } = findElements();

    vm.newUsername = newUsername;

    Vue.nextTick()
      .then(() => {
        vm.onConfirm();
      })
      .then(Vue.nextTick)
      .then(() => {
        expect(input).toBeDisabled();
        expect(openModalBtn).toBeDisabled();
      })
      .then(Vue.nextTick)
      .then(() => {
        expect(vm.username).toBe(newUsername);
        expect(vm.newUsername).toBe(newUsername);
      })
      .then(Vue.nextTick)
      .then(() => {
        expect(input).not.toBeDisabled();
        expect(input.value).toBe(newUsername);
        expect(openModalBtn).toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('does not set the username after a erroneous update', done => {
    axiosMock.onPut(actionUrl).replyOnce(() => [400, { message: 'Invalid username' }]);
    const { input, openModalBtn } = findElements();

    const invalidUsername = 'anything.git';
    vm.newUsername = invalidUsername;

    Vue.nextTick()
      .then(() => {
        vm.onConfirm();
      })
      .then(Vue.nextTick)
      .then(() => {
        expect(input).toBeDisabled();
        expect(openModalBtn).toBeDisabled();
      })
      .then(Vue.nextTick)
      .then(() => {
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(invalidUsername);
      })
      .then(Vue.nextTick)
      .then(() => {
        expect(input).not.toBeDisabled();
        expect(input.value).toBe(invalidUsername);
        expect(openModalBtn).not.toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });
});
