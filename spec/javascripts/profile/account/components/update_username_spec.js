import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

import updateUsername from '~/profile/account/components/update_username.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('UpdateUsername component', () => {
  const rootUrl = gl.TEST_HOST;
  const actionUrl = `${gl.TEST_HOST}/update/username`;
  const username = 'hasnoname';
  const newUsername = 'new_username';
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

    Vue.nextTick()
      .then(done)
      .catch(done.fail);
  });

  afterEach(() => {
    vm.$destroy();
    axiosMock.restore();
  });

  const findElements = () => {
    const modalSelector = `#${vm.$options.modalId}`;

    return {
      input: vm.$el.querySelector(`#${vm.$options.inputId}`),
      openModalBtn: vm.$el.querySelector(`[data-target="${modalSelector}"]`),
      modal: vm.$el.querySelector(modalSelector),
      confirmModalBtn: vm.$el.querySelector(`${modalSelector} .btn-warning`),
    };
  };

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
    const header = vm.$el.querySelector(`#${vm.$options.modalId} .modal-title`);
    const body = vm.$el.querySelector(`#${vm.$options.modalId} .modal-body`);

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
    const { confirmModalBtn } = findElements();

    axiosMock.onPut(actionUrl).replyOnce(() => [200, { message: 'Username changed' }]);
    spyOn(axios, 'put').and.callThrough();

    vm.newUsername = newUsername;

    Vue.nextTick()
      .then(() => {
        confirmModalBtn.click();
        expect(axios.put).toHaveBeenCalledWith(actionUrl, { user: { username: newUsername } });
      })
      .then(done)
      .catch(done.fail);
  });

  it('sets the username after a successful update', done => {
    const { input, openModalBtn } = findElements();

    axiosMock.onPut(actionUrl).replyOnce(() => {
      expect(input).toBeDisabled();
      expect(openModalBtn).toBeDisabled();

      return [200, { message: 'Username changed' }];
    });
    spyOn(axios, 'put').and.callThrough();

    vm.newUsername = newUsername;

    vm
      .onConfirm()
      .then(() => {
        expect(axios.put).toHaveBeenCalled();
        expect(vm.username).toBe(newUsername);
        expect(vm.newUsername).toBe(newUsername);
        expect(input).not.toBeDisabled();
        expect(input.value).toBe(newUsername);
        expect(openModalBtn).toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('does not set the username after a erroneous update', done => {
    const { input, openModalBtn } = findElements();

    axiosMock.onPut(actionUrl).replyOnce(() => {
      expect(input).toBeDisabled();
      expect(openModalBtn).toBeDisabled();

      return [400, { message: 'Invalid username' }];
    });
    spyOn(axios, 'put').and.callThrough();

    const invalidUsername = 'anything.git';
    vm.newUsername = invalidUsername;

    vm
      .onConfirm()
      .then(() => done.fail('Expected onConfirm to throw!'))
      .catch(() => {
        expect(axios.put).toHaveBeenCalled();
        expect(vm.username).toBe(username);
        expect(vm.newUsername).toBe(invalidUsername);
        expect(input).not.toBeDisabled();
        expect(input.value).toBe(invalidUsername);
        expect(openModalBtn).not.toBeDisabled();
      })
      .then(done)
      .catch(done.fail);
  });
});
