export const currentSession = {
  groups: {
    username: 'root',
    storageKey: 'root/frequent-groups',
    apiVersion: 'v4',
    group: {
      id: 1,
      name: 'dummy-group',
      full_name: 'dummy-parent-group',
      webUrl: `${gl.TEST_HOST}/dummy-group`,
      avatarUrl: null,
      lastAccessedOn: Date.now(),
    },
  },
  projects: {
    username: 'root',
    storageKey: 'root/frequent-projects',
    apiVersion: 'v4',
    project: {
      id: 1,
      name: 'dummy-project',
      namespace: 'SampleGroup / Dummy-Project',
      webUrl: `${gl.TEST_HOST}/samplegroup/dummy-project`,
      avatarUrl: null,
      lastAccessedOn: Date.now(),
    },
  },
};

export const mockNamespace = 'projects';

export const mockStorageKey = 'test-user/frequent-projects';

export const mockGroup = {
  id: 1,
  name: 'Sub451',
  namespace: 'Commit451 / Sub451',
  webUrl: `${gl.TEST_HOST}/Commit451/Sub451`,
  avatarUrl: null,
};

export const mockRawGroup = {
  id: 1,
  name: 'Sub451',
  full_name: 'Commit451 / Sub451',
  web_url: `${gl.TEST_HOST}/Commit451/Sub451`,
  avatar_url: null,
};

export const mockFrequentGroups = [
  {
    id: 3,
    name: 'Subgroup451',
    full_name: 'Commit451 / Subgroup451',
    webUrl: '/Commit451/Subgroup451',
    avatarUrl: null,
    frequency: 7,
    lastAccessedOn: 1497979281815,
  },
  {
    id: 1,
    name: 'Commit451',
    full_name: 'Commit451',
    webUrl: '/Commit451',
    avatarUrl: null,
    frequency: 3,
    lastAccessedOn: 1497979281815,
  },
];

export const mockSearchedGroups = [mockRawGroup];
export const mockProcessedSearchedGroups = [mockGroup];

export const mockProject = {
  id: 1,
  name: 'GitLab Community Edition',
  namespace: 'gitlab-org / gitlab-ce',
  webUrl: `${gl.TEST_HOST}/gitlab-org/gitlab-foss`,
  avatarUrl: null,
};

export const mockRawProject = {
  id: 1,
  name: 'GitLab Community Edition',
  name_with_namespace: 'gitlab-org / gitlab-ce',
  web_url: `${gl.TEST_HOST}/gitlab-org/gitlab-foss`,
  avatar_url: null,
};

export const mockFrequentProjects = [
  {
    id: 1,
    name: 'GitLab Community Edition',
    namespace: 'gitlab-org / gitlab-ce',
    webUrl: `${gl.TEST_HOST}/gitlab-org/gitlab-foss`,
    avatarUrl: null,
    frequency: 1,
    lastAccessedOn: Date.now(),
  },
  {
    id: 2,
    name: 'GitLab CI',
    namespace: 'gitlab-org / gitlab-ci',
    webUrl: `${gl.TEST_HOST}/gitlab-org/gitlab-ci`,
    avatarUrl: null,
    frequency: 9,
    lastAccessedOn: Date.now(),
  },
  {
    id: 3,
    name: 'Typeahead.Js',
    namespace: 'twitter / typeahead-js',
    webUrl: `${gl.TEST_HOST}/twitter/typeahead-js`,
    avatarUrl: '/uploads/-/system/project/avatar/7/TWBS.png',
    frequency: 2,
    lastAccessedOn: Date.now(),
  },
  {
    id: 4,
    name: 'Intel',
    namespace: 'platform / hardware / bsp / intel',
    webUrl: `${gl.TEST_HOST}/platform/hardware/bsp/intel`,
    avatarUrl: null,
    frequency: 3,
    lastAccessedOn: Date.now(),
  },
  {
    id: 5,
    name: 'v4.4',
    namespace: 'platform / hardware / bsp / kernel / common / v4.4',
    webUrl: `${gl.TEST_HOST}/platform/hardware/bsp/kernel/common/v4.4`,
    avatarUrl: null,
    frequency: 8,
    lastAccessedOn: Date.now(),
  },
];

export const mockSearchedProjects = { data: [mockRawProject] };
export const mockProcessedSearchedProjects = [mockProject];

export const unsortedFrequentItems = [
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
 * of `getTopFrequentItems` method so
 * DO NOT change order of items in this const.
 */
export const sortedFrequentItems = [
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
