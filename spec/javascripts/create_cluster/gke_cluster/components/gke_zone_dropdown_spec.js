import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import GkeZoneDropdown from '~/create_cluster/gke_cluster/components/gke_zone_dropdown.vue';
import { createStore } from '~/create_cluster/gke_cluster/store';
import {
  SET_PROJECT,
  SET_ZONES,
  SET_PROJECT_BILLING_STATUS,
} from '~/create_cluster/gke_cluster/store/mutation_types';
import { selectedZoneMock, selectedProjectMock, gapiZonesResponseMock } from '../mock_data';

const componentConfig = {
  fieldId: 'cluster_provider_gcp_attributes_gcp_zone',
  fieldName: 'cluster[provider_gcp_attributes][gcp_zone]',
};

const LABELS = {
  LOADING: 'Fetching zones',
  DISABLED: 'Select project to choose zone',
  DEFAULT: 'Select zone',
};

const createComponent = (store, props = componentConfig) => {
  const Component = Vue.extend(GkeZoneDropdown);

  return mountComponentWithStore(Component, {
    el: null,
    props,
    store,
  });
};

describe('GkeZoneDropdown', () => {
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();
    vm = createComponent(store);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('toggleText', () => {
    it('returns disabled state toggle text', () => {
      expect(vm.toggleText).toBe(LABELS.DISABLED);
    });

    it('returns loading toggle text', () => {
      vm.isLoading = true;

      expect(vm.toggleText).toBe(LABELS.LOADING);
    });

    it('returns default toggle text', () => {
      expect(vm.toggleText).toBe(LABELS.DISABLED);

      vm.$store.commit(SET_PROJECT, selectedProjectMock);
      vm.$store.commit(SET_PROJECT_BILLING_STATUS, true);

      expect(vm.toggleText).toBe(LABELS.DEFAULT);
    });

    it('returns project name if project selected', () => {
      vm.setItem(selectedZoneMock);

      expect(vm.toggleText).toBe(selectedZoneMock);
    });
  });

  describe('selectItem', () => {
    it('reflects new value when dropdown item is clicked', done => {
      expect(vm.$el.querySelector('input').value).toBe('');
      vm.$store.commit(SET_ZONES, gapiZonesResponseMock.items);

      return vm
        .$nextTick()
        .then(() => {
          vm.$el.querySelector('.dropdown-content button').click();

          return vm
            .$nextTick()
            .then(() => {
              expect(vm.$el.querySelector('input').value).toBe(selectedZoneMock);
              done();
            })
            .catch(done.fail);
        })
        .catch(done.fail);
    });
  });
});
