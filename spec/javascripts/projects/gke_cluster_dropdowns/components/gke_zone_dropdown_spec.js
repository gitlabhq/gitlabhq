import Vue from 'vue';
import GkeZoneDropdown from '~/projects/gke_cluster_dropdowns/components/gke_zone_dropdown.vue';
import { SET_PROJECT, SET_ZONES } from '~/projects/gke_cluster_dropdowns/stores/mutation_types';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { resetStore } from '../helpers';
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

const createComponent = (config = componentConfig) => {
  const Component = Vue.extend(GkeZoneDropdown);

  return mountComponent(Component, config);
};

describe('GkeZoneDropdown', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
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

      vm.$nextTick(() => {
        vm.$el.querySelector('.dropdown-content button').click();

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('input').value).toBe(selectedZoneMock);
          done();
        });
      });
    });
  });
});
