import {
  gapiProjectsResponseMock,
  gapiZonesResponseMock,
  gapiMachineTypesResponseMock,
} from './mock_data';

// eslint-disable-next-line import/prefer-default-export
export const gapi = () => ({
  client: {
    cloudbilling: {
      projects: {
        getBillingInfo: () =>
          new Promise(resolve => {
            resolve({
              result: { billingEnabled: true },
            });
          }),
      },
    },
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
