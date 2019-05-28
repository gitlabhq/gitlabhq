import Vue from 'vue';
import app from '~/releases/components/app.vue';
import createStore from '~/releases/store';
import api from '~/api';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../store/helpers';
import { releases } from '../mock_data';

describe('Releases App ', () => {
  const Component = Vue.extend(app);
  let store;
  let vm;

  const props = {
    projectId: 'gitlab-ce',
    documentationLink: 'help/releases',
    illustrationPath: 'illustration/path',
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      spyOn(api, 'releases').and.returnValue(Promise.resolve({ data: [] }));
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders loading icon', done => {
      expect(vm.$el.querySelector('.js-loading')).not.toBeNull();
      expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
      expect(vm.$el.querySelector('.js-success-state')).toBeNull();

      setTimeout(() => {
        done();
      }, 0);
    });
  });

  describe('with successful request', () => {
    beforeEach(() => {
      spyOn(api, 'releases').and.returnValue(Promise.resolve({ data: releases }));
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders success state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-loading')).toBeNull();
        expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
        expect(vm.$el.querySelector('.js-success-state')).not.toBeNull();

        done();
      }, 0);
    });
  });

  describe('with empty request', () => {
    beforeEach(() => {
      spyOn(api, 'releases').and.returnValue(Promise.resolve({ data: [] }));
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders empty state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-loading')).toBeNull();
        expect(vm.$el.querySelector('.js-empty-state')).not.toBeNull();
        expect(vm.$el.querySelector('.js-success-state')).toBeNull();

        done();
      }, 0);
    });
  });
});
