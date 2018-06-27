import { createStore } from '~/projects/gke_cluster_dropdowns/store';
import * as types from '~/projects/gke_cluster_dropdowns/store/mutation_types';
import {
  selectedProjectMock,
  selectedZoneMock,
  selectedMachineTypeMock,
  gapiProjectsResponseMock,
  gapiZonesResponseMock,
  gapiMachineTypesResponseMock,
} from '../mock_data';

describe('GCP Cluster Dropdown Store Mutations', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  describe('SET_PROJECT', () => {
    it('should set GCP project as selectedProject', () => {
      const projectToSelect = gapiProjectsResponseMock.projects[0];

      store.commit(types.SET_PROJECT, projectToSelect);

      expect(store.state.selectedProject.projectId).toEqual(selectedProjectMock.projectId);
      expect(store.state.selectedProject.name).toEqual(selectedProjectMock.name);
    });
  });

  describe('SET_PROJECT_BILLING_STATUS', () => {
    it('should set project billing status', () => {
      store.commit(types.SET_PROJECT_BILLING_STATUS, true);

      expect(store.state.projectHasBillingEnabled).toBeTruthy();
    });
  });

  describe('SET_ZONE', () => {
    it('should set GCP zone as selectedZone', () => {
      const zoneToSelect = gapiZonesResponseMock.items[0].name;

      store.commit(types.SET_ZONE, zoneToSelect);

      expect(store.state.selectedZone).toEqual(selectedZoneMock);
    });
  });

  describe('SET_MACHINE_TYPE', () => {
    it('should set GCP machine type as selectedMachineType', () => {
      const machineTypeToSelect = gapiMachineTypesResponseMock.items[0].name;

      store.commit(types.SET_MACHINE_TYPE, machineTypeToSelect);

      expect(store.state.selectedMachineType).toEqual(selectedMachineTypeMock);
    });
  });

  describe('SET_PROJECTS', () => {
    it('should set Google API Projects response as projects', () => {
      expect(store.state.projects.length).toEqual(0);

      store.commit(types.SET_PROJECTS, gapiProjectsResponseMock.projects);

      expect(store.state.projects.length).toEqual(gapiProjectsResponseMock.projects.length);
    });
  });

  describe('SET_ZONES', () => {
    it('should set Google API Zones response as zones', () => {
      expect(store.state.zones.length).toEqual(0);

      store.commit(types.SET_ZONES, gapiZonesResponseMock.items);

      expect(store.state.zones.length).toEqual(gapiZonesResponseMock.items.length);
    });
  });

  describe('SET_MACHINE_TYPES', () => {
    it('should set Google API Machine Types response as machineTypes', () => {
      expect(store.state.machineTypes.length).toEqual(0);

      store.commit(types.SET_MACHINE_TYPES, gapiMachineTypesResponseMock.items);

      expect(store.state.machineTypes.length).toEqual(gapiMachineTypesResponseMock.items.length);
    });
  });
});
