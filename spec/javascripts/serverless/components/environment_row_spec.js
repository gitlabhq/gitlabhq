import Vue from 'vue';

import environmentRowComponent from '~/serverless/components/environment_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import ServerlessStore from '~/serverless/stores/serverless_store';

import { mockServerlessFunctions, mockServerlessFunctionsDiffEnv } from '../mock_data';

const createComponent = (env, envName) =>
  mountComponent(Vue.extend(environmentRowComponent), { env, envName });

describe('environment row component', () => {
  describe('default global cluster case', () => {
    let vm;

    beforeEach(() => {
      const store = new ServerlessStore(false, '/cluster_path', 'help_path');
      store.updateFunctionsFromServer(mockServerlessFunctions);
      vm = createComponent(store.state.functions['*'], '*');
    });

    it('has the correct envId', () => {
      expect(vm.envId).toEqual('env-global');
      vm.$destroy();
    });

    it('is open by default', () => {
      expect(vm.isOpenClass).toEqual({ 'is-open': true });
      vm.$destroy();
    });

    it('generates correct output', () => {
      expect(vm.$el.querySelectorAll('li').length).toEqual(2);
      expect(vm.$el.id).toEqual('env-global');
      expect(vm.$el.classList.contains('is-open')).toBe(true);
      expect(vm.$el.querySelector('div.title').innerHTML.trim()).toEqual('*');

      vm.$destroy();
    });

    it('opens and closes correctly', () => {
      expect(vm.isOpen).toBe(true);

      vm.toggleOpen();
      Vue.nextTick(() => {
        expect(vm.isOpen).toBe(false);
      });

      vm.$destroy();
    });
  });

  describe('default named cluster case', () => {
    let vm;

    beforeEach(() => {
      const store = new ServerlessStore(false, '/cluster_path', 'help_path');
      store.updateFunctionsFromServer(mockServerlessFunctionsDiffEnv);
      vm = createComponent(store.state.functions.test, 'test');
    });

    it('has the correct envId', () => {
      expect(vm.envId).toEqual('env-test');
      vm.$destroy();
    });

    it('is open by default', () => {
      expect(vm.isOpenClass).toEqual({ 'is-open': true });
      vm.$destroy();
    });

    it('generates correct output', () => {
      expect(vm.$el.querySelectorAll('li').length).toEqual(1);
      expect(vm.$el.id).toEqual('env-test');
      expect(vm.$el.classList.contains('is-open')).toBe(true);
      expect(vm.$el.querySelector('div.title').innerHTML.trim()).toEqual('test');

      vm.$destroy();
    });
  });
});
