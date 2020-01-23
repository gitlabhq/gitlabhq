import {
  hasProject,
  hasZone,
  hasMachineType,
  hasValidData,
} from '~/create_cluster/gke_cluster/store/getters';
import { selectedProjectMock, selectedZoneMock, selectedMachineTypeMock } from '../mock_data';

describe('GCP Cluster Dropdown Store Getters', () => {
  let state;

  describe('valid states', () => {
    beforeEach(() => {
      state = {
        projectHasBillingEnabled: true,
        selectedProject: selectedProjectMock,
        selectedZone: selectedZoneMock,
        selectedMachineType: selectedMachineTypeMock,
      };
    });

    describe('hasProject', () => {
      it('should return true when project is selected', () => {
        expect(hasProject(state)).toEqual(true);
      });
    });

    describe('hasZone', () => {
      it('should return true when zone is selected', () => {
        expect(hasZone(state)).toEqual(true);
      });
    });

    describe('hasMachineType', () => {
      it('should return true when machine type is selected', () => {
        expect(hasMachineType(state)).toEqual(true);
      });
    });

    describe('hasValidData', () => {
      it('should return true when a project, zone and machine type are selected', () => {
        expect(hasValidData(state, { hasZone: true, hasMachineType: true })).toEqual(true);
      });
    });
  });

  describe('invalid states', () => {
    beforeEach(() => {
      state = {
        selectedProject: {
          projectId: '',
          name: '',
        },
        selectedZone: '',
        selectedMachineType: '',
      };
    });

    describe('hasProject', () => {
      it('should return false when project is not selected', () => {
        expect(hasProject(state)).toEqual(false);
      });
    });

    describe('hasZone', () => {
      it('should return false when zone is not selected', () => {
        expect(hasZone(state)).toEqual(false);
      });
    });

    describe('hasMachineType', () => {
      it('should return false when machine type is not selected', () => {
        expect(hasMachineType(state)).toEqual(false);
      });
    });

    describe('hasValidData', () => {
      let getters;

      beforeEach(() => {
        getters = { hasZone: true, hasMachineType: true };
      });

      it('should return false when project is not billable', () => {
        state.projectHasBillingEnabled = false;

        expect(hasValidData(state, getters)).toEqual(false);
      });

      it('should return false when zone is not selected', () => {
        getters.hasZone = false;

        expect(hasValidData(state, getters)).toEqual(false);
      });

      it('should return false when machine type is not selected', () => {
        getters.hasMachineType = false;

        expect(hasValidData(state, getters)).toEqual(false);
      });
    });
  });
});
