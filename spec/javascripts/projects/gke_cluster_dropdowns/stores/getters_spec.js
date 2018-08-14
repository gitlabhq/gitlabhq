import * as getters from '~/projects/gke_cluster_dropdowns/store/getters';
import { selectedProjectMock, selectedZoneMock, selectedMachineTypeMock } from '../mock_data';

describe('GCP Cluster Dropdown Store Getters', () => {
  let state;

  describe('valid states', () => {
    beforeEach(() => {
      state = {
        selectedProject: selectedProjectMock,
        selectedZone: selectedZoneMock,
        selectedMachineType: selectedMachineTypeMock,
      };
    });

    describe('hasProject', () => {
      it('should return true when project is selected', () => {
        expect(getters.hasProject(state)).toEqual(true);
      });
    });

    describe('hasZone', () => {
      it('should return true when zone is selected', () => {
        expect(getters.hasZone(state)).toEqual(true);
      });
    });

    describe('hasMachineType', () => {
      it('should return true when machine type is selected', () => {
        expect(getters.hasMachineType(state)).toEqual(true);
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
        expect(getters.hasProject(state)).toEqual(false);
      });
    });

    describe('hasZone', () => {
      it('should return false when zone is not selected', () => {
        expect(getters.hasZone(state)).toEqual(false);
      });
    });

    describe('hasMachineType', () => {
      it('should return false when machine type is not selected', () => {
        expect(getters.hasMachineType(state)).toEqual(false);
      });
    });
  });
});
