import testAction from 'spec/helpers/vuex_action_helper';
import * as actions from '~/projects/gke_cluster_dropdowns/store/actions';
import store from '~/projects/gke_cluster_dropdowns/store';
import { resetStore, gapi } from '../helpers';
import { selectedProjectMock, selectedZoneMock, selectedMachineTypeMock } from '../mock_data';

describe('GCP Cluster Dropdown Store Actions', () => {
  afterEach(() => {
    resetStore(store);
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

  describe('async fetch methods', () => {
    window.gapi = gapi();

    describe('getProjects', () => {
      it('fetches projects from Google API', done => {
        store
          .dispatch('getProjects')
          .then(() => {
            expect(store.state.projects[0].projectId).toEqual(selectedProjectMock.projectId);
            expect(store.state.projects[0].name).toEqual(selectedProjectMock.name);

            done();
          })
          .catch(done.fail);
      });
    });

    describe('getZones', () => {
      it('fetches zones from Google API', done => {
        store
          .dispatch('getZones')
          .then(() => {
            expect(store.state.zones[0].name).toEqual(selectedZoneMock);

            done();
          })
          .catch(done.fail);
      });
    });

    describe('getMachineTypes', () => {
      it('fetches machine types from Google API', done => {
        store
          .dispatch('getMachineTypes')
          .then(() => {
            expect(store.state.machineTypes[0].name).toEqual(selectedMachineTypeMock);

            done();
          })
          .catch(done.fail);
      });
    });
  });
});
