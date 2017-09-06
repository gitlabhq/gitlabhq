export const currentSession = {
  username: 'root',
  storageKey: 'root/frequent-projects',
  apiVersion: 'v4',
  project: {
    id: 1,
    name: 'dummy-project',
    namespace: 'SamepleGroup / Dummy-Project',
    webUrl: 'http://127.0.0.1/samplegroup/dummy-project',
    avatarUrl: null,
    lastAccessedOn: Date.now(),
  },
};

export const mockProject = {
  id: 1,
  name: 'GitLab Community Edition',
  namespace: 'gitlab-org / gitlab-ce',
  webUrl: 'http://127.0.0.1:3000/gitlab-org/gitlab-ce',
  avatarUrl: null,
};

export const mockRawProject = {
  id: 1,
  name: 'GitLab Community Edition',
  name_with_namespace: 'gitlab-org / gitlab-ce',
  web_url: 'http://127.0.0.1:3000/gitlab-org/gitlab-ce',
  avatar_url: null,
};

export const mockFrequents = [
  {
    id: 1,
    name: 'GitLab Community Edition',
    namespace: 'gitlab-org / gitlab-ce',
    webUrl: 'http://127.0.0.1:3000/gitlab-org/gitlab-ce',
    avatarUrl: null,
  },
  {
    id: 2,
    name: 'GitLab CI',
    namespace: 'gitlab-org / gitlab-ci',
    webUrl: 'http://127.0.0.1:3000/gitlab-org/gitlab-ci',
    avatarUrl: null,
  },
  {
    id: 3,
    name: 'Typeahead.Js',
    namespace: 'twitter / typeahead-js',
    webUrl: 'http://127.0.0.1:3000/twitter/typeahead-js',
    avatarUrl: '/uploads/-/system/project/avatar/7/TWBS.png',
  },
  {
    id: 4,
    name: 'Intel',
    namespace: 'platform / hardware / bsp / intel',
    webUrl: 'http://127.0.0.1:3000/platform/hardware/bsp/intel',
    avatarUrl: null,
  },
  {
    id: 5,
    name: 'v4.4',
    namespace: 'platform / hardware / bsp / kernel / common / v4.4',
    webUrl: 'http://localhost:3000/platform/hardware/bsp/kernel/common/v4.4',
    avatarUrl: null,
  },
];

export const unsortedFrequents = [
  { id: 1, frequency: 12, lastAccessedOn: 1491400843391 },
  { id: 2, frequency: 14, lastAccessedOn: 1488240890738 },
  { id: 3, frequency: 44, lastAccessedOn: 1497675908472 },
  { id: 4, frequency: 8, lastAccessedOn: 1497979281815 },
  { id: 5, frequency: 34, lastAccessedOn: 1488089211943 },
  { id: 6, frequency: 14, lastAccessedOn: 1493517292488 },
  { id: 7, frequency: 42, lastAccessedOn: 1486815299875 },
  { id: 8, frequency: 33, lastAccessedOn: 1500762279114 },
  { id: 10, frequency: 46, lastAccessedOn: 1483251641543 },
];

/**
 * This const has a specific order which tests authenticity
 * of `ProjectsService.getTopFrequentProjects` method so
 * DO NOT change order of items in this const.
 */
export const sortedFrequents = [
  { id: 10, frequency: 46, lastAccessedOn: 1483251641543 },
  { id: 3, frequency: 44, lastAccessedOn: 1497675908472 },
  { id: 7, frequency: 42, lastAccessedOn: 1486815299875 },
  { id: 5, frequency: 34, lastAccessedOn: 1488089211943 },
  { id: 8, frequency: 33, lastAccessedOn: 1500762279114 },
  { id: 6, frequency: 14, lastAccessedOn: 1493517292488 },
  { id: 2, frequency: 14, lastAccessedOn: 1488240890738 },
  { id: 1, frequency: 12, lastAccessedOn: 1491400843391 },
  { id: 4, frequency: 8, lastAccessedOn: 1497979281815 },
];
