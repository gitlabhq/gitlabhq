export const emptyProjectMock = {
  projectId: '',
  name: '',
};

export const selectedProjectMock = {
  projectId: 'gcp-project-123',
  name: 'gcp-project',
};

export const selectedZoneMock = 'us-central1-a';

export const selectedMachineTypeMock = 'n1-standard-2';

export const gapiProjectsResponseMock = {
  projects: [
    {
      projectNumber: '1234',
      projectId: 'gcp-project-123',
      lifecycleState: 'ACTIVE',
      name: 'gcp-project',
      createTime: '2017-12-16T01:48:29.129Z',
      parent: {
        type: 'organization',
        id: '12345',
      },
    },
  ],
};

export const gapiZonesResponseMock = {
  kind: 'compute#zoneList',
  id: 'projects/gitlab-internal-153318/zones',
  items: [
    {
      kind: 'compute#zone',
      id: '2000',
      creationTimestamp: '1969-12-31T16:00:00.000-08:00',
      name: 'us-central1-a',
      description: 'us-central1-a',
      status: 'UP',
      region:
        'https://www.googleapis.com/compute/v1/projects/gitlab-internal-153318/regions/us-central1',
      selfLink:
        'https://www.googleapis.com/compute/v1/projects/gitlab-internal-153318/zones/us-central1-a',
      availableCpuPlatforms: ['Intel Skylake', 'Intel Broadwell', 'Intel Sandy Bridge'],
    },
  ],
  selfLink: 'https://www.googleapis.com/compute/v1/projects/gitlab-internal-153318/zones',
};

export const gapiMachineTypesResponseMock = {
  kind: 'compute#machineTypeList',
  id: 'projects/gitlab-internal-153318/zones/us-central1-a/machineTypes',
  items: [
    {
      kind: 'compute#machineType',
      id: '3002',
      creationTimestamp: '1969-12-31T16:00:00.000-08:00',
      name: 'n1-standard-2',
      description: '2 vCPUs, 7.5 GB RAM',
      guestCpus: 2,
      memoryMb: 7680,
      imageSpaceGb: 10,
      maximumPersistentDisks: 64,
      maximumPersistentDisksSizeGb: '65536',
      zone: 'us-central1-a',
      selfLink:
        'https://www.googleapis.com/compute/v1/projects/gitlab-internal-153318/zones/us-central1-a/machineTypes/n1-standard-2',
      isSharedCpu: false,
    },
  ],
  selfLink:
    'https://www.googleapis.com/compute/v1/projects/gitlab-internal-153318/zones/us-central1-a/machineTypes',
};
