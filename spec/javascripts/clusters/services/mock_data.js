import {
  APPLICATION_INSTALLABLE,
  APPLICATION_INSTALLING,
  APPLICATION_ERROR,
} from '~/clusters/constants';

const CLUSTERS_MOCK_DATA = {
  GET: {
    '/gitlab-org/gitlab-shell/clusters/1/status.json': {
      data: {
        status: 'errored',
        status_reason: 'Failed to request to CloudPlatform.',
        applications: [{
          name: 'helm',
          status: APPLICATION_INSTALLABLE,
          status_reason: null,
        }, {
          name: 'ingress',
          status: APPLICATION_ERROR,
          status_reason: 'Cannot connect',
          external_ip: null,
        }, {
          name: 'runner',
          status: APPLICATION_INSTALLING,
          status_reason: null,
        },
        {
          name: 'prometheus',
          status: APPLICATION_ERROR,
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
