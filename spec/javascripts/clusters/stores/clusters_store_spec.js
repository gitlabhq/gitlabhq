import ClustersStore from '~/clusters/stores/clusters_store';
import { APPLICATION_INSTALLING } from '~/clusters/constants';
import { CLUSTERS_MOCK_DATA } from '../services/mock_data';

describe('Clusters Store', () => {
  let store;

  beforeEach(() => {
    store = new ClustersStore();
  });

  describe('updateStatus', () => {
    it('should store new status', () => {
      expect(store.state.status).toEqual(null);

      const newStatus = 'errored';
      store.updateStatus(newStatus);

      expect(store.state.status).toEqual(newStatus);
    });
  });

  describe('updateStatusReason', () => {
    it('should store new reason', () => {
      expect(store.state.statusReason).toEqual(null);

      const newReason = 'Something went wrong!';
      store.updateStatusReason(newReason);

      expect(store.state.statusReason).toEqual(newReason);
    });
  });

  describe('updateAppProperty', () => {
    it('should store new request status', () => {
      expect(store.state.applications.helm.requestStatus).toEqual(null);

      const newStatus = APPLICATION_INSTALLING;
      store.updateAppProperty('helm', 'requestStatus', newStatus);

      expect(store.state.applications.helm.requestStatus).toEqual(newStatus);
    });

    it('should store new request reason', () => {
      expect(store.state.applications.helm.requestReason).toEqual(null);

      const newReason = 'We broke it.';
      store.updateAppProperty('helm', 'requestReason', newReason);

      expect(store.state.applications.helm.requestReason).toEqual(newReason);
    });
  });

  describe('updateStateFromServer', () => {
    it('should store new polling data from server', () => {
      const mockResponseData = CLUSTERS_MOCK_DATA.GET['/gitlab-org/gitlab-shell/clusters/1/status.json'].data;
      store.updateStateFromServer(mockResponseData);

      expect(store.state).toEqual({
        helpPath: null,
        ingressHelpPath: null,
        status: mockResponseData.status,
        statusReason: mockResponseData.status_reason,
        applications: {
          helm: {
            title: 'Helm Tiller',
            status: mockResponseData.applications[0].status,
            statusReason: mockResponseData.applications[0].status_reason,
            requestStatus: null,
            requestReason: null,
          },
          ingress: {
            title: 'Ingress',
            status: mockResponseData.applications[1].status,
            statusReason: mockResponseData.applications[1].status_reason,
            requestStatus: null,
            requestReason: null,
            externalIp: null,
          },
          runner: {
            title: 'GitLab Runner',
            status: mockResponseData.applications[2].status,
            statusReason: mockResponseData.applications[2].status_reason,
            requestStatus: null,
            requestReason: null,
          },
          prometheus: {
            title: 'Prometheus',
            status: mockResponseData.applications[3].status,
            statusReason: mockResponseData.applications[3].status_reason,
            requestStatus: null,
            requestReason: null,
          },
        },
      });
    });
  });
});
