import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import GkeMachineTypeDropdown from '~/create_cluster/gke_cluster/components/gke_machine_type_dropdown.vue';
import { createStore } from '~/create_cluster/gke_cluster/store';
import {
  SET_PROJECT,
  SET_PROJECT_BILLING_STATUS,
  SET_ZONE,
  SET_MACHINE_TYPES,
} from '~/create_cluster/gke_cluster/store/mutation_types';
import {
  selectedZoneMock,
  selectedProjectMock,
  selectedMachineTypeMock,
  gapiMachineTypesResponseMock,
} from '../mock_data';

const componentConfig = {
  fieldId: 'cluster_provider_gcp_attributes_gcp_machine_type',
  fieldName: 'cluster[provider_gcp_attributes][gcp_machine_type]',
};

const LABELS = {
  LOADING: 'Fetching machine types',
  DISABLED_NO_PROJECT: 'Select project and zone to choose machine type',
  DISABLED_NO_ZONE: 'Select zone to choose machine type',
  DEFAULT: 'Select machine type',
};

const createComponent = (store, props = componentConfig) => {
  const Component = Vue.extend(GkeMachineTypeDropdown);

  return mountComponentWithStore(Component, {
    el: null,
    props,
    store,
  });
};

describe('GkeMachineTypeDropdown', () => {
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();
    vm = createComponent(store);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('shows various toggle text depending on state', () => {
    it('returns disabled state toggle text when no project and zone are selected', () => {
      expect(vm.toggleText).toBe(LABELS.DISABLED_NO_PROJECT);
    });

    it('returns disabled state toggle text when no zone is selected', () => {
      vm.$store.commit(SET_PROJECT, selectedProjectMock);
      vm.$store.commit(SET_PROJECT_BILLING_STATUS, true);

      expect(vm.toggleText).toBe(LABELS.DISABLED_NO_ZONE);
    });

    it('returns loading toggle text', () => {
      vm.isLoading = true;

      expect(vm.toggleText).toBe(LABELS.LOADING);
    });

    it('returns default toggle text', () => {
      expect(vm.toggleText).toBe(LABELS.DISABLED_NO_PROJECT);

      vm.$store.commit(SET_PROJECT, selectedProjectMock);
      vm.$store.commit(SET_PROJECT_BILLING_STATUS, true);
      vm.$store.commit(SET_ZONE, selectedZoneMock);

      expect(vm.toggleText).toBe(LABELS.DEFAULT);
    });

    it('returns machine type name if machine type selected', () => {
      vm.setItem(selectedMachineTypeMock);

      expect(vm.toggleText).toBe(selectedMachineTypeMock);
    });
  });

  describe('form input', () => {
    it('reflects new value when dropdown item is clicked', done => {
      expect(vm.$el.querySelector('input').value).toBe('');
      vm.$store.commit(SET_MACHINE_TYPES, gapiMachineTypesResponseMock.items);

      return vm
        .$nextTick()
        .then(() => {
          vm.$el.querySelector('.dropdown-content button').click();

          return vm
            .$nextTick()
            .then(() => {
              expect(vm.$el.querySelector('input').value).toBe(selectedMachineTypeMock);
              done();
            })
            .catch(done.fail);
        })
        .catch(done.fail);
    });
  });
});
