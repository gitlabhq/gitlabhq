import { APPLICATION_STATUS } from '~/clusters/constants';

const CLUSTERS_MOCK_DATA = {
  GET: {
    '/gitlab-org/gitlab-shell/clusters/1/status.json': {
      data: {
        status: 'errored',
        status_reason: 'Failed to request to CloudPlatform.',
        applications: [{
          name: 'helm',
          status: APPLICATION_STATUS.INSTALLABLE,
          status_reason: null,
        }, {
          name: 'ingress',
          status: APPLICATION_STATUS.ERROR,
          status_reason: 'Cannot connect',
          external_ip: null,
        }, {
          name: 'runner',
          status: APPLICATION_STATUS.INSTALLING,
          status_reason: null,
        },
        {
          name: 'prometheus',
          status: APPLICATION_STATUS.ERROR,
          status_reason: 'Cannot connect',
        }, {
          name: 'jupyter',
          status: APPLICATION_STATUS.INSTALLING,
          status_reason: 'Cannot connect',
        }],
      },
    },
    '/gitlab-org/gitlab-shell/clusters/2/status.json': {
      data: {
        status: 'errored',
        status_reason: 'Failed to request to CloudPlatform.',
        applications: [{
          name: 'helm',
          status: APPLICATION_STATUS.INSTALLED,
          status_reason: null,
        }, {
          name: 'ingress',
          status: APPLICATION_STATUS.INSTALLED,
          status_reason: 'Cannot connect',
          external_ip: '1.1.1.1',
        }, {
          name: 'runner',
          status: APPLICATION_STATUS.INSTALLING,
          status_reason: null,
        },
        {
          name: 'prometheus',
          status: APPLICATION_STATUS.ERROR,
          status_reason: 'Cannot connect',
        }, {
          name: 'jupyter',
          status: APPLICATION_STATUS.INSTALLABLE,
          status_reason: 'Cannot connect',
        }],
      },
    },
  },
  POST: {
    '/gitlab-org/gitlab-shell/clusters/1/applications/helm': { },
    '/gitlab-org/gitlab-shell/clusters/1/applications/ingress': { },
    '/gitlab-org/gitlab-shell/clusters/1/applications/runner': { },
    '/gitlab-org/gitlab-shell/clusters/1/applications/prometheus': { },
    '/gitlab-org/gitlab-shell/clusters/1/applications/jupyter': { },
  },
};

const DEFAULT_APPLICATION_STATE = {
  id: 'some-app',
  title: 'My App',
  titleLink: 'https://about.gitlab.com/',
  description: 'Some description about this interesting application!',
  status: null,
  statusReason: null,
  requestStatus: null,
  requestReason: null,
};

export {
  CLUSTERS_MOCK_DATA,
  DEFAULT_APPLICATION_STATE,
};
