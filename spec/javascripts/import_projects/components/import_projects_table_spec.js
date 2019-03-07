import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/import_projects/store';
import importProjectsTable from '~/import_projects/components/import_projects_table.vue';
import STATUS_MAP from '~/import_projects/constants';
import setTimeoutPromise from '../../helpers/set_timeout_promise_helper';

describe('ImportProjectsTable', () => {
  let vm;
  let mock;
  let store;
  const reposPath = '/repos-path';
  const jobsPath = '/jobs-path';
  const providerTitle = 'THE PROVIDER';
  const providerRepo = { id: 10, sanitizedName: 'sanitizedName', fullName: 'fullName' };
  const importedProject = {
    id: 1,
    fullPath: 'fullPath',
    importStatus: 'started',
    providerLink: 'providerLink',
    importSource: 'importSource',
  };

  function createComponent() {
    const ImportProjectsTable = Vue.extend(importProjectsTable);

    const component = new ImportProjectsTable({
      store,
      propsData: {
        providerTitle,
      },
    }).$mount();

    store.dispatch('stopJobsPolling');

    return component;
  }

  beforeEach(() => {
    store = createStore();
    store.dispatch('setInitialData', { reposPath });
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  it('renders a loading icon whilst repos are loading', done => {
    mock.restore(); // Stop the mock adapter from responding to the request, keeping the spinner up

    vm = createComponent();

    setTimeoutPromise()
      .then(() => {
        expect(vm.$el.querySelector('.js-loading-button-icon')).not.toBeNull();
      })
      .then(() => done())
      .catch(() => done.fail());
  });

  it('renders a table with imported projects and provider repos', done => {
    const response = {
      importedProjects: [importedProject],
      providerRepos: [providerRepo],
      namespaces: [{ path: 'path' }],
    };
    mock.onGet(reposPath).reply(200, response);

    vm = createComponent();

    setTimeoutPromise()
      .then(() => {
        expect(vm.$el.querySelector('.js-loading-button-icon')).toBeNull();
        expect(vm.$el.querySelector('.table')).not.toBeNull();
        expect(vm.$el.querySelector('.import-jobs-from-col').innerText).toMatch(
          `From ${providerTitle}`,
        );

        expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
        expect(vm.$el.querySelector('.js-provider-repo')).not.toBeNull();
      })
      .then(() => done())
      .catch(() => done.fail());
  });

  it('renders an empty state if there are no imported projects or provider repos', done => {
    const response = {
      importedProjects: [],
      providerRepos: [],
      namespaces: [],
    };
    mock.onGet(reposPath).reply(200, response);

    vm = createComponent();

    setTimeoutPromise()
      .then(() => {
        expect(vm.$el.querySelector('.js-loading-button-icon')).toBeNull();
        expect(vm.$el.querySelector('.table')).toBeNull();
        expect(vm.$el.innerText).toMatch(`No ${providerTitle} repositories available to import`);
      })
      .then(() => done())
      .catch(() => done.fail());
  });

  it('imports provider repos if bulk import button is clicked', done => {
    const importPath = '/import-path';
    const response = {
      importedProjects: [],
      providerRepos: [providerRepo],
      namespaces: [{ path: 'path' }],
    };

    mock.onGet(reposPath).replyOnce(200, response);
    mock.onPost(importPath).replyOnce(200, importedProject);

    store.dispatch('setInitialData', { importPath });

    vm = createComponent();

    setTimeoutPromise()
      .then(() => {
        expect(vm.$el.querySelector('.js-imported-project')).toBeNull();
        expect(vm.$el.querySelector('.js-provider-repo')).not.toBeNull();

        vm.$el.querySelector('.js-import-all').click();
      })
      .then(() => setTimeoutPromise())
      .then(() => {
        expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
        expect(vm.$el.querySelector('.js-provider-repo')).toBeNull();
      })
      .then(() => done())
      .catch(() => done.fail());
  });

  it('polls to update the status of imported projects', done => {
    const importPath = '/import-path';
    const response = {
      importedProjects: [importedProject],
      providerRepos: [],
      namespaces: [{ path: 'path' }],
    };
    const updatedProjects = [
      {
        id: importedProject.id,
        importStatus: 'finished',
      },
    ];

    mock.onGet(reposPath).replyOnce(200, response);

    store.dispatch('setInitialData', { importPath, jobsPath });

    vm = createComponent();

    setTimeoutPromise()
      .then(() => {
        const statusObject = STATUS_MAP[importedProject.importStatus];

        expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
        expect(vm.$el.querySelector(`.${statusObject.textClass}`).textContent).toMatch(
          statusObject.text,
        );

        expect(vm.$el.querySelector(`.ic-status_${statusObject.icon}`)).not.toBeNull();

        mock.onGet(jobsPath).replyOnce(200, updatedProjects);
        return store.dispatch('restartJobsPolling');
      })
      .then(() => setTimeoutPromise())
      .then(() => {
        const statusObject = STATUS_MAP[updatedProjects[0].importStatus];

        expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
        expect(vm.$el.querySelector(`.${statusObject.textClass}`).textContent).toMatch(
          statusObject.text,
        );

        expect(vm.$el.querySelector(`.ic-status_${statusObject.icon}`)).not.toBeNull();
      })
      .then(() => done())
      .catch(() => done.fail());
  });
});
