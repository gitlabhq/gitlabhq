import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import router from '~/ide/ide_router';
import store from '~/ide/stores';
import { resetStore } from './helpers';
import { project, branch, files } from './mock_data';

describe('IDE router', () => {
  const originaPathName = location.pathname;
  let mock;

  beforeEach(() => {
    spyOn(history, 'pushState');
    spyOn(store, 'dispatch').and.callThrough();

    mock = new MockAdapter(axios);

    mock.onGet('/api/v4/projects/namespace-123%2Fproject-123').reply(200, project);
    mock
      .onGet('/api/v4/projects/namespace-123%2Fproject-123/repository/branches/master')
      .reply(200, branch);
    mock.onGet('/namespace-123/project-123/files/master').reply(200, files);

    history.replaceState({}, '', router.options.base);
  });

  afterEach(done => {
    mock.restore();

    resetStore(store);

    router.push('/project', done);
  });

  afterAll(() => {
    history.replaceState({}, '', originaPathName);
  });

  describe('project path', () => {
    it('loads project data', done => {
      router.push('/project/namespace-123/project-123/', () => {
        expect(store.dispatch).toHaveBeenCalledWith('getProjectData', {
          namespace: 'namespace-123',
          projectId: 'project-123',
        });

        done();
      });
    });

    it('loads project data without trailing slash', done => {
      router.push('/project/namespace-123/project-123', () => {
        expect(store.dispatch).toHaveBeenCalledWith('getProjectData', {
          namespace: 'namespace-123',
          projectId: 'project-123',
        });

        done();
      });
    });
  });

  describe('branch data', () => {
    it('loads branch data', done => {
      router.push('/project/namespace-123/project-123/edit/master/', () => {
        expect(store.dispatch.calls.count()).toBe(3);
        expect(store.dispatch.calls.argsFor(1)).toEqual([
          'getBranchData',
          {
            projectId: 'namespace-123/project-123',
            branchId: 'master',
          },
        ]);

        done();
      });
    });

    it('loads branch data without trailing slash', done => {
      router.push('/project/namespace-123/project-123/edit/master', () => {
        expect(store.dispatch.calls.count()).toBe(3);
        expect(store.dispatch.calls.argsFor(1)).toEqual([
          'getBranchData',
          {
            projectId: 'namespace-123/project-123',
            branchId: 'master',
          },
        ]);

        done();
      });
    });

    it('loads files for branch', done => {
      router.push('/project/namespace-123/project-123/edit/master/', () => {
        expect(store.dispatch.calls.argsFor(2)).toEqual([
          'getFiles',
          {
            projectId: 'namespace-123/project-123',
            branchId: 'master',
          },
        ]);

        done();
      });
    });
  });

  describe('setting folder open', () => {
    it('calls handleTreeEntryAction with folder', done => {
      router.push('/project/namespace-123/project-123/edit/master/folder', () => {
        expect(store.dispatch.calls.argsFor(3)).toEqual([
          'handleTreeEntryAction',
          jasmine.anything(),
        ]);
        expect(store.dispatch.calls.argsFor(3)[1].path).toBe('folder');

        done();
      });
    });

    it('calls handleTreeEntryAction with folder with trailing slash', done => {
      router.push('/project/namespace-123/project-123/edit/master/folder/', () => {
        expect(store.dispatch.calls.argsFor(3)).toEqual([
          'handleTreeEntryAction',
          jasmine.anything(),
        ]);
        expect(store.dispatch.calls.argsFor(3)[1].path).toBe('folder');

        done();
      });
    });

    it('does not call handleTreeEntryAction when file is pending', done => {
      router.push('/project/namespace-123/project-123/edit/master/folder', () => {
        store.dispatch.calls.reset();
        store.state.entries['folder/index.js'].pending = true;

        router.push('/project/namespace-123/project-123/edit/master/folder/index.js', () => {
          expect(store.dispatch.calls.argsFor(3)).not.toEqual([
            'handleTreeEntryAction',
            jasmine.anything(),
          ]);

          done();
        });
      });
    });
  });
});
