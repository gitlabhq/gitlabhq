import Vue from 'vue';
import GkeProjectIdDropdown from '~/projects/gke_cluster_dropdowns/components/gke_project_id_dropdown.vue';
import { SET_PROJECTS } from '~/projects/gke_cluster_dropdowns/store/mutation_types';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { resetStore } from '../helpers';
import { emptyProjectMock, selectedProjectMock } from '../mock_data';

const componentConfig = {
  docsUrl: 'https://console.cloud.google.com/home/dashboard',
  fieldId: 'cluster_provider_gcp_attributes_gcp_project_id',
  fieldName: 'cluster[provider_gcp_attributes][gcp_project_id]',
};

const LABELS = {
  LOADING: 'Fetching projects',
  DEFAULT: 'Select project',
  EMPTY: 'No projects found',
};

const createComponent = (config = componentConfig) => {
  const Component = Vue.extend(GkeProjectIdDropdown);

  return mountComponent(Component, config);
};

describe('GkeProjectIdDropdown', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('toggleText', () => {
    it('returns loading toggle text', () => {
      expect(vm.toggleText).toBe(LABELS.LOADING);
    });

    it('returns default toggle text', done =>
      vm.$nextTick().then(() => {
        vm.setItem(emptyProjectMock);

        expect(vm.toggleText).toBe(LABELS.DEFAULT);
        done();
      }));

    it('returns project name if project selected', done =>
      vm.$nextTick().then(() => {
        expect(vm.toggleText).toBe(selectedProjectMock.name);
        done();
      }));

    it('returns empty toggle text', done =>
      vm.$nextTick().then(() => {
        vm.$store.commit(SET_PROJECTS, null);
        vm.setItem(emptyProjectMock);

        expect(vm.toggleText).toBe(LABELS.EMPTY);
        done();
      }));
  });

  describe('selectItem', () => {
    it('reflects new value when dropdown item is clicked', done => {
      expect(vm.$el.querySelector('input').value).toBe('');

      return vm.$nextTick().then(() => {
        vm.$el.querySelector('.dropdown-content button').click();

        return vm.$nextTick().then(() => {
          expect(vm.$el.querySelector('input').value).toBe(selectedProjectMock.projectId);
          done();
        });
      });
    });
  });
});
