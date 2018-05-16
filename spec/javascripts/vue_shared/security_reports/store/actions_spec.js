import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import actions, {
  setHeadBlobPath,
  setBaseBlobPath,
  setVulnerabilityFeedbackPath,
  setVulnerabilityFeedbackHelpPath,
  setPipelineId,
  setSastHeadPath,
  setSastBasePath,
  requestSastReports,
  receiveSastReports,
  receiveSastError,
  fetchSastReports,
  setSastContainerHeadPath,
  setSastContainerBasePath,
  requestSastContainerReports,
  receiveSastContainerReports,
  receiveSastContainerError,
  fetchSastContainerReports,
  setDastHeadPath,
  setDastBasePath,
  requestDastReports,
  receiveDastReports,
  receiveDastError,
  fetchDastReports,
  setDependencyScanningHeadPath,
  setDependencyScanningBasePath,
  requestDependencyScanningReports,
  receiveDependencyScanningError,
  receiveDependencyScanningReports,
  fetchDependencyScanningReports,
  openModal,
  setModalData,
  requestDismissIssue,
  receiveDismissIssue,
  receiveDismissIssueError,
  dismissIssue,
  revertDismissIssue,
  requestCreateIssue,
  receiveCreateIssue,
  receiveCreateIssueError,
  createNewIssue,
  updateSastIssue,
  updateDependencyScanningIssue,
  updateContainerScanningIssue,
  updateDastIssue,
} from 'ee/vue_shared/security_reports/store/actions';
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
  sastFeedbacks,
  dastFeedbacks,
  containerScanningFeedbacks,
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
        setHeadBlobPath,
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
        setBaseBlobPath,
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

  describe('setVulnerabilityFeedbackPath', () => {
    it('should commit set vulnerabulity feedback path', done => {
      testAction(
        setVulnerabilityFeedbackPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_VULNERABILITY_FEEDBACK_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilityFeedbackHelpPath', () => {
    it('should commit set vulnerabulity feedback help path', done => {
      testAction(
        setVulnerabilityFeedbackHelpPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_VULNERABILITY_FEEDBACK_HELP_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setPipelineId', () => {
    it('should commit set vulnerability feedback path', done => {
      testAction(
        setPipelineId,
        123,
        mockedState,
        [
          {
            type: types.SET_PIPELINE_ID,
            payload: 123,
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
        setSastHeadPath,
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
        setSastBasePath,
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
        requestSastReports,
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
        receiveSastReports,
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
        receiveSastError,
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
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'sast',
            },
          })
          .reply(200, sastFeedbacks);

        mockedState.sast.paths.head = 'foo';
        mockedState.sast.paths.base = 'bar';
        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        testAction(
          fetchSastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastReports',
            },
            {
              type: 'receiveSastReports',
              payload: { head: sastIssues, base: sastIssuesBase, enrichData: sastFeedbacks },
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
          fetchSastReports,
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
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'sast',
            },
          })
          .reply(200, sastFeedbacks);

        mockedState.sast.paths.head = 'foo';
        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';

        testAction(
          fetchSastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastReports',
            },
            {
              type: 'receiveSastReports',
              payload: { head: sastIssues, base: null, enrichData: sastFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sast.paths.head = 'foo';

        testAction(
          fetchSastReports,
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
        setSastContainerHeadPath,
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
        setSastContainerBasePath,
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
        requestSastContainerReports,
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
        receiveSastContainerReports,
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
        receiveSastContainerError,
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
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.sastContainer.paths.head = 'foo';
        mockedState.sastContainer.paths.base = 'bar';

        testAction(
          fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerReports',
              payload: {
                head: dockerReport,
                base: dockerBaseReport,
                enrichData: containerScanningFeedbacks,
              },
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
          fetchSastContainerReports,
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
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';

        mockedState.sastContainer.paths.head = 'foo';

        testAction(
          fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerReports',
              payload: { head: dockerReport, base: null, enrichData: containerScanningFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sastContainer.paths.head = 'foo';

        testAction(
          fetchSastContainerReports,
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
        setDastHeadPath,
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
        setDastBasePath,
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
        requestDastReports,
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
        receiveDastReports,
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
        receiveDastError,
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

        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dast.paths.head = 'foo';
        mockedState.dast.paths.base = 'bar';

        testAction(
          fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastReports',
              payload: { head: dast, base: dastBase, enrichData: dastFeedbacks },
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
          fetchDastReports,
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
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dast.paths.head = 'foo';

        testAction(
          fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastReports',
              payload: { head: dast, base: null, enrichData: dastFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dast.paths.head = 'foo';

        testAction(
          fetchDastReports,
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
        setDependencyScanningHeadPath,
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
        setDependencyScanningBasePath,
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
        requestDependencyScanningReports,
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
        receiveDependencyScanningReports,
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
        receiveDependencyScanningError,
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
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, sastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dependencyScanning.paths.head = 'foo';
        mockedState.dependencyScanning.paths.base = 'bar';

        testAction(
          fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningReports',
              payload: { head: sastIssues, base: sastIssuesBase, enrichData: sastFeedbacks },
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
          fetchDependencyScanningReports,
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
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, sastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dependencyScanning.paths.head = 'foo';

        testAction(
          fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningReports',
              payload: { head: sastIssues, base: null, enrichData: sastFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDependencyScanningError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dependencyScanning.paths.head = 'foo';

        testAction(
          fetchDependencyScanningReports,
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

  describe('openModal', () => {
    it('dispatches setModalData action', done => {
      testAction(
        openModal,
        { id: 1 },
        mockedState,
        [],
        [
          {
            type: 'setModalData',
            payload: { id: 1 },
          },
        ],
        done,
      );
    });
  });

  describe('setModalData', () => {
    it('commits set issue modal data', done => {
      testAction(
        setModalData,
        { id: 1 },
        mockedState,
        [
          {
            type: types.SET_ISSUE_MODAL_DATA,
            payload: { id: 1 },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDismissIssue', () => {
    it('commits request dismiss issue', done => {
      testAction(
        requestDismissIssue,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DISMISS_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissIssue', () => {
    it('commits receive dismiss issue', done => {
      testAction(
        receiveDismissIssue,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_ISSUE_SUCCESS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissIssueError', () => {
    it('commits receive dismiss issue error with payload', done => {
      testAction(
        receiveDismissIssueError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_ISSUE_ERROR,
            payload: 'error',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('dismissIssue', () => {
    describe('with success', () => {
      let dismissalFeedback;
      beforeEach(() => {
        dismissalFeedback = {
          foo: 'bar',
        };
        mock.onPost('dismiss_issue_path').reply(200, dismissalFeedback);
        mockedState.vulnerabilityFeedbackPath = 'dismiss_issue_path';
      });

      it('with success should dispatch `receiveDismissIssue`', done => {
        testAction(
          dismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
          ],
          done,
        );
      });

      it('should dispatch `updateSastIssue` for sast issue', done => {
        mockedState.modal.vulnerability.category = 'sast';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: true,
          dismissalFeedback,
        };

        testAction(
          dismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateSastIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });

      it('should dispatch `updateDependencyScanningIssue` for dependency scanning issue', done => {
        mockedState.modal.vulnerability.category = 'dependency_scanning';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: true,
          dismissalFeedback,
        };

        testAction(
          dismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateDependencyScanningIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });

      it('should dispatch `updateContainerScanningIssue` for container scanning issue', done => {
        mockedState.modal.vulnerability.category = 'container_scanning';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: true,
          dismissalFeedback,
        };

        testAction(
          dismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateContainerScanningIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });

      it('should dispatch `updateDastIssue` for dast issue', done => {
        mockedState.modal.vulnerability.category = 'dast';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: true,
          dismissalFeedback,
        };

        testAction(
          dismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateDastIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });
    });

    it('with error should dispatch `receiveDismissIssueError`', done => {
      mock.onPost('dismiss_issue_path').reply(500, {});
      mockedState.vulnerabilityFeedbackPath = 'dismiss_issue_path';

      testAction(
        dismissIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestDismissIssue',
          },
          {
            type: 'receiveDismissIssueError',
          },
        ],
        done,
      );
    });
  });

  describe('revertDismissIssue', () => {
    describe('with success', () => {
      beforeEach(() => {
        mock.onDelete('dismiss_issue_path/123').reply(200, {});
        mockedState.modal.vulnerability.dismissalFeedback = { id: 123 };
        mockedState.vulnerabilityFeedbackPath = 'dismiss_issue_path';
      });

      it('should dispatch `receiveDismissIssue`', done => {
        testAction(
          revertDismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
          ],
          done,
        );
      });

      it('should dispatch `updateSastIssue` for sast issue', done => {
        mockedState.modal.vulnerability.category = 'sast';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: false,
          dismissalFeedback: null,
        };

        testAction(
          revertDismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateSastIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });

      it('should dispatch `updateDependencyScanningIssue` for dependency scanning issue', done => {
        mockedState.modal.vulnerability.category = 'dependency_scanning';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: false,
          dismissalFeedback: null,
        };

        testAction(
          revertDismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateDependencyScanningIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });

      it('should dispatch `updateContainerScanningIssue` for container scanning issue', done => {
        mockedState.modal.vulnerability.category = 'container_scanning';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: false,
          dismissalFeedback: null,
        };

        testAction(
          revertDismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateContainerScanningIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });

      it('should dispatch `updateDastIssue` for dast issue', done => {
        mockedState.modal.vulnerability.category = 'dast';
        const expectedUpdatePayload = {
          ...mockedState.modal.vulnerability,
          isDismissed: false,
          dismissalFeedback: null,
        };

        testAction(
          revertDismissIssue,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissIssue',
            },
            {
              type: 'receiveDismissIssue',
            },
            {
              type: 'updateDastIssue',
              payload: expectedUpdatePayload,
            },
          ],
          done,
        );
      });
    });

    it('with error should dispatch `receiveDismissIssueError`', done => {
      mock.onDelete('dismiss_issue_path/123').reply(500, {});
      mockedState.modal.vulnerability.dismissalFeedback = { id: 123 };
      mockedState.vulnerabilityFeedbackPath = 'dismiss_issue_path';

      testAction(
        revertDismissIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestDismissIssue',
          },
          {
            type: 'receiveDismissIssueError',
          },
        ],
        done,
      );
    });
  });

  describe('requestCreateIssue', () => {
    it('commits request create issue', done => {
      testAction(
        requestCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CREATE_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssue', () => {
    it('commits receive create issue', done => {
      testAction(
        receiveCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_SUCCESS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssueError', () => {
    it('commits receive create issue error with payload', done => {
      testAction(
        receiveCreateIssueError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_ERROR,
            payload: 'error',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('createNewIssue', () => {
    beforeEach(() => {
      spyOnDependency(actions, 'visitUrl');
    });

    it('with success should dispatch `receiveDismissIssue`', done => {
      mock.onPost('create_issue_path').reply(200, { issue_path: 'new_issue' });
      mockedState.vulnerabilityFeedbackPath = 'create_issue_path';

      testAction(
        createNewIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateIssue',
          },
          {
            type: 'receiveCreateIssue',
          },
        ],
        done,
      );
    });

    it('with error should dispatch `receiveCreateIssueError`', done => {
      mock.onPost('create_issue_path').reply(500, {});
      mockedState.vulnerabilityFeedbackPath = 'create_issue_path';

      testAction(
        createNewIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateIssue',
          },
          {
            type: 'receiveCreateIssueError',
          },
        ],
        done,
      );
    });
  });

  describe('updateSastIssue', () => {
    it('commits update sast issue', done => {
      testAction(
        updateSastIssue,
        null,
        mockedState,
        [
          {
            type: types.UPDATE_SAST_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateDependencyScanningIssue', () => {
    it('commits update dependency scanning issue', done => {
      testAction(
        updateDependencyScanningIssue,
        null,
        mockedState,
        [
          {
            type: types.UPDATE_DEPENDENCY_SCANNING_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateContainerScanningIssue', () => {
    it('commits update container scanning issue', done => {
      testAction(
        updateContainerScanningIssue,
        null,
        mockedState,
        [
          {
            type: types.UPDATE_CONTAINER_SCANNING_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateDastIssue', () => {
    it('commits update dast issue', done => {
      testAction(
        updateDastIssue,
        null,
        mockedState,
        [
          {
            type: types.UPDATE_DAST_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });
});
