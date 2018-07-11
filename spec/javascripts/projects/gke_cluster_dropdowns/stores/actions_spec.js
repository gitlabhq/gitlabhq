import testAction from 'spec/helpers/vuex_action_helper';
import * as actions from '~/projects/gke_cluster_dropdowns/store/actions';
import { createStore } from '~/projects/gke_cluster_dropdowns/store';
import { gapi } from '../helpers';
import { selectedProjectMock, selectedZoneMock, selectedMachineTypeMock } from '../mock_data';

describe('GCP Cluster Dropdown Store Actions', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  describe('setProject', () => {
    it('should set project', done => {
      testAction(
        actions.setProject,
        selectedProjectMock,
        { selectedProject: {} },
        [{ type: 'SET_PROJECT', payload: selectedProjectMock }],
        [],
        done,
      );
    });
  });

  describe('setZone', () => {
    it('should set zone', done => {
      testAction(
        actions.setZone,
        selectedZoneMock,
        { selectedZone: '' },
        [{ type: 'SET_ZONE', payload: selectedZoneMock }],
        [],
        done,
      );
    });
  });

  describe('setMachineType', () => {
    it('should set machine type', done => {
      testAction(
        actions.setMachineType,
        selectedMachineTypeMock,
        { selectedMachineType: '' },
        [{ type: 'SET_MACHINE_TYPE', payload: selectedMachineTypeMock }],
        [],
        done,
      );
    });
  });

  describe('setIsValidatingProjectBilling', () => {
    it('should set machine type', done => {
      testAction(
        actions.setIsValidatingProjectBilling,
        true,
        { isValidatingProjectBilling: null },
        [{ type: 'SET_IS_VALIDATING_PROJECT_BILLING', payload: true }],
        [],
        done,
      );
    });
  });

  describe('async fetch methods', () => {
    window.gapi = gapi();

    describe('fetchProjects', () => {
      it('fetches projects from Google API', done => {
        store
          .dispatch('fetchProjects')
          .then(() => {
            expect(store.state.projects[0].projectId).toEqual(selectedProjectMock.projectId);
            expect(store.state.projects[0].name).toEqual(selectedProjectMock.name);

            done();
          })
          .catch(done.fail);
      });
    });

    describe('validateProjectBilling', () => {
      it('checks project billing status from Google API', done => {
        testAction(
          actions.validateProjectBilling,
          true,
          {
            selectedProject: selectedProjectMock,
            selectedZone: '',
            selectedMachineType: '',
            projectHasBillingEnabled: null,
          },
          [
            { type: 'SET_ZONE', payload: '' },
            { type: 'SET_MACHINE_TYPE', payload: '' },
            { type: 'SET_PROJECT_BILLING_STATUS', payload: true },
          ],
          [{ type: 'setIsValidatingProjectBilling', payload: false }],
          done,
        );
      });
    });

    describe('fetchZones', () => {
      it('fetches zones from Google API', done => {
        store
          .dispatch('fetchZones')
          .then(() => {
            expect(store.state.zones[0].name).toEqual(selectedZoneMock);

            done();
          })
          .catch(done.fail);
      });
    });

    describe('fetchMachineTypes', () => {
      it('fetches machine types from Google API', done => {
        store
          .dispatch('fetchMachineTypes')
          .then(() => {
            expect(store.state.machineTypes[0].name).toEqual(selectedMachineTypeMock);

            done();
          })
          .catch(done.fail);
      });
    });
  });
});
