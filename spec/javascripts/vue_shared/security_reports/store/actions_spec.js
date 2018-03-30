import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import * as actions from 'ee/vue_shared/security_reports/store/actions';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import state from 'ee/vue_shared/security_reports/store/state';
import testAction from '../../../helpers/vuex_action_helper';
import {
  sastIssues,
  sastIssuesBase,
  dast,
  dastBase,
  dockerReport,
  dockerBaseReport,
} from '../mock_data';

describe('security reports actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setHeadBlobPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setHeadBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_HEAD_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setBaseBlobPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setBaseBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_BASE_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setSastHeadPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setSastHeadPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_SAST_HEAD_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setSastBasePath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setSastBasePath,
        'path',
        mockedState,
        [
          {
            type: types.SET_SAST_BASE_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestSastReports', () => {
    it('should commit request mutation', done => {
      testAction(
        actions.requestSastReports,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_SAST_REPORTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastReports', () => {
    it('should commit request mutation', done => {
      testAction(
        actions.receiveSastReports,
        {},
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_REPORTS,
            payload: {},
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastError', () => {
    it('should commit sast error mutation', done => {
      testAction(
        actions.receiveSastError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_REPORTS_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchSastReports', () => {
    describe('with head and base', () => {
      it('should dispatch `receiveSastReports`', done => {
        mock.onGet('foo').reply(200, sastIssues);
        mock.onGet('bar').reply(200, sastIssuesBase);

        mockedState.sast.paths.head = 'foo';
        mockedState.sast.paths.base = 'bar';

        testAction(
          actions.fetchSastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastReports',
            },
            {
              type: 'receiveSastReports',
              payload: { head: sastIssues, base: sastIssuesBase },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sast.paths.head = 'foo';
        mockedState.sast.paths.base = 'bar';

        testAction(
          actions.fetchSastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastReports',
            },
            {
              type: 'receiveSastError',
            },
          ],
          done,
        );
      });
    });

    describe('with head', () => {
      it('should dispatch `receiveSastReports`', done => {
        mock.onGet('foo').reply(200, sastIssues);

        mockedState.sast.paths.head = 'foo';

        testAction(
          actions.fetchSastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastReports',
            },
            {
              type: 'receiveSastReports',
              payload: { head: sastIssues, base: null },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sast.paths.head = 'foo';

        testAction(
          actions.fetchSastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastReports',
            },
            {
              type: 'receiveSastError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setSastContainerHeadPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setSastContainerHeadPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_SAST_CONTAINER_HEAD_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setSastContainerBasePath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setSastContainerBasePath,
        'path',
        mockedState,
        [
          {
            type: types.SET_SAST_CONTAINER_BASE_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestSastContainerReports', () => {
    it('should commit request mutation', done => {
      testAction(
        actions.requestSastContainerReports,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_SAST_CONTAINER_REPORTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastContainerReports', () => {
    it('should commit sast receive mutation', done => {
      testAction(
        actions.receiveSastContainerReports,
        {},
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_CONTAINER_REPORTS,
            payload: {},
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastContainerError', () => {
    it('should commit sast error mutation', done => {
      testAction(
        actions.receiveSastContainerError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_CONTAINER_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchSastContainerReports', () => {
    describe('with head and base', () => {
      it('should dispatch `receiveSastContainerReports`', done => {
        mock.onGet('foo').reply(200, dockerReport);
        mock.onGet('bar').reply(200, dockerBaseReport);

        mockedState.sastContainer.paths.head = 'foo';
        mockedState.sastContainer.paths.base = 'bar';

        testAction(
          actions.fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerReports',
              payload: { head: dockerReport, base: dockerBaseReport },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastContainerError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sastContainer.paths.head = 'foo';
        mockedState.sastContainer.paths.base = 'bar';

        testAction(
          actions.fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerError',
            },
          ],
          done,
        );
      });
    });

    describe('with head', () => {
      it('should dispatch `receiveSastContainerReports`', done => {
        mock.onGet('foo').reply(200, dockerReport);

        mockedState.sastContainer.paths.head = 'foo';

        testAction(
          actions.fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerReports',
              payload: { head: dockerReport, base: null },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sastContainer.paths.head = 'foo';

        testAction(
          actions.fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDastHeadPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setDastHeadPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DAST_HEAD_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setDastBasePath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setDastBasePath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DAST_BASE_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDastReports', () => {
    it('should commit request mutation', done => {
      testAction(
        actions.requestDastReports,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DAST_REPORTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastReports', () => {
    it('should commit sast receive mutation', done => {
      testAction(
        actions.receiveDastReports,
        {},
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_REPORTS,
            payload: {},
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastError', () => {
    it('should commit sast error mutation', done => {
      testAction(
        actions.receiveDastError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDastReports', () => {
    describe('with head and base', () => {
      it('should dispatch `receiveDastReports`', done => {
        mock.onGet('foo').reply(200, dast);
        mock.onGet('bar').reply(200, dastBase);

        mockedState.dast.paths.head = 'foo';
        mockedState.dast.paths.base = 'bar';

        testAction(
          actions.fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastReports',
              payload: { head: dast, base: dastBase },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dast.paths.head = 'foo';
        mockedState.dast.paths.base = 'bar';

        testAction(
          actions.fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastError',
            },
          ],
          done,
        );
      });
    });

    describe('with head', () => {
      it('should dispatch `receiveSastContainerReports`', done => {
        mock.onGet('foo').reply(200, dast);
        mockedState.dast.paths.head = 'foo';

        testAction(
          actions.fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastReports',
              payload: { head: dast, base: null },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dast.paths.head = 'foo';

        testAction(
          actions.fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDependencyScanningHeadPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setDependencyScanningHeadPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DEPENDENCY_SCANNING_HEAD_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setDependencyScanningBasePath', () => {
    it('should commit set head blob path', done => {
      testAction(
        actions.setDependencyScanningBasePath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DEPENDENCY_SCANNING_BASE_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDependencyScanningReports', () => {
    it('should commit request mutation', done => {
      testAction(
        actions.requestDependencyScanningReports,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DEPENDENCY_SCANNING_REPORTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningReports', () => {
    it('should commit sast receive mutation', done => {
      testAction(
        actions.receiveDependencyScanningReports,
        {},
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_REPORTS,
            payload: {},
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningError', () => {
    it('should commit sast error mutation', done => {
      testAction(
        actions.receiveDependencyScanningError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDependencyScanningReports', () => {
    describe('with head and base', () => {
      it('should dispatch `receiveDependencyScanningReports`', done => {
        mock.onGet('foo').reply(200, sastIssues);
        mock.onGet('bar').reply(200, sastIssuesBase);

        mockedState.dependencyScanning.paths.head = 'foo';
        mockedState.dependencyScanning.paths.base = 'bar';

        testAction(
          actions.fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningReports',
              payload: { head: sastIssues, base: sastIssuesBase },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDependencyScanningError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dependencyScanning.paths.head = 'foo';
        mockedState.dependencyScanning.paths.base = 'bar';

        testAction(
          actions.fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningError',
            },
          ],
          done,
        );
      });
    });

    describe('with head', () => {
      it('should dispatch `receiveDependencyScanningReports`', done => {
        mock.onGet('foo').reply(200, sastIssues);
        mockedState.dependencyScanning.paths.head = 'foo';

        testAction(
          actions.fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningReports',
              payload: { head: sastIssues, base: null },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDependencyScanningError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dependencyScanning.paths.head = 'foo';

        testAction(
          actions.fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningError',
            },
          ],
          done,
        );
      });
    });
  });
});
