import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Api from '~/api';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = 'http://host.invalid';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };
  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = Object.assign({}, dummyGon);
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('buildUrl', () => {
    it('adds URL root and fills in API version', () => {
      const input = '/api/:version/foo/bar';
      const expectedOutput = `${dummyUrlRoot}/api/${dummyApiVersion}/foo/bar`;

      const builtUrl = Api.buildUrl(input);

      expect(builtUrl).toEqual(expectedOutput);
    });
  });

  describe('group', () => {
    it('fetches a group', done => {
      const groupId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}`;
      mock.onGet(expectedUrl).reply(200, {
        name: 'test',
      });

      Api.group(groupId, response => {
        expect(response.name).toBe('test');
        done();
      });
    });
  });

  describe('groups', () => {
    it('fetches groups', done => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups.json`;
      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.groups(query, options, response => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('namespaces', () => {
    it('fetches namespaces', done => {
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/namespaces.json`;
      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.namespaces(query, response => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('projects', () => {
    it('fetches projects with membership when logged in', done => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      window.gon.current_user_id = 1;
      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.projects(query, options, response => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });

    it('fetches projects without membership when not logged in', done => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.projects(query, options, response => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('mergerequest', () => {
    it('fetches a merge request', done => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}`;
      mock.onGet(expectedUrl).reply(200, {
        title: 'test',
      });

      Api.mergeRequest(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.title).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('mergerequest changes', () => {
    it('fetches the changes of a merge request', done => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/changes`;
      mock.onGet(expectedUrl).reply(200, {
        title: 'test',
      });

      Api.mergeRequestChanges(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.title).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('mergerequest versions', () => {
    it('fetches the versions of a merge request', done => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/versions`;
      mock.onGet(expectedUrl).reply(200, [
        {
          id: 123,
        },
      ]);

      Api.mergeRequestVersions(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].id).toBe(123);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('newLabel', () => {
    it('creates a new label', done => {
      const namespace = 'some namespace';
      const project = 'some project';
      const labelData = { some: 'data' };
      const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/labels`;
      const expectedData = {
        label: labelData,
      };
      mock.onPost(expectedUrl).reply(config => {
        expect(config.data).toBe(JSON.stringify(expectedData));

        return [
          200,
          {
            name: 'test',
          },
        ];
      });

      Api.newLabel(namespace, project, labelData, response => {
        expect(response.name).toBe('test');
        done();
      });
    });

    it('creates a group label', done => {
      const namespace = 'group/subgroup';
      const labelData = { some: 'data' };
      const expectedUrl = `${dummyUrlRoot}/groups/${namespace}/-/labels`;
      const expectedData = {
        label: labelData,
      };
      mock.onPost(expectedUrl).reply(config => {
        expect(config.data).toBe(JSON.stringify(expectedData));

        return [
          200,
          {
            name: 'test',
          },
        ];
      });

      Api.newLabel(namespace, undefined, labelData, response => {
        expect(response.name).toBe('test');
        done();
      });
    });
  });

  describe('groupProjects', () => {
    it('fetches group projects', done => {
      const groupId = '123456';
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/projects.json`;
      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.groupProjects(groupId, query, response => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
        done();
      });
    });
  });

  describe('licenseText', () => {
    it('fetches a license text', done => {
      const licenseKey = "driver's license";
      const data = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/licenses/${licenseKey}`;
      mock.onGet(expectedUrl).reply(200, 'test');

      Api.licenseText(licenseKey, data, response => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('gitignoreText', () => {
    it('fetches a gitignore text', done => {
      const gitignoreKey = 'ignore git';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/gitignores/${gitignoreKey}`;
      mock.onGet(expectedUrl).reply(200, 'test');

      Api.gitignoreText(gitignoreKey, response => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('gitlabCiYml', () => {
    it('fetches a .gitlab-ci.yml', done => {
      const gitlabCiYmlKey = 'Y CI ML';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/gitlab_ci_ymls/${gitlabCiYmlKey}`;
      mock.onGet(expectedUrl).reply(200, 'test');

      Api.gitlabCiYml(gitlabCiYmlKey, response => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('dockerfileYml', () => {
    it('fetches a Dockerfile', done => {
      const dockerfileYmlKey = 'a giant whale';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/dockerfiles/${dockerfileYmlKey}`;
      mock.onGet(expectedUrl).reply(200, 'test');

      Api.dockerfileYml(dockerfileYmlKey, response => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('issueTemplate', () => {
    it('fetches an issue template', done => {
      const namespace = 'some namespace';
      const project = 'some project';
      const templateKey = ' template #%?.key ';
      const templateType = 'template type';
      const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/templates/${templateType}/${encodeURIComponent(
        templateKey,
      )}`;
      mock.onGet(expectedUrl).reply(200, 'test');

      Api.issueTemplate(namespace, project, templateKey, templateType, (error, response) => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('users', () => {
    it('fetches users', done => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users.json`;
      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.users(query, options)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].name).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
