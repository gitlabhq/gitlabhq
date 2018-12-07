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

  describe('projectMergeRequest', () => {
    it('fetches a merge request', done => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}`;
      mock.onGet(expectedUrl).reply(200, {
        title: 'test',
      });

      Api.projectMergeRequest(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.title).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectMergeRequestChanges', () => {
    it('fetches the changes of a merge request', done => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/changes`;
      mock.onGet(expectedUrl).reply(200, {
        title: 'test',
      });

      Api.projectMergeRequestChanges(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.title).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectMergeRequestVersions', () => {
    it('fetches the versions of a merge request', done => {
      const projectPath = 'abc';
      const mergeRequestId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/merge_requests/${mergeRequestId}/versions`;
      mock.onGet(expectedUrl).reply(200, [
        {
          id: 123,
        },
      ]);

      Api.projectMergeRequestVersions(projectPath, mergeRequestId)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].id).toBe(123);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('projectRunners', () => {
    it('fetches the runners of a project', done => {
      const projectPath = 7;
      const params = { scope: 'active' };
      const mockData = [{ id: 4 }];
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/runners`;
      mock.onGet(expectedUrl, { params }).reply(200, mockData);

      Api.projectRunners(projectPath, { params })
        .then(({ data }) => {
          expect(data).toEqual(mockData);
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

      Api.groupProjects(groupId, query, {}, response => {
        expect(response.length).toBe(1);
        expect(response[0].name).toBe('test');
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

  describe('projectTemplates', () => {
    it('fetches a list of templates', done => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/gitlab-org%2Fgitlab-ce/templates/licenses`;

      mock.onGet(expectedUrl).reply(200, 'test');

      Api.projectTemplates('gitlab-org/gitlab-ce', 'licenses', {}, response => {
        expect(response).toBe('test');
        done();
      });
    });
  });

  describe('projectTemplate', () => {
    it('fetches a single template', done => {
      const data = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/gitlab-org%2Fgitlab-ce/templates/licenses/test%20license`;

      mock.onGet(expectedUrl).reply(200, 'test');

      Api.projectTemplate('gitlab-org/gitlab-ce', 'licenses', 'test license', data, response => {
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

  describe('commitPipelines', () => {
    it('fetches pipelines for a given commit', done => {
      const projectId = 'example/foobar';
      const commitSha = 'abc123def';
      const expectedUrl = `${dummyUrlRoot}/${projectId}/commit/${commitSha}/pipelines`;
      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.commitPipelines(projectId, commitSha)
        .then(({ data }) => {
          expect(data.length).toBe(1);
          expect(data[0].name).toBe('test');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('createBranch', () => {
    it('creates new branch', done => {
      const ref = 'master';
      const branch = 'new-branch-name';
      const dummyProjectPath = 'gitlab-org/gitlab-ce';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodeURIComponent(
        dummyProjectPath,
      )}/repository/branches`;

      spyOn(axios, 'post').and.callThrough();

      mock.onPost(expectedUrl).replyOnce(200, {
        name: branch,
      });

      Api.createBranch(dummyProjectPath, { ref, branch })
        .then(({ data }) => {
          expect(data.name).toBe(branch);
          expect(axios.post).toHaveBeenCalledWith(expectedUrl, { ref, branch });
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
