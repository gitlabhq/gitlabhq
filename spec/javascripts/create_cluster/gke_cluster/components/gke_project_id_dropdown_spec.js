import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import GkeProjectIdDropdown from '~/create_cluster/gke_cluster/components/gke_project_id_dropdown.vue';
import { createStore } from '~/create_cluster/gke_cluster/store';
import { SET_PROJECTS } from '~/create_cluster/gke_cluster/store/mutation_types';
import { emptyProjectMock, selectedProjectMock } from '../mock_data';
import { gapi } from '../helpers';

const componentConfig = {
  docsUrl: 'https://console.cloud.google.com/home/dashboard',
  fieldId: 'cluster_provider_gcp_attributes_gcp_project_id',
  fieldName: 'cluster[provider_gcp_attributes][gcp_project_id]',
};

const LABELS = {
  LOADING: 'Fetching projects',
  VALIDATING_PROJECT_BILLING: 'Validating project billing status',
  DEFAULT: 'Select project',
  EMPTY: 'No projects found',
};

const createComponent = (store, props = componentConfig) => {
  const Component = Vue.extend(GkeProjectIdDropdown);

  return mountComponentWithStore(Component, {
    el: null,
    props,
    store,
  });
};

describe('GkeProjectIdDropdown', () => {
  let vm;
  let store;

  let originalGapi;
  beforeAll(() => {
    originalGapi = window.gapi;
    window.gapi = gapi();
  });

  afterAll(() => {
    window.gapi = originalGapi;
  });

  beforeEach(() => {
    store = createStore();
    vm = createComponent(store);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('toggleText', () => {
    it('returns loading toggle text', () => {
      expect(vm.toggleText).toBe(LABELS.LOADING);
    });

    it('returns project billing validation text', () => {
      vm.setIsValidatingProjectBilling(true);

      expect(vm.toggleText).toBe(LABELS.VALIDATING_PROJECT_BILLING);
    });

    it('returns default toggle text', done =>
      setTimeout(() => {
        vm.setItem(emptyProjectMock);

        expect(vm.toggleText).toBe(LABELS.DEFAULT);

        done();
      }));

    it('returns project name if project selected', done =>
      setTimeout(() => {
        vm.isLoading = false;

        expect(vm.toggleText).toBe(selectedProjectMock.name);

        done();
      }));

    it('returns empty toggle text', done =>
      setTimeout(() => {
        vm.$store.commit(SET_PROJECTS, null);
        vm.setItem(emptyProjectMock);

        expect(vm.toggleText).toBe(LABELS.EMPTY);

        done();
      }));
  });

  describe('selectItem', () => {
    it('reflects new value when dropdown item is clicked', done => {
      expect(vm.$el.querySelector('input').value).toBe('');

      return vm
        .$nextTick()
        .then(() => {
          vm.$el.querySelector('.dropdown-content button').click();

          return vm
            .$nextTick()
            .then(() => {
              expect(vm.$el.querySelector('input').value).toBe(selectedProjectMock.projectId);
              done();
            })
            .catch(done.fail);
        })
        .catch(done.fail);
    });
  });
});
