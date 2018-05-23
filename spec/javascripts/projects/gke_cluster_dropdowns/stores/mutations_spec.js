import mutations from '~/projects/gke_cluster_dropdowns/store/mutations';
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

  describe('SET_PROJECT_BILLING_STATUS', () => {
    it('should set project billing status', () => {
      const state = {
        projectHasBillingEnabled: null,
      };
      mutations.SET_PROJECT_BILLING_STATUS(state, true);

      expect(state.projectHasBillingEnabled).toBeTruthy();
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

  describe('SET_PROJECTS', () => {
    it('should set Google API Projects response as projects', () => {
      const state = {
        projects: [],
      };

      expect(state.projects.length).toEqual(0);

      mutations.SET_PROJECTS(state, gapiProjectsResponseMock.projects);

      expect(state.projects.length).toEqual(gapiProjectsResponseMock.projects.length);
    });
  });

  describe('SET_ZONES', () => {
    it('should set Google API Zones response as zones', () => {
      const state = {
        zones: [],
      };

      expect(state.zones.length).toEqual(0);

      mutations.SET_ZONES(state, gapiZonesResponseMock.items);

      expect(state.zones.length).toEqual(gapiZonesResponseMock.items.length);
    });
  });

  describe('SET_MACHINE_TYPES', () => {
    it('should set Google API Machine Types response as machineTypes', () => {
      const state = {
        machineTypes: [],
      };

      expect(state.machineTypes.length).toEqual(0);

      mutations.SET_MACHINE_TYPES(state, gapiMachineTypesResponseMock.items);

      expect(state.machineTypes.length).toEqual(gapiMachineTypesResponseMock.items.length);
    });
  });
});
