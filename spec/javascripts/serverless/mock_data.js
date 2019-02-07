export const mockServerlessFunctions = [
  {
    name: 'testfunc1',
    namespace: 'tm-example',
    environment_scope: '*',
    cluster_id: 46,
    detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
    podcount: null,
    created_at: '2019-02-05T01:01:23Z',
    url: 'http://testfunc1.tm-example.apps.example.com',
    description: 'A test service',
    image: 'knative-test-container-buildtemplate',
  },
  {
    name: 'testfunc2',
    namespace: 'tm-example',
    environment_scope: '*',
    cluster_id: 46,
    detail_url: '/testuser/testproj/serverless/functions/*/testfunc2',
    podcount: null,
    created_at: '2019-02-05T01:01:23Z',
    url: 'http://testfunc2.tm-example.apps.example.com',
    description: 'A second test service\nThis one with additional descriptions',
    image: 'knative-test-echo-buildtemplate',
  },
];

export const mockServerlessFunctionsDiffEnv = [
  {
    name: 'testfunc1',
    namespace: 'tm-example',
    environment_scope: '*',
    cluster_id: 46,
    detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
    podcount: null,
    created_at: '2019-02-05T01:01:23Z',
    url: 'http://testfunc1.tm-example.apps.example.com',
    description: 'A test service',
    image: 'knative-test-container-buildtemplate',
  },
  {
    name: 'testfunc2',
    namespace: 'tm-example',
    environment_scope: 'test',
    cluster_id: 46,
    detail_url: '/testuser/testproj/serverless/functions/*/testfunc2',
    podcount: null,
    created_at: '2019-02-05T01:01:23Z',
    url: 'http://testfunc2.tm-example.apps.example.com',
    description: 'A second test service\nThis one with additional descriptions',
    image: 'knative-test-echo-buildtemplate',
  },
];

export const mockServerlessFunction = {
  name: 'testfunc1',
  namespace: 'tm-example',
  environment_scope: '*',
  cluster_id: 46,
  detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
  podcount: '3',
  created_at: '2019-02-05T01:01:23Z',
  url: 'http://testfunc1.tm-example.apps.example.com',
  description: 'A test service',
  image: 'knative-test-container-buildtemplate',
};

export const mockMultilineServerlessFunction = {
  name: 'testfunc1',
  namespace: 'tm-example',
  environment_scope: '*',
  cluster_id: 46,
  detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
  podcount: '3',
  created_at: '2019-02-05T01:01:23Z',
  url: 'http://testfunc1.tm-example.apps.example.com',
  description: 'testfunc1\nA test service line\\nWith additional services',
  image: 'knative-test-container-buildtemplate',
};
