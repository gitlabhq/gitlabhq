import Vue from 'vue';
import _ from 'underscore';
import app from '~/releases/list/components/app.vue';
import createStore from '~/releases/list/store';
import api from '~/api';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../store/helpers';
import {
  pageInfoHeadersWithoutPagination,
  pageInfoHeadersWithPagination,
  release,
  releases,
} from '../../mock_data';

describe('Releases App ', () => {
  const Component = Vue.extend(app);
  let store;
  let vm;
  let releasesPagination;

  const props = {
    projectId: 'gitlab-ce',
    documentationLink: 'help/releases',
    illustrationPath: 'illustration/path',
  };

  beforeEach(() => {
    store = createStore();
    releasesPagination = _.range(21).map(index => ({ ...release, tag_name: `${index}.00` }));
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      spyOn(api, 'releases').and.returnValue(Promise.resolve({ data: [], headers: {} }));
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders loading icon', done => {
      expect(vm.$el.querySelector('.js-loading')).not.toBeNull();
      expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
      expect(vm.$el.querySelector('.js-success-state')).toBeNull();
      expect(vm.$el.querySelector('.gl-pagination')).toBeNull();

      setTimeout(() => {
        done();
      }, 0);
    });
  });

  describe('with successful request', () => {
    beforeEach(() => {
      spyOn(api, 'releases').and.returnValue(
        Promise.resolve({ data: releases, headers: pageInfoHeadersWithoutPagination }),
      );
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders success state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-loading')).toBeNull();
        expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
        expect(vm.$el.querySelector('.js-success-state')).not.toBeNull();
        expect(vm.$el.querySelector('.gl-pagination')).toBeNull();

        done();
      }, 0);
    });
  });

  describe('with successful request and pagination', () => {
    beforeEach(() => {
      spyOn(api, 'releases').and.returnValue(
        Promise.resolve({ data: releasesPagination, headers: pageInfoHeadersWithPagination }),
      );
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders success state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-loading')).toBeNull();
        expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
        expect(vm.$el.querySelector('.js-success-state')).not.toBeNull();
        expect(vm.$el.querySelector('.gl-pagination')).not.toBeNull();

        done();
      }, 0);
    });
  });

  describe('with empty request', () => {
    beforeEach(() => {
      spyOn(api, 'releases').and.returnValue(Promise.resolve({ data: [], headers: {} }));
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders empty state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-loading')).toBeNull();
        expect(vm.$el.querySelector('.js-empty-state')).not.toBeNull();
        expect(vm.$el.querySelector('.js-success-state')).toBeNull();
        expect(vm.$el.querySelector('.gl-pagination')).toBeNull();

        done();
      }, 0);
    });
  });
});
