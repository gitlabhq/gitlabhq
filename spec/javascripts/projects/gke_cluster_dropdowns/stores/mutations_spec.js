import mutations from '~/projects/gke_cluster_dropdowns/stores/mutations';
import {
  selectedProjectMock,
  selectedZoneMock,
  selectedMachineTypeMock,
  gapiProjectsResponseMock,
  gapiZonesResponseMock,
  gapiMachineTypesResponseMock,
} from '../mock_data';

describe('GCP Cluster Dropdown Store Mutations', () => {
  describe('SET_PROJECT', () => {
    it('should set GCP project as selectedProject', () => {
      const state = {
        selectedProject: {
          projectId: '',
          name: '',
        },
      };
      const projectToSelect = gapiProjectsResponseMock.projects[0];

      mutations.SET_PROJECT(state, projectToSelect);

      expect(state.selectedProject.projectId).toEqual(selectedProjectMock.projectId);
      expect(state.selectedProject.name).toEqual(selectedProjectMock.name);
    });
  });

  describe('SET_ZONE', () => {
    it('should set GCP zone as selectedZone', () => {
      const state = {
        selectedZone: '',
      };
      const zoneToSelect = gapiZonesResponseMock.items[0].name;

      mutations.SET_ZONE(state, zoneToSelect);

      expect(state.selectedZone).toEqual(selectedZoneMock);
    });
  });

  describe('SET_MACHINE_TYPE', () => {
    it('should set GCP machine type as selectedMachineType', () => {
      const state = {
        selectedMachineType: '',
      };
      const machineTypeToSelect = gapiMachineTypesResponseMock.items[0].name;

      mutations.SET_MACHINE_TYPE(state, machineTypeToSelect);

      expect(state.selectedMachineType).toEqual(selectedMachineTypeMock);
    });
  });

  describe('SET_FETCHED_PROJECTS', () => {
    it('should set Google API Projects response as fetchedProjects', () => {
      const state = {
        fetchedProjects: [],
      };

      expect(state.fetchedProjects.length).toEqual(0);

      mutations.SET_FETCHED_PROJECTS(state, gapiProjectsResponseMock.projects);

      expect(state.fetchedProjects.length).toEqual(gapiProjectsResponseMock.projects.length);
    });
  });

  describe('SET_FETCHED_ZONES', () => {
    it('should set Google API Zones response as fetchedZones', () => {
      const state = {
        fetchedZones: [],
      };

      expect(state.fetchedZones.length).toEqual(0);

      mutations.SET_FETCHED_ZONES(state, gapiZonesResponseMock.items);

      expect(state.fetchedZones.length).toEqual(gapiZonesResponseMock.items.length);
    });
  });

  describe('SET_FETCHED_MACHINE_TYPES', () => {
    it('should set Google API Machine Types response as fetchedMachineTypes', () => {
      const state = {
        fetchedMachineTypes: [],
      };

      expect(state.fetchedMachineTypes.length).toEqual(0);

      mutations.SET_FETCHED_MACHINE_TYPES(state, gapiMachineTypesResponseMock.items);

      expect(state.fetchedMachineTypes.length).toEqual(gapiMachineTypesResponseMock.items.length);
    });
  });
});
