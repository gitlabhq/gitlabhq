export const defaultState = {
  isLoading: false,
  endpoint: '',
  repos: [],
};

export const reposServerResponse = [
  {
    destroy_path: 'path',
    id: '123',
    location: 'location',
    path: 'foo',
    tags_path: 'tags_path',
  },
  {
    destroy_path: 'path_',
    id: '456',
    location: 'location_',
    path: 'bar',
    tags_path: 'tags_path_',
  },
];

export const registryServerResponse = [
  {
    name: 'centos7',
    short_revision: 'b118ab5b0',
    revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
    total_size: 679,
    layers: 19,
    location: 'location',
    created_at: 1505828744434,
    destroy_path: 'path_',
  },
  {
    name: 'centos6',
    short_revision: 'b118ab5b0',
    revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
    total_size: 679,
    layers: 19,
    location: 'location',
    created_at: 1505828744434,
  }];

export const parsedReposServerResponse = [
  {
    canDelete: true,
    destroyPath: reposServerResponse[0].destroy_path,
    id: reposServerResponse[0].id,
    isLoading: false,
    list: [],
    location: reposServerResponse[0].location,
    name: reposServerResponse[0].path,
    tagsPath: reposServerResponse[0].tags_path,
  },
  {
    canDelete: true,
    destroyPath: reposServerResponse[1].destroy_path,
    id: reposServerResponse[1].id,
    isLoading: false,
    list: [],
    location: reposServerResponse[1].location,
    name: reposServerResponse[1].path,
    tagsPath: reposServerResponse[1].tags_path,
  },
];

export const parsedRegistryServerResponse = [
  {
    tag: registryServerResponse[0].name,
    revision: registryServerResponse[0].revision,
    shortRevision: registryServerResponse[0].short_revision,
    size: registryServerResponse[0].total_size,
    layers: registryServerResponse[0].layers,
    location: registryServerResponse[0].location,
    createdAt: registryServerResponse[0].created_at,
    destroyPath: registryServerResponse[0].destroy_path,
    canDelete: true,
  },
  {
    tag: registryServerResponse[1].name,
    revision: registryServerResponse[1].revision,
    shortRevision: registryServerResponse[1].short_revision,
    size: registryServerResponse[1].total_size,
    layers: registryServerResponse[1].layers,
    location: registryServerResponse[1].location,
    createdAt: registryServerResponse[1].created_at,
    destroyPath: registryServerResponse[1].destroy_path,
    canDelete: false,
  },
];

export const repoPropsData = {
  canDelete: true,
  destroyPath: 'path',
  id: '123',
  isLoading: false,
  list: [
    {
      tag: 'centos6',
      revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
      shortRevision: 'b118ab5b0',
      size: 19,
      layers: 10,
      location: 'location',
      createdAt: 1505828744434,
      destroyPath: 'path',
      canDelete: true,
    },
  ],
  location: 'location',
  name: 'foo',
  tagsPath: 'path',
  pagination: {
    perPage: 5,
    page: 1,
    total: 13,
    totalPages: 1,
    nextPage: null,
    previousPage: null,
  },
};
