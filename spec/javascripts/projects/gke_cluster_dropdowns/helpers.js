import {
  gapiProjectsResponseMock,
  gapiZonesResponseMock,
  gapiMachineTypesResponseMock,
} from './mock_data';

// eslint-disable-next-line import/prefer-default-export
export const resetStore = store => {
  store.replaceState({
    selectedProject: {
      projectId: '',
      name: '',
    },
    selectedZone: '',
    selectedMachineType: '',
    projects: [],
    zones: [],
    machineTypes: [],
  });
};

// eslint-disable-next-line import/prefer-default-export
export const gapi = () => ({
  client: {
    cloudresourcemanager: {
      projects: {
        list: () =>
          new Promise(resolve => {
            resolve({
              result: { ...gapiProjectsResponseMock },
            });
          }),
      },
    },
    compute: {
      zones: {
        list: () =>
          new Promise(resolve => {
            resolve({
              result: { ...gapiZonesResponseMock },
            });
          }),
      },
      machineTypes: {
        list: () =>
          new Promise(resolve => {
            resolve({
              result: { ...gapiMachineTypesResponseMock },
            });
          }),
      },
    },
  },
});
