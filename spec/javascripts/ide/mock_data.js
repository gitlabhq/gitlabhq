export const projectData = {
  id: 1,
  name: 'abcproject',
  web_url: '',
  avatar_url: '',
  path: '',
  name_with_namespace: 'namespace/abcproject',
  branches: {
    master: {
      treeId: 'abcproject/master',
    },
  },
  mergeRequests: {},
  merge_requests_enabled: true,
};

export const pipelines = [
  {
    id: 1,
    ref: 'master',
    sha: '123',
    status: 'failed',
  },
  {
    id: 2,
    ref: 'master',
    sha: '213',
    status: 'success',
  },
];

export const jobs = [
  {
    id: 1,
    name: 'test',
    status: 'failed',
    stage: 'test',
    duration: 1,
  },
  {
    id: 2,
    name: 'test 2',
    status: 'failed',
    stage: 'test',
    duration: 1,
  },
  {
    id: 3,
    name: 'test 3',
    status: 'failed',
    stage: 'test',
    duration: 1,
  },
  {
    id: 4,
    name: 'test 3',
    status: 'failed',
    stage: 'build',
    duration: 1,
  },
];

export const fullPipelinesResponse = {
  data: {
    count: {
      all: 2,
    },
    pipelines: [
      {
        id: '51',
        commit: {
          id: 'xxxxxxxxxxxxxxxxxxxx',
        },
        details: {
          status: {
            icon: 'status_failed',
            text: 'failed',
          },
        },
      },
      {
        id: '50',
        commit: {
          id: 'abc123def456ghi789jkl',
        },
        details: {
          status: {
            icon: 'status_passed',
            text: 'passed',
          },
        },
      },
    ],
  },
};
