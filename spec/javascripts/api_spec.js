import Api from '~/api';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = 'http://host.invalid';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };
  const dummyResponse = 'hello from outer space!';
  const sendDummyResponse = () => {
    const deferred = $.Deferred();
    deferred.resolve(dummyResponse);
    return deferred.promise();
  };
  let originalGon;

  beforeEach(() => {
    originalGon = window.gon;
    window.gon = Object.assign({}, dummyGon);
  });

  afterEach(() => {
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
    it('fetches a group', (done) => {
      const groupId = '123456';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}.json`;
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        return sendDummyResponse();
      });

      Api.group(groupId, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('groups', () => {
    it('fetches groups', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups.json`;
      const expectedData = Object.assign({
        search: query,
        per_page: 20,
      }, options);
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.groups(query, options, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('namespaces', () => {
    it('fetches namespaces', (done) => {
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/namespaces.json`;
      const expectedData = {
        search: query,
        per_page: 20,
      };
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.namespaces(query, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('projects', () => {
    it('fetches projects with membership when logged in', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      window.gon.current_user_id = 1;
      const expectedData = Object.assign({
        search: query,
        per_page: 20,
        membership: true,
        simple: true,
      }, options);
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.projects(query, options, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });

    it('fetches projects without membership when not logged in', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects.json`;
      const expectedData = Object.assign({
        search: query,
        per_page: 20,
        simple: true,
      }, options);
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.projects(query, options, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('newLabel', () => {
    it('creates a new label', (done) => {
      const namespace = 'some namespace';
      const project = 'some project';
      const labelData = { some: 'data' };
      const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/labels`;
      const expectedData = {
        label: labelData,
      };
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.type).toEqual('POST');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.newLabel(namespace, project, labelData, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });

    it('creates a new group label', (done) => {
      const namespace = 'some namespace';
      const labelData = { some: 'data' };
      const expectedUrl = Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespace);
      const expectedData = {
        label: labelData,
      };
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.type).toEqual('POST');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.newLabel(namespace, null, labelData, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('groupProjects', () => {
    it('fetches group projects', (done) => {
      const groupId = '123456';
      const query = 'dummy query';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/projects.json`;
      const expectedData = {
        search: query,
        per_page: 20,
      };
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.groupProjects(groupId, query, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('licenseText', () => {
    it('fetches a license text', (done) => {
      const licenseKey = "driver's license";
      const data = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/licenses/${licenseKey}`;
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.data).toEqual(data);
        return sendDummyResponse();
      });

      Api.licenseText(licenseKey, data, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('gitignoreText', () => {
    it('fetches a gitignore text', (done) => {
      const gitignoreKey = 'ignore git';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/gitignores/${gitignoreKey}`;
      spyOn(jQuery, 'get').and.callFake((url, callback) => {
        expect(url).toEqual(expectedUrl);
        callback(dummyResponse);
      });

      Api.gitignoreText(gitignoreKey, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('gitlabCiYml', () => {
    it('fetches a .gitlab-ci.yml', (done) => {
      const gitlabCiYmlKey = 'Y CI ML';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/gitlab_ci_ymls/${gitlabCiYmlKey}`;
      spyOn(jQuery, 'get').and.callFake((url, callback) => {
        expect(url).toEqual(expectedUrl);
        callback(dummyResponse);
      });

      Api.gitlabCiYml(gitlabCiYmlKey, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('dockerfileYml', () => {
    it('fetches a Dockerfile', (done) => {
      const dockerfileYmlKey = 'a giant whale';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/templates/dockerfiles/${dockerfileYmlKey}`;
      spyOn(jQuery, 'get').and.callFake((url, callback) => {
        expect(url).toEqual(expectedUrl);
        callback(dummyResponse);
      });

      Api.dockerfileYml(dockerfileYmlKey, (response) => {
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('issueTemplate', () => {
    it('fetches an issue template', (done) => {
      const namespace = 'some namespace';
      const project = 'some project';
      const templateKey = ' template #%?.key ';
      const templateType = 'template type';
      const expectedUrl = `${dummyUrlRoot}/${namespace}/${project}/templates/${templateType}/${encodeURIComponent(templateKey)}`;
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        return sendDummyResponse();
      });

      Api.issueTemplate(namespace, project, templateKey, templateType, (error, response) => {
        expect(error).toBe(null);
        expect(response).toBe(dummyResponse);
        done();
      });
    });
  });

  describe('users', () => {
    it('fetches users', (done) => {
      const query = 'dummy query';
      const options = { unused: 'option' };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/users.json`;
      const expectedData = Object.assign({
        search: query,
        per_page: 20,
      }, options);
      spyOn(jQuery, 'ajax').and.callFake((request) => {
        expect(request.url).toEqual(expectedUrl);
        expect(request.dataType).toEqual('json');
        expect(request.data).toEqual(expectedData);
        return sendDummyResponse();
      });

      Api.users(query, options)
        .then((response) => {
          expect(response).toBe(dummyResponse);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('ldap_groups', () => {
    it('calls callback on completion', (done) => {
      const query = 'query';
      const provider = 'provider';
      const callback = jasmine.createSpy();

      spyOn(jQuery, 'ajax').and.callFake(() => $.Deferred().resolve());

      Api.ldap_groups(query, provider, callback)
        .then((response) => {
          expect(callback).toHaveBeenCalledWith(response);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
